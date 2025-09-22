import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'hanzi_database_service.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  
  factory OCRService() => _instance;
  
  OCRService._internal();
  
  final ImagePicker _picker = ImagePicker();
  final HanziDatabaseService _databaseService = HanziDatabaseService();
  
  // Google ML Kit Text Recognizer - created lazily
  TextRecognizer? _textRecognizer;
  
  TextRecognizer get textRecognizer {
    if (_textRecognizer == null) {
      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript.chinese,
      );
      print('Created new ML Kit TextRecognizer with Chinese script');
    }
    return _textRecognizer!;
  }
  
  Future<List<VocabItem>> scanVocabSheet({ImageSource source = ImageSource.camera, bool allowMultiple = true}) async {
    try {
      if (allowMultiple && source == ImageSource.gallery) {
        // Try multiple image selection for gallery
        try {
          final List<XFile> images = await _picker.pickMultipleMedia(
            limit: 10,
            imageQuality: 85,
          );
          
          if (images.isNotEmpty) {
            return await _processMultipleImages(images);
          }
        } catch (e) {
          // Fall back to single image if multiple selection fails
        }
      }
      
      // Single image selection
      return await _scanSingleImage(source);
    } catch (e) {
      print('OCR Error: $e');
      rethrow;
    }
  }
  
  Future<List<VocabItem>> processSelectedImages(List<XFile> images) async {
    return await _processMultipleImages(images);
  }
  
  Future<List<VocabItem>> _processMultipleImages(List<XFile> images) async {
    final List<VocabItem> allItems = [];
    final Set<String> seenCharacters = {};
    
    for (int i = 0; i < images.length; i++) {
      try {
        final imageFile = File(images[i].path);
        final inputImage = InputImage.fromFile(imageFile);
        
        print('Processing image ${i + 1}/${images.length}...');
        
        // Use Google ML Kit Text Recognition with timeout
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage)
            .timeout(Duration(seconds: 30), onTimeout: () {
          throw Exception('OCR processing timed out after 30 seconds');
        });
        
        print('OCR completed for image ${i + 1}, processing results...');
        final results = await _processRecognizedTextAsTable(recognizedText);
        
        for (final result in results) {
          final String character = result['character'] ?? '';
          final String definition = result['definition'] ?? '';
          
          if (character.isNotEmpty && !seenCharacters.contains(character)) {
            seenCharacters.add(character);
            
            String cleanedDefinition = _cleanDefinition(definition);
            
            // If definition is missing or invalid, try database fallback
            if (cleanedDefinition.isEmpty || cleanedDefinition == 'No definition found' || cleanedDefinition == 'definition needed') {
              cleanedDefinition = await _getDatabaseDefinition(character);
            }
            
            if (cleanedDefinition.isNotEmpty && cleanedDefinition != 'No definition found') {
              allItems.add(VocabItem(
                character: character,
                definition: cleanedDefinition,
                originalCharacter: result['originalCharacter'] ?? character,
                confidence: (result['confidence'] ?? 0.0).toDouble(),
                rawData: {
                  'pinyin': result['pinyin'] ?? '',
                  'rawText': result['rawText'] ?? '',
                },
              ));
            }
          }
        }
      } catch (e) {
        print('Error processing image ${i + 1}: $e');
        
        // If it's a timeout or model loading issue, try to reinitialize
        if (e.toString().contains('timeout') || e.toString().contains('model')) {
          print('Attempting to recover from ML Kit error...');
          try {
            _textRecognizer?.close();
            _textRecognizer = null; // Force recreation on next use
            await Future.delayed(Duration(seconds: 1));
          } catch (_) {
            // Ignore errors during cleanup
          }
        }
        
        // Continue with other images
      }
    }
    
    // DO NOT SORT: Preserve the reading order from ML Kit OCR service
    return allItems;
  }
  
  Future<List<VocabItem>> _scanSingleImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    
    if (image == null) {
      throw Exception('No image selected');
    }
    
    final imageFile = File(image.path);
    final inputImage = InputImage.fromFile(imageFile);
    
    // Use Google ML Kit Text Recognition
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    
    final results = await _processRecognizedTextAsTable(recognizedText);
    
    final List<VocabItem> vocabItems = [];
    final Set<String> seenCharacters = {};
    
    for (final result in results) {
      final String character = result['character'] ?? '';
      final String definition = result['definition'] ?? '';
      
      if (character.isNotEmpty && !seenCharacters.contains(character)) {
        seenCharacters.add(character);
        
        String cleanedDefinition = _cleanDefinition(definition);
        
        // If definition is missing or invalid, try database fallback
        if (cleanedDefinition.isEmpty || cleanedDefinition == 'No definition found' || cleanedDefinition == 'definition needed') {
          cleanedDefinition = await _getDatabaseDefinition(character);
        }
        
        if (cleanedDefinition.isNotEmpty && cleanedDefinition != 'No definition found') {
          vocabItems.add(VocabItem(
            character: character,
            definition: cleanedDefinition,
            originalCharacter: result['originalCharacter'] ?? character,
            confidence: (result['confidence'] ?? 0.0).toDouble(),
            rawData: {
              'pinyin': result['pinyin'] ?? '',
              'rawText': result['rawText'] ?? '',
            },
          ));
        }
      }
    }
    
    // DO NOT SORT: Preserve the reading order from ML Kit OCR service
    return vocabItems;
  }
  
  Future<List<Map<String, dynamic>>> _processRecognizedTextAsTable(RecognizedText recognizedText) async {
    print("\n==================== RAW OCR DATA ====================");
    
    // First show ALL raw OCR data from ML Kit
    List<Map<String, dynamic>> allRawTexts = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          final text = element.text.trim();
          if (text.isNotEmpty) {
            final boundingBox = element.boundingBox;
            final x = boundingBox.left / 1000.0; // Normalize to 0-1 range
            final y = (1000.0 - boundingBox.top) / 1000.0; // Flip Y and normalize
            
            allRawTexts.add({
              'text': text,
              'x': x,
              'y': y,
              'confidence': element.confidence ?? 0.8,
            });
          }
        }
      }
    }
    
    // Sort all raw texts by Y position (top to bottom)
    allRawTexts.sort((a, b) => b['y'].compareTo(a['y']));
    
    print("ALL RAW OCR TEXT (top to bottom):");
    for (int i = 0; i < allRawTexts.length; i++) {
      final item = allRawTexts[i];
      print("  ${i + 1}. '${item['text']}' at X: ${item['x'].toStringAsFixed(3)}, Y: ${item['y'].toStringAsFixed(3)}");
    }
    print("Total raw texts detected: ${allRawTexts.length}");
    
    print("\n==================== CLASSIFICATION ====================");
    
    // Separate Chinese terms and English definitions
    List<Map<String, dynamic>> chineseItems = [];
    List<Map<String, dynamic>> englishItems = [];
    List<Map<String, dynamic>> pinyinItems = [];
    
    for (final item in allRawTexts) {
      final text = item['text'] as String;
      final x = item['x'] as double;
      final y = item['y'] as double;
      
      print("Classifying: '$text' at X: ${x.toStringAsFixed(3)}, Y: ${y.toStringAsFixed(3)}");
      
      // Skip obvious headers
      if (_isHeader(text)) {
        print("  -> Skipping header: $text");
        continue;
      }
      
      // Classify text type
      if (_containsChineseCharacters(text)) {
        final cleanChinese = _extractChineseFromText(text);
        if (cleanChinese.isNotEmpty && cleanChinese.length >= 2 && !_isGarbageChinese(cleanChinese)) {
          chineseItems.add({
            'text': cleanChinese,
            'x': x,
            'y': y,
            'originalText': text,
          });
          print("  -> Chinese: $cleanChinese");
        } else if (cleanChinese.isNotEmpty) {
          print("  -> Filtered Chinese garbage: $cleanChinese");
        }
      } else if (_isPinyinText(text)) {
        pinyinItems.add({
          'text': text,
          'x': x,
          'y': y,
        });
        print("  -> Pinyin: $text");
      } else if (_containsEnglishText(text) && !_isGarbledText(text)) {
        final cleanEnglish = _cleanDefinition(text);
        if (cleanEnglish.isNotEmpty && !_isLikelyPinyin(cleanEnglish)) {
          englishItems.add({
            'text': cleanEnglish,
            'x': x,
            'y': y,
          });
          print("  -> English: $cleanEnglish");
        }
      } else {
        print("  -> Unclassified: $text");
      }
    }
    
    print("\nFound ${chineseItems.length} Chinese terms, ${englishItems.length} English definitions");
    
    // Build table by sorting columns independently and matching by position
    print("\nChinese | Pinyin | English");
    print("--------|--------|--------");
    
    List<Map<String, dynamic>> results = [];
    
    // Sort each column independently by Y position (top to bottom)
    chineseItems.sort((a, b) => b['y'].compareTo(a['y']));
    englishItems.sort((a, b) => b['y'].compareTo(a['y']));
    pinyinItems.sort((a, b) => b['y'].compareTo(a['y']));
    
    print("Sorted Chinese terms (top to bottom):");
    for (int i = 0; i < chineseItems.length; i++) {
      final item = chineseItems[i];
      print("  ${i + 1}. '${item['text']}' at Y: ${item['y'].toStringAsFixed(3)}");
    }
    
    print("Sorted English definitions (top to bottom):");
    for (int i = 0; i < englishItems.length; i++) {
      final item = englishItems[i];
      print("  ${i + 1}. '${item['text']}' at Y: ${item['y'].toStringAsFixed(3)}");
    }
    
    print("Sorted Pinyin (top to bottom):");
    for (int i = 0; i < pinyinItems.length; i++) {
      final item = pinyinItems[i];
      print("  ${i + 1}. '${item['text']}' at Y: ${item['y'].toStringAsFixed(3)}");
    }
    
    // Match by position - Chinese[0] with English[0], Chinese[1] with English[1], etc.
    final maxCount = [chineseItems.length, englishItems.length].reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < maxCount; i++) {
      final chineseTerm = i < chineseItems.length ? chineseItems[i]['text'] as String : '';
      final englishDef = i < englishItems.length ? englishItems[i]['text'] as String : '';
      final pinyinTerm = i < pinyinItems.length ? pinyinItems[i]['text'] as String : '';
      
      if (chineseTerm.isNotEmpty) {
        final simplified = _convertTermToSimplified(chineseTerm);
        
        // Use "-" for empty fields
        final displayChinese = simplified.isEmpty ? "-" : simplified;
        final displayPinyin = pinyinTerm.isEmpty ? "-" : pinyinTerm;
        final displayEnglish = englishDef.isEmpty ? "-" : englishDef;
        
        print("$displayChinese | $displayPinyin | $displayEnglish");
        
        results.add({
          "character": simplified,
          "originalCharacter": chineseTerm,
          "fullText": chineseTerm,
          "definition": englishDef.isEmpty ? "No definition" : englishDef,
          "pinyin": pinyinTerm,
          "confidence": 0.9,
          "rawText": "$chineseTerm | $pinyinTerm | $englishDef"
        });
      }
    }
    
    print("\nTotal entries: ${results.length}");
    print("========================================================\n");
    
    return results;
  }
  
  bool _isHeader(String text) {
    final lowerText = text.toLowerCase();
    final headerPatterns = [
      '中文', '拼音', '英文', '班级', '姓名', 'name:',
      'ap-ib', '阅读文章', '阅读'
    ];
    
    for (final pattern in headerPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }
  
  bool _containsChineseCharacters(String text) {
    final chineseRegex = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]+');
    return chineseRegex.hasMatch(text);
  }
  
  String _extractChineseFromText(String text) {
    // First, handle numbered entries by removing number prefixes
    String workingText = text.trim();
    workingText = workingText.replaceAll(RegExp(r'^\d+\s*'), '');
    
    // Extract Chinese characters including A/B format
    final chineseRegex = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]+(?:/[\u4e00-\u9fff\u3400-\u4dbf]+)?');
    final matches = chineseRegex.allMatches(workingText);
    
    if (matches.isNotEmpty) {
      // Find the longest match
      String bestMatch = '';
      for (final match in matches) {
        final chineseText = workingText.substring(match.start, match.end);
        if (chineseText.length > bestMatch.length) {
          bestMatch = chineseText;
        }
      }
      return bestMatch;
    }
    
    return '';
  }
  
  bool _isGarbageChinese(String text) {
    // Filter out obviously invalid Chinese terms
    final garbageTerms = ['然需', '中文', '拼音', '英文', '班级', '姓名'];
    
    if (garbageTerms.contains(text)) {
      return true;
    }
    
    // Filter out single characters that are likely OCR errors
    if (text.length == 1) {
      return true;
    }
    
    return false;
  }
  
  bool _isPinyinText(String text) {
    final cleanText = text.trim();
    final lowerText = cleanText.toLowerCase();
    
    // Reject garbled text patterns
    if (cleanText.length <= 3 && (cleanText.contains('P') || cleanText.contains('Q'))) {
      return false;
    }
    
    // Check for tone marks - strong indicator of pinyin
    final toneMarks = 'āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ';
    for (int i = 0; i < toneMarks.length; i++) {
      if (cleanText.contains(toneMarks[i])) {
        return true;
      }
    }
    
    // Exact pinyin syllables - must match exactly, not just contain
    final pinyinSyllables = [
      'ba', 'pa', 'ma', 'fa', 'da', 'ta', 'na', 'la', 'ga', 'ka', 'ha',
      'bo', 'po', 'mo', 'fo', 'wo', 'zi', 'ci', 'si', 'qi', 'xi', 'yi',
      'bi', 'pi', 'mi', 'di', 'ti', 'ni', 'li', 'zhi', 'chi', 'shi', 'ri',
      'ju', 'qu', 'xu', 'yu', 'nu', 'lu', 'zu', 'cu', 'su', 'zhu', 'chu', 'shu', 'ru',
      'ji', 'jia', 'qia', 'xia', 'jie', 'qie', 'xie', 'die', 'tie', 'nie', 'lie',
      'jiao', 'qiao', 'xiao', 'diao', 'tiao', 'niao', 'liao',
      'jiu', 'qiu', 'xiu', 'diu', 'niu', 'liu', 'le', 'ge', 'ke', 'he',
      'zhe', 'che', 'she', 're', 'ze', 'ce', 'se', 'er', 'ye', 'yue', 'yuan',
      'yin', 'yun', 'ying', 'yong', 'wa', 'wai', 'wei', 'wan', 'wen',
      'wang', 'weng', 'wu', 'dong', 'tong', 'nong', 'long', 'gong', 'kong',
      'hong', 'zhong', 'chong', 'rong', 'zong', 'cong', 'jiang', 'qiang',
      'xiang', 'niang', 'liang', 'jing', 'qing', 'xing', 'ding', 'ting',
      'ning', 'ling', 'dan', 'chan', 'ran', 'san', 'shan', 'gan', 'kan',
      'han', 'man', 'fan', 'tan', 'lan', 'pan', 'ban'
    ];
    
    // Split into words and check if ALL words are exact pinyin syllables
    final words = lowerText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    
    if (words.isEmpty || words.length > 4) {
      return false; // Too many words, probably English
    }
    
    // ALL words must be exact pinyin syllables
    for (final word in words) {
      if (!pinyinSyllables.contains(word)) {
        return false; // If any word is not pinyin, the whole thing is not pinyin
      }
    }
    
    return true; // All words are exact pinyin syllables
  }
  
  bool _containsEnglishText(String text) {
    final englishRegex = RegExp(r'[a-zA-Z]');
    return englishRegex.hasMatch(text);
  }
  
  bool _isGarbledText(String text) {
    final lowerText = text.toLowerCase();
    
    // First check if it contains valid English words - if so, not garbled
    if (_containsValidEnglishWords(text)) {
      return false;
    }
    
    // Check for obvious OCR garbage patterns
    if (text.length <= 4) {
      // Check for mixed case in short text (like "yOU", "qP", etc.)
      final hasLower = RegExp(r'[a-z]').hasMatch(text);
      final hasUpper = RegExp(r'[A-Z]').hasMatch(text);
      if (hasLower && hasUpper) {
        return true;
      }
      
      // Check for single letters or very short meaningless combinations
      if (text.length <= 2 || lowerText == 'you' || lowerText == 'qp' || 
          text == 'yOU' || lowerText == 'al') {
        return true;
      }
    }
    
    // Patterns that indicate garbled OCR text
    final garbledPatterns = [
      r'\b(ohtr|bdlh|lber|sroke|hemm|trl|rn|promgpf|mgnisr)\b',
      r'^al qp',
    ];
    
    for (final pattern in garbledPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerText)) {
        return true;
      }
    }
    
    return false;
  }
  
  bool _containsValidEnglishWords(String text) {
    final lowerText = text.toLowerCase();
    
    // Check for basic English patterns instead of hardcoded words
    if (lowerText.length < 3) return false;
    
    // Check for typical English definition patterns
    final patterns = [
      r"\b\w+\'s\s+\w+", // possessive forms like "father's sister"
      r"\b(to|of|in|on|at|with|by|from)\s+\w+", // prepositions
      r"\b\w+ed\b", // past tense verbs
      r"\b\w+ing\b", // present participle verbs
    ];
    
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    
    // If it has more than 3 words and contains common English letters/patterns, likely English
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    return words.length >= 3 && RegExp(r'[bcdfghjklmnpqrstvwxyz]').hasMatch(text);
  }
  
  bool _isLikelyPinyin(String text) {
    final lowerText = text.toLowerCase().trim();
    
    // If it contains English indicators, it's NOT pinyin
    if (text.contains(',') || text.contains("'") || text.contains('of') || text.contains('the') || 
        text.contains('and') || text.contains('to') || text.contains('with') || 
        text.contains('brother') || text.contains('sister') || text.contains('mother') ||
        text.contains('father') || text.contains('child') || lowerText.length > 15) {
      return false;
    }
    
    return false;
  }
  
  String _cleanDefinition(String definition) {
    return definition
        .replaceAll(RegExp(r'^[,;\s\d\.]+'), '')
        .replaceAll(RegExp(r'[\s]+'), ' ')
        .trim();
  }
  
  String _convertTermToSimplified(String term) {
    String result = '';
    for (int i = 0; i < term.length; i++) {
      result += _convertToSimplified(term[i]);
    }
    return result;
  }
  
  String _convertToSimplified(String character) {
    const traditionalToSimplified = {
      '愛': '爱', '國': '国', '會': '会', '時': '时', '來': '来',
      '為': '为', '發': '发', '開': '开', '關': '关', '門': '门',
      '見': '见', '進': '进', '對': '对', '說': '说', '這': '这',
      '長': '长', '書': '书', '學': '学', '應': '应', '將': '将',
      '無': '无', '現': '现', '經': '经', '頭': '头', '與': '与',
      '動': '动', '還': '还', '點': '点', '從': '从', '邊': '边',
      '過': '过', '後': '后', '馬': '马', '錢': '钱', '車': '车',
      '樂': '乐', '熱': '热', '聽': '听', '話': '话', '語': '语',
      '讀': '读', '誰': '谁', '課': '课', '買': '买', '賣': '卖',
      '電': '电', '號': '号', '們': '们', '類': '类', '問': '问',
      '間': '间', '離': '离', '難': '难', '風': '风', '飛': '飞',
      '機': '机', '場': '场', '務': '务', '報': '报', '紙': '纸',
      '畫': '画', '較': '较', '運': '运', '農': '农', '覺': '觉',
      '黨': '党', '織': '织', '軍': '军', '導': '导', '幹': '干',
      '備': '备', '辦': '办', '議': '议', '選': '选', '參': '参',
      '歷': '历', '驗': '验', '營': '营', '構': '构', '確': '确',
      '傳': '传', '師': '师', '觀': '观', '論': '论', '際': '际',
      '陸': '陆', '訪': '访', '談': '谈', '責': '责', '採': '采',
      '術': '术', '極': '极', '驚': '惊', '雙': '双', '隨': '随',
      '藝': '艺', '錯': '错', '聯': '联', '斷': '断', '權': '权',
      '證': '证', '識': '识', '條': '条', '戰': '战', '團': '团',
      '轉': '转', '敗': '败', '貿': '贸', '陽': '阳', '職': '职',
      '漢': '汉', '夢': '梦', '響': '响', '雖': '虽', '續': '续',
      '衛': '卫', '規': '规', '視': '视', '競': '竞', '獲': '获'
    };
    
    return traditionalToSimplified[character] ?? character;
  }
  
  Future<String> _getDatabaseDefinition(String character) async {
    try {
      // Try each character individually for multi-character terms
      String bestDefinition = '';
      for (int i = 0; i < character.length; i++) {
        final singleChar = character[i];
        final hanziChar = await _databaseService.getCharacter(singleChar);
        
        if (hanziChar != null && hanziChar.meanings.isNotEmpty) {
          // Use the first meaning as the definition
          final definition = hanziChar.meanings.first;
          if (definition.isNotEmpty && !definition.toLowerCase().contains('variant') && 
              !definition.toLowerCase().contains('same as')) {
            if (bestDefinition.isEmpty) {
              bestDefinition = definition;
            } else {
              // For multi-character terms, combine definitions
              bestDefinition += '; $definition';
            }
          }
        }
      }
      
      if (bestDefinition.isNotEmpty) {
        return bestDefinition;
      }
      
      return 'No definition found';
    } catch (e) {
      print('Error getting database definition for $character: $e');
      return 'No definition found';
    }
  }
  
  Future<Map<String, dynamic>> createCharacterSetFromOCR({
    required List<VocabItem> items,
    required String setName,
  }) async {
    final List<Map<String, dynamic>> characters = [];
    
    for (final item in items) {
      characters.add({
        'character': item.character,
        'definition': item.definition,
        'isCustomDefinition': true,
      });
    }
    
    return {
      'name': setName,
      'characters': characters,
      'source': 'ocr_import',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
  
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

class VocabItem {
  final String character;
  final String definition;
  final String originalCharacter;
  final double confidence;
  final Map<String, dynamic>? rawData;
  
  VocabItem({
    required this.character,
    required this.definition,
    required this.originalCharacter,
    this.confidence = 0.0,
    this.rawData,
  });
  
  Map<String, dynamic> toJson() => {
    'character': character,
    'definition': definition,
    'originalCharacter': originalCharacter,
    'confidence': confidence,
    if (rawData != null) 'rawData': rawData,
  };
}