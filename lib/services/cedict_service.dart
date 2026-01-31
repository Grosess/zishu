import 'package:flutter/services.dart';

/// Dictionary entry with pinyin and definition from CEDICT
class CedictEntry {
  final String simplified;
  final String traditional;
  final String pinyin;
  final String definition;
  
  CedictEntry({
    required this.simplified,
    required this.traditional,
    required this.pinyin,
    required this.definition,
  });
}

/// Service for looking up definitions from CEDICT dictionary
class CedictService {
  static final CedictService _instance = CedictService._internal();
  factory CedictService() => _instance;
  CedictService._internal();
  
  Map<String, CedictEntry>? _dictionary;
  bool _isLoading = false;
  Future<void>? _loadingFuture;
  
  /// Initialize the dictionary by loading CEDICT data
  Future<void> initialize() async {
    if (_dictionary != null) return;
    
    // Return existing loading future if already loading
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }
    
    // Create new loading future
    _loadingFuture = _loadCedict();
    return _loadingFuture!;
  }
  
  Future<void> _loadCedict() async {
    _isLoading = true;
    try {
      // Load CEDICT file from assets
      final String cedictData = await rootBundle.loadString('assets/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
      
      // Parse in isolate for better performance
      _dictionary = _parseCedict(cedictData);
    } catch (e) {
      // Production: removed debug print
      _dictionary = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Parse CEDICT data into a dictionary
  Map<String, CedictEntry> _parseCedict(String data) {
    final Map<String, CedictEntry> dict = {};
    final lines = data.split(RegExp(r'\r?\n'));
    
    int parsed = 0;
    int skipped = 0;
    int failed = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Skip comments and empty lines
      if (line.startsWith('#') || line.trim().isEmpty) {
        skipped++;
        continue;
      }
      
      // Parse line format: Traditional Simplified [pinyin] /definition1/definition2/
      final match = RegExp(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$').firstMatch(line);
      if (match != null) {
        final traditional = match.group(1)!;
        final simplified = match.group(2)!;
        final pinyin = match.group(3)!;
        final definitions = match.group(4)!;
        
        // Check if this is a surname entry BEFORE cleaning
        final isSurnameEntry = definitions.toLowerCase().contains('surname');
        
        // Clean up definition - take first one and remove extra info
        String cleanDef = _cleanDefinition(definitions);
        
        final entry = CedictEntry(
          simplified: simplified,
          traditional: traditional,
          pinyin: pinyin,
          definition: cleanDef,
        );
        
        // Store by simplified character
        // Special handling for characters with multiple pronunciations
        if (simplified == '好') {
          // For 好, prefer hǎo (3rd tone) over hào (4th tone)
          if (pinyin.contains('hao3')) {
            dict[simplified] = entry;
          } else if (!dict.containsKey(simplified)) {
            dict[simplified] = entry;
          }
        } else if (simplified == '东西') {
          // For 东西, prefer dong1 xi5 (thing/stuff) over dong1 xi1 (east and west)
          if (pinyin.contains('dong1 xi5')) {
            dict[simplified] = entry;
          } else if (!dict.containsKey(simplified)) {
            dict[simplified] = entry;
          }
        } else if (!dict.containsKey(simplified)) {
          // For other characters, keep the first entry (usually most common)
          dict[simplified] = entry;
        } else {
          // Check if we should replace the existing entry
          final existingDef = dict[simplified]!.definition.toLowerCase();
          final existingPinyin = dict[simplified]!.pinyin;
          final newDef = cleanDef.toLowerCase();
          
          // Replace if:
          // 1. Existing is surname and new is not
          // 2. Existing contains "variant of", "used in", "see also", "same as" and new doesn't
          // 3. Existing pinyin starts with capital letter and new doesn't (prefer common nouns)
          if ((!isSurnameEntry && existingDef.contains('surname')) ||
              ((existingDef.contains('variant of') || 
                existingDef.contains('used in') || 
                existingDef.contains('see also') || 
                existingDef.contains('same as')) &&
               !newDef.contains('variant of') &&
               !newDef.contains('used in') &&
               !newDef.contains('see also') &&
               !newDef.contains('same as')) ||
              (existingPinyin.isNotEmpty && existingPinyin[0].toUpperCase() == existingPinyin[0] &&
               pinyin.isNotEmpty && pinyin[0].toLowerCase() == pinyin[0])) {
            dict[simplified] = entry;
          }
        }
        
        // Also store by traditional if different
        if (traditional != simplified) {
          if (traditional == '好') {
            // Same special handling for traditional form
            if (pinyin.contains('hao3')) {
              dict[traditional] = entry;
            } else if (!dict.containsKey(traditional)) {
              dict[traditional] = entry;
            }
          } else if (traditional == '東西') {
            // For 東西, prefer dong1 xi5 (thing/stuff) over dong1 xi1 (east and west)
            if (pinyin.contains('dong1 xi5')) {
              dict[traditional] = entry;
            } else if (!dict.containsKey(traditional)) {
              dict[traditional] = entry;
            }
          } else if (traditional == '書' || simplified == '书') {
            // For 書/书, prefer shu1 (book) over Shu1 (abbreviation)
            if (pinyin == 'shu1') {
              dict[traditional] = entry;
              if (simplified != traditional) {
                dict[simplified] = entry;
              }
            } else if (!dict.containsKey(traditional)) {
              dict[traditional] = entry;
            }
          } else if (!dict.containsKey(traditional)) {
            dict[traditional] = entry;
          } else {
            // Apply same replacement logic for traditional
            final existingDef = dict[traditional]!.definition.toLowerCase();
            final newDef = cleanDef.toLowerCase();
            
            if ((!isSurnameEntry && existingDef.contains('surname')) ||
                ((existingDef.contains('variant of') || 
                  existingDef.contains('used in') || 
                  existingDef.contains('see also') || 
                  existingDef.contains('same as')) &&
                 !newDef.contains('variant of') &&
                 !newDef.contains('used in') &&
                 !newDef.contains('see also') &&
                 !newDef.contains('same as'))) {
              dict[traditional] = entry;
            }
          }
        }
        
        parsed++;
        if (parsed % 10000 == 0) {
          // Production: removed debug print
        }
        
        // Debug: Check if we found our test characters and phrases
        if (simplified == '客' || simplified == '气' || simplified == '得' || 
            traditional == '客' || traditional == '气' || traditional == '得' ||
            simplified == '为什么' || traditional == '為什麼' ||
            simplified == '冷' || simplified == '束' || simplified == '好' ||
            simplified == '万' || traditional == '萬') {
          // Found test entry in CEDICT
          // Found test entry in CEDICT
          // Validated simplified text
          // Production: removed debug print
          // Production: removed debug print
          // Checked surname status
          // Production: removed debug print
        }
      } else {
        // Failed to match
        failed++;
        if (failed <= 5) {
          // Failed to parse line
        }
      }
    }
    
    // Final debug check
    // Parsed CEDICT successfully
    // Final dictionary contains all entries
    
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Validated dictionary contents
    if (dict.containsKey('客')) {
      final e = dict['客']!;
      // Production: removed debug print
    }
    if (dict.containsKey('气')) {
      final e = dict['气']!;
      // Production: removed debug print
    }
    if (dict.containsKey('为什么')) {
      final e = dict['为什么']!;
      // Production: removed debug print
    }
    if (dict.containsKey('冷')) {
      final e = dict['冷']!;
      // Production: removed debug print
    }
    if (dict.containsKey('束')) {
      final e = dict['束']!;
      // Production: removed debug print
    }
    if (dict.containsKey('好')) {
      final e = dict['好']!;
      // Production: removed debug print
    }
    
    return dict;
  }
  
  /// Clean up definition for display
  String _cleanDefinition(String definitions) {
    // Split by / and take first definition only
    final parts = definitions.split('/').where((s) => s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '';

    // ALWAYS use the FIRST definition from the database
    String def = parts.first;
    
    // Remove CL: classifiers
    def = def.replaceAll(RegExp(r'CL:[^\s,;]+'), '');
    
    // Remove parentheses but keep the content
    def = def.replaceAll(RegExp(r'[()]'), '');
    
    // Replace "abbr. for X" with just "X"
    def = def.replaceAllMapped(
      RegExp(r'abbr\.\s+for\s+(.+)', caseSensitive: false),
      (match) => match.group(1) ?? ''
    );
    def = def.replaceAllMapped(
      RegExp(r'abbreviation\s+for\s+(.+)', caseSensitive: false),
      (match) => match.group(1) ?? ''
    );
    
    // Remove ALL Chinese/CJK characters from definitions - no exceptions
    // This includes:
    // - CJK Unified Ideographs (U+4E00–U+9FFF)
    // - CJK Extension A (U+3400–U+4DBF)
    // - CJK Compatibility Ideographs (U+F900–U+FAFF)
    // - CJK Symbols and Punctuation (U+3000–U+303F)
    // - Hiragana (U+3040–U+309F) and Katakana (U+30A0–U+30FF)
    def = def.replaceAll(RegExp(r'[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]+'), '');
    
    // Clean up any leftover parentheses, brackets, or "see" references that are now empty
    def = def.replaceAll(RegExp(r'\(\s*\)'), '');
    def = def.replaceAll(RegExp(r'\[\s*\]'), '');
    def = def.replaceAll(RegExp(r'see\s*(?:[,;]|$)', caseSensitive: false), '');
    def = def.replaceAll(RegExp(r'See\s*(?:[,;]|$)', caseSensitive: false), '');
    
    // Remove "variant of", "same as", etc. that reference Chinese terms (now removed)
    def = def.replaceAll(RegExp(r'variant of\s*(?:[,;]|$)', caseSensitive: false), '');
    def = def.replaceAll(RegExp(r'same as\s*(?:[,;]|$)', caseSensitive: false), '');
    def = def.replaceAll(RegExp(r'used in\s*(?:[,;]|$)', caseSensitive: false), '');
    
    // Clean up any double spaces, commas, or semicolons
    def = def.replaceAll(RegExp(r'[,;]+\s*[,;]+'), ',');
    def = def.replaceAll(RegExp(r'^[,;\s]+|[,;\s]+$'), '');
    
    // Clean up whitespace
    def = def.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // If definition became empty or too short after removing Chinese, mark it
    if (def.isEmpty || def.length < 2) {
      // Try next definition if available
      if (parts.length > 1) {
        return _cleanDefinition(parts.sublist(1).join('/'));
      }
      // Otherwise return a generic placeholder
      return '[definition]';
    }
    
    // Make first letter lowercase unless it's a proper noun (like China, Beijing, etc.)
    if (def.isNotEmpty && !_isProperNoun(def)) {
      def = def[0].toLowerCase() + def.substring(1);
    }
    
    // If definition is too short or empty after cleaning, try next one
    if (def.length < 3 && parts.length > 1) {
      return _cleanDefinition(parts.sublist(1).join('/'));
    }
    
    // SHORTEN LONG DEFINITIONS
    // Special case for Beijing - just show "Beijing" instead of the full definition
    if (def.toLowerCase().contains('beijing municipality') || 
        def.toLowerCase().contains('capital of')) {
      return 'Beijing';
    }
    
    // For definitions with semicolons, take only the first part
    if (def.contains(';')) {
      def = def.split(';').first.trim();
    }
    
    // For definitions with "to" verbs, simplify
    if (def.startsWith('to ')) {
      // Remove "to" and take first verb only
      def = def.substring(3);
      if (def.contains(',')) {
        def = def.split(',').first.trim();
      }
      if (def.contains(';')) {
        def = def.split(';').first.trim();
      }
    }
    
    // Limit length to 40 characters for display (increased from 20)
    if (def.length > 40) {
      // Try to cut at a word boundary
      final cutoff = def.substring(0, 40).lastIndexOf(' ');
      if (cutoff > 20) {
        def = '${def.substring(0, cutoff)}...';
      } else {
        def = '${def.substring(0, 37)}...';
      }
    }
    
    return def;
  }
  
  /// Look up a word in the dictionary
  CedictEntry? lookup(String word) {
    if (_dictionary == null) {
      // Production: removed debug print
      return null;
    }
    
    // Check for manual override first
    final override = _getManualOverride(word);
    if (override != null) {
      return override;
    }
    
    final entry = _dictionary![word];
    if (entry != null) {
      // Found entry in dictionary
      // Filter out definitions containing "variant of" or "used in"
      if (_shouldFilterDefinition(entry.definition)) {
        // Filtering out unhelpful definition
        // Return null to indicate no useful definition
        return null;
      }
    } else {
      // No entry found in dictionary
      // For multi-character words, try to build a definition from individual characters
      if (word.length > 1) {
        return _buildCompositeDefinition(word);
      }
    }
    return entry;
  }
  
  /// Check if a definition should be filtered out
  bool _shouldFilterDefinition(String definition) {
    final lowerDef = definition.toLowerCase();
    
    // Filter out offensive terms
    if (lowerDef.contains('nigger') || lowerDef.contains('negro')) {
      return true;
    }
    
    return lowerDef.contains('variant of') || 
           lowerDef.contains('used in') ||
           lowerDef.contains('see also') ||
           lowerDef.contains('same as');
  }
  
  /// Get definition for a word (returns null if not found)
  String? getDefinition(String word) {
    final entry = lookup(word);
    return entry?.definition;
  }
  
  /// Get pinyin for a word (returns null if not found)
  String? getPinyin(String word) {
    final entry = lookup(word);
    return entry?.pinyin;
  }
  
  /// Get formatted display string with pinyin and definition
  String? getFormattedDisplay(String word) {
    final entry = lookup(word);
    if (entry == null) return null;
    
    return '${entry.pinyin} - ${entry.definition}';
  }
  
  /// Check if dictionary is loaded
  bool get isLoaded => _dictionary != null;
  
  /// Get total number of entries
  int get entryCount => _dictionary?.length ?? 0;
  
  /// Get synonyms for common search terms
  List<String> _getSynonyms(String word) {
    final synonymMap = {
      'test': ['test', 'exam', 'examination', 'quiz'],
      'exam': ['test', 'exam', 'examination', 'quiz'],
      'examination': ['test', 'exam', 'examination', 'quiz'],
      'quiz': ['test', 'exam', 'examination', 'quiz'],
      'big': ['big', 'large', 'huge', 'great'],
      'large': ['big', 'large', 'huge', 'great'],
      'huge': ['big', 'large', 'huge', 'great'],
      'small': ['small', 'little', 'tiny', 'minor'],
      'little': ['small', 'little', 'tiny', 'minor'],
      'tiny': ['small', 'little', 'tiny', 'minor'],
      'fast': ['fast', 'quick', 'rapid', 'swift'],
      'quick': ['fast', 'quick', 'rapid', 'swift'],
      'rapid': ['fast', 'quick', 'rapid', 'swift'],
      'slow': ['slow', 'sluggish', 'gradual'],
      'good': ['good', 'well', 'fine', 'nice'],
      'bad': ['bad', 'poor', 'terrible', 'awful'],
      'happy': ['happy', 'glad', 'joyful', 'pleased'],
      'sad': ['sad', 'unhappy', 'sorrowful', 'upset'],
      'angry': ['angry', 'mad', 'furious', 'upset'],
      'mad': ['angry', 'mad', 'furious', 'crazy'],
      'beautiful': ['beautiful', 'pretty', 'lovely', 'attractive'],
      'pretty': ['beautiful', 'pretty', 'lovely', 'attractive'],
      'ugly': ['ugly', 'unattractive', 'unsightly'],
      'hot': ['hot', 'warm', 'heated'],
      'cold': ['cold', 'cool', 'chilly', 'freezing'],
      'new': ['new', 'fresh', 'recent', 'modern'],
      'old': ['old', 'ancient', 'aged', 'elderly'],
      'young': ['young', 'youthful', 'juvenile'],
      'speak': ['speak', 'say', 'talk', 'tell'],
      'say': ['speak', 'say', 'talk', 'tell'],
      'talk': ['speak', 'say', 'talk', 'tell'],
      'tell': ['speak', 'say', 'talk', 'tell'],
      'see': ['see', 'look', 'watch', 'view'],
      'look': ['see', 'look', 'watch', 'view'],
      'watch': ['see', 'look', 'watch', 'view'],
      'eat': ['eat', 'consume', 'dine'],
      'drink': ['drink', 'beverage', 'sip'],
      'sleep': ['sleep', 'rest', 'slumber', 'nap'],
      'rest': ['sleep', 'rest', 'relax'],
      'walk': ['walk', 'stroll', 'stride'],
      'run': ['run', 'jog', 'sprint'],
      'buy': ['buy', 'purchase', 'shop'],
      'sell': ['sell', 'vend', 'market'],
      'help': ['help', 'assist', 'aid'],
      'like': ['like', 'enjoy', 'love', 'fond'],
      'love': ['like', 'enjoy', 'love', 'adore'],
      'hate': ['hate', 'dislike', 'detest'],
      'want': ['want', 'need', 'desire', 'wish'],
      'need': ['want', 'need', 'require'],
      'begin': ['begin', 'start', 'commence'],
      'start': ['begin', 'start', 'commence'],
      'end': ['end', 'finish', 'complete', 'stop'],
      'finish': ['end', 'finish', 'complete'],
      'stop': ['end', 'stop', 'halt', 'cease'],
    };
    
    return synonymMap[word] ?? [word];
  }

  /// Search the dictionary by pinyin or English definition
  List<CedictEntry> search(String query, {int maxResults = 100}) {
    if (_dictionary == null || query.isEmpty) return [];
    
    final results = <CedictEntry>[];
    final processedQuery = query.toLowerCase().trim();
    // Also create a version without spaces for pinyin matching
    final processedQueryNoSpaces = processedQuery.replaceAll(RegExp(r'\s+'), '');
    
    // First pass: exact matches
    for (final entry in _dictionary!.values) {
      if (results.length >= maxResults) break;
      
      // Skip entries with unhelpful definitions
      if (_shouldFilterDefinition(entry.definition)) continue;
      
      final pinyinNoTone = _removeTones(entry.pinyin).toLowerCase();
      final definitionLower = entry.definition.toLowerCase();
      
      // Exact match in pinyin (without tones and spaces)
      if (pinyinNoTone == processedQueryNoSpaces) {
        results.add(entry);
        continue;
      }
      
      // Exact word match in definition (including synonyms)
      final definitionWords = definitionLower.split(RegExp(r'[\s,;/()]+'));
      bool matchesSynonym = false;
      
      // Check if query matches any word in definition
      if (definitionWords.contains(processedQuery)) {
        matchesSynonym = true;
      } else {
        // Check synonyms
        final synonyms = _getSynonyms(processedQuery);
        for (final synonym in synonyms) {
          if (definitionWords.contains(synonym)) {
            matchesSynonym = true;
            break;
          }
        }
      }
      
      if (matchesSynonym) {
        results.add(entry);
        continue;
      }
    }
    
    // Second pass: partial matches if not enough results
    if (results.length < 20) {
      for (final entry in _dictionary!.values) {
        if (results.length >= maxResults) break;
        if (results.contains(entry)) continue; // Skip already added
        
        // Skip entries with unhelpful definitions
        if (_shouldFilterDefinition(entry.definition)) continue;
        
        final pinyinNoTone = _removeTones(entry.pinyin).toLowerCase();
        final definitionLower = entry.definition.toLowerCase();
        
        // Partial match in pinyin or definition (including synonyms)
        bool partialMatch = false;
        
        if (pinyinNoTone.contains(processedQueryNoSpaces) || 
            definitionLower.contains(processedQuery)) {
          partialMatch = true;
        } else {
          // Check synonyms for partial matches
          final synonyms = _getSynonyms(processedQuery);
          for (final synonym in synonyms) {
            if (definitionLower.contains(synonym)) {
              partialMatch = true;
              break;
            }
          }
        }
        
        if (partialMatch) {
          results.add(entry);
        }
      }
    }
    
    // Sort results by relevance
    results.sort((a, b) {
      // Single characters before multi-character words
      if (a.simplified.length != b.simplified.length) {
        return a.simplified.length.compareTo(b.simplified.length);
      }
      
      // Then by pinyin
      return a.pinyin.compareTo(b.pinyin);
    });
    
    return results;
  }
  
  /// Remove tone marks from pinyin for easier searching
  String _removeTones(String pinyin) {
    return pinyin
        .replaceAll(RegExp(r'[āáǎàa]'), 'a')
        .replaceAll(RegExp(r'[ēéěèe]'), 'e')
        .replaceAll(RegExp(r'[īíǐìi]'), 'i')
        .replaceAll(RegExp(r'[ōóǒòo]'), 'o')
        .replaceAll(RegExp(r'[ūúǔùu]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜü]'), 'u')
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'\s+'), ''); // Remove all whitespace
  }
  
  /// Check if a definition is a proper noun
  bool _isProperNoun(String def) {
    // List of common proper nouns and patterns
    final properNouns = [
      'China', 'Beijing', 'Shanghai', 'Taiwan', 'Hong Kong', 'Macau',
      'Japan', 'Korea', 'America', 'USA', 'UK', 'England', 'France',
      'Germany', 'Russia', 'Canada', 'Australia', 'India', 'Singapore',
      'Malaysia', 'Thailand', 'Vietnam', 'Indonesia', 'Philippines',
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    
    // Check if the definition starts with any proper noun
    for (final noun in properNouns) {
      if (def.startsWith(noun)) {
        return true;
      }
    }
    
    // Check for patterns like "X Province", "X City", etc.
    if (def.contains(RegExp(r'^[A-Z]\w+\s+(Province|City|County|River|Mountain|Lake|Sea)'))) {
      return true;
    }
    
    return false;
  }

  /// Get manual override for common HSK characters
  CedictEntry? _getManualOverride(String character) {
    // Manual overrides for common problematic definitions
    // These focus on practical, everyday meanings for HSK learners
    final overrides = <String, Map<String, String>>{
      // Time-related that get technical definitions
      '午': {'pinyin': 'wǔ', 'def': 'noon; midday'},
      '时': {'pinyin': 'shí', 'def': 'time; hour'},
      '分': {'pinyin': 'fēn', 'def': 'minute; divide'},
      '日': {'pinyin': 'rì', 'def': 'day; sun'},
      '月': {'pinyin': 'yuè', 'def': 'month; moon'},
      '些': {'pinyin': 'xiē', 'def': 'some; few'},
      '猫': {'pinyin': 'māo', 'def': 'cat'},
      '马': {'pinyin': 'mǎ', 'def': 'horse'},
      '发烧': {'pinyin': 'fā shāo', 'def': 'fever'},
      // Common HSK 1-3 characters with simplified definitions
      '上': {'pinyin': 'shàng', 'def': 'up; above; on'},
      '个': {'pinyin': 'gè/ge', 'def': 'measure word'},
      '你': {'pinyin': 'nǐ', 'def': 'you'},
      '他': {'pinyin': 'tā', 'def': 'he; him'},
      '她': {'pinyin': 'tā', 'def': 'she; her'},
      '我': {'pinyin': 'wǒ', 'def': 'I; me'},
      '们': {'pinyin': 'men', 'def': 'plural marker'},
      '是': {'pinyin': 'shì', 'def': 'is'},
      '没': {'pinyin': 'méi', 'def': 'not have; no'},
      '有': {'pinyin': 'yǒu', 'def': 'have; there is'},
      '和': {'pinyin': 'hé', 'def': 'and; with'},
      '在': {'pinyin': 'zài', 'def': 'at; in; exist'},
      '的': {'pinyin': 'de', 'def': 'possessive particle'},
      '了': {'pinyin': 'le', 'def': 'completed action'},
      '不': {'pinyin': 'bù', 'def': 'not; no'},
      '很': {'pinyin': 'hěn', 'def': 'very'},
      '都': {'pinyin': 'dōu', 'def': 'all; both'},
      '这': {'pinyin': 'zhè', 'def': 'this'},
      '那': {'pinyin': 'nà', 'def': 'that'},
      '也': {'pinyin': 'yě', 'def': 'also; too'},
      '会': {'pinyin': 'huì', 'def': 'can; will'},
      '能': {'pinyin': 'néng', 'def': 'can; able to'},
      '想': {'pinyin': 'xiǎng', 'def': 'think; want'},
      '要': {'pinyin': 'yào', 'def': 'want; need'},
      '好': {'pinyin': 'hǎo', 'def': 'good; well'},
      '吃': {'pinyin': 'chī', 'def': 'eat'},
      '喝': {'pinyin': 'hē', 'def': 'drink'},
      '看': {'pinyin': 'kàn', 'def': 'look; see; read'},
      '听': {'pinyin': 'tīng', 'def': 'listen; hear'},
      '说': {'pinyin': 'shuō', 'def': 'speak; say'},
      '读': {'pinyin': 'dú', 'def': 'read'},
      '写': {'pinyin': 'xiě', 'def': 'write'},
      '来': {'pinyin': 'lái', 'def': 'come'},
      '去': {'pinyin': 'qù', 'def': 'go'},
      '开': {'pinyin': 'kāi', 'def': 'open; start'},
      '喂': {'pinyin': 'wèi', 'def': 'hello (phone)'},
      '因': {'pinyin': 'yīn', 'def': 'because'},
      '因为': {'pinyin': 'yīn wèi', 'def': 'because'},
      '所以': {'pinyin': 'suǒ yǐ', 'def': 'therefore; so'},
      '但是': {'pinyin': 'dàn shì', 'def': 'but; however'},
      '如果': {'pinyin': 'rú guǒ', 'def': 'if'},
      '虽然': {'pinyin': 'suī rán', 'def': 'although'},
      '或者': {'pinyin': 'huò zhě', 'def': 'or'},
      '还是': {'pinyin': 'hái shì', 'def': 'or; still'},
      '已经': {'pinyin': 'yǐ jīng', 'def': 'already'},
      '正在': {'pinyin': 'zhèng zài', 'def': 'in progress'},
      '一起': {'pinyin': 'yī qǐ', 'def': 'together'},
      '一定': {'pinyin': 'yī dìng', 'def': 'definitely'},
      '一样': {'pinyin': 'yī yàng', 'def': 'same; alike'},
      '可以': {'pinyin': 'kě yǐ', 'def': 'can; may'},
      '可能': {'pinyin': 'kě néng', 'def': 'maybe; possible'},
      '应该': {'pinyin': 'yīng gāi', 'def': 'should; ought to'},
      '必须': {'pinyin': 'bì xū', 'def': 'must'},
      '需要': {'pinyin': 'xū yào', 'def': 'need; require'},
      '离': {'pinyin': 'lí', 'def': 'leave; from'},
      '里': {'pinyin': 'lǐ', 'def': 'inside'},
      '哪': {'pinyin': 'nǎ', 'def': 'which one'},
      '踢足球': {'pinyin': 'tī zú qiú', 'def': 'play soccer'},
      '同学': {'pinyin': 'tóng xué', 'def': 'classmate'},
      '名字': {'pinyin': 'míng zi', 'def': 'name'},
      '后面': {'pinyin': 'hòu miàn', 'def': 'behind; back'},
      '前面': {'pinyin': 'qián miàn', 'def': 'in front; ahead'},
      '里面': {'pinyin': 'lǐ miàn', 'def': 'inside'},
      '外面': {'pinyin': 'wài miàn', 'def': 'outside'},
      '上面': {'pinyin': 'shàng miàn', 'def': 'above; on top'},
      '下面': {'pinyin': 'xià miàn', 'def': 'below; under'},
      '左边': {'pinyin': 'zuǒ biān', 'def': 'left side'},
      '右边': {'pinyin': 'yòu biān', 'def': 'right side'},
      '中间': {'pinyin': 'zhōng jiān', 'def': 'middle; between'},
      '对不起': {'pinyin': 'duì bu qǐ', 'def': 'sorry'},
      '没关系': {'pinyin': 'méi guān xi', 'def': "it's ok"},
      '不客气': {'pinyin': 'bù kè qi', 'def': "you're welcome"},
      '再见': {'pinyin': 'zài jiàn', 'def': 'goodbye'},
      '谢谢': {'pinyin': 'xiè xie', 'def': 'thank you'},
      '请': {'pinyin': 'qǐng', 'def': 'please'},
      '对': {'pinyin': 'duì', 'def': 'correct; right'},
      '错': {'pinyin': 'cuò', 'def': 'wrong; mistake'},
      '快': {'pinyin': 'kuài', 'def': 'fast; quick'},
      '慢': {'pinyin': 'màn', 'def': 'slow'},
      '大': {'pinyin': 'dà', 'def': 'big; large'},
      '小': {'pinyin': 'xiǎo', 'def': 'small; little'},
      '多': {'pinyin': 'duō', 'def': 'many; much'},
      '少': {'pinyin': 'shǎo', 'def': 'few; little'},
      '高': {'pinyin': 'gāo', 'def': 'tall; high'},
      '矮': {'pinyin': 'ǎi', 'def': 'short (height)'},
      '长': {'pinyin': 'cháng', 'def': 'long'},
      '短': {'pinyin': 'duǎn', 'def': 'short (length)'},
      '新': {'pinyin': 'xīn', 'def': 'new'},
      '旧': {'pinyin': 'jiù', 'def': 'old (things)'},
      '老': {'pinyin': 'lǎo', 'def': 'old; elder'},
      '年轻': {'pinyin': 'nián qīng', 'def': 'young'},
      '热': {'pinyin': 'rè', 'def': 'hot'},
      '冷': {'pinyin': 'lěng', 'def': 'cold'},
      '贵': {'pinyin': 'guì', 'def': 'expensive'},
      '便宜': {'pinyin': 'pián yi', 'def': 'cheap'},
      '远': {'pinyin': 'yuǎn', 'def': 'far'},
      '近': {'pinyin': 'jìn', 'def': 'near; close'},
      '容易': {'pinyin': 'róng yì', 'def': 'easy'},
      '难': {'pinyin': 'nán', 'def': 'difficult'},
      '中国': {'pinyin': 'zhōng guó', 'def': 'China'},
      '啊': {'pinyin': 'a/ā/á/ǎ/à', 'def': 'ah; oh'},
      '吗': {'pinyin': 'ma', 'def': 'question particle'},
      '呢': {'pinyin': 'ne', 'def': 'what about...?'},
      '吧': {'pinyin': 'ba', 'def': 'suggestion particle'},
      '鸡': {'pinyin': 'jī', 'def': 'chicken'},
      '鸭': {'pinyin': 'yā', 'def': 'duck'},
      '鱼': {'pinyin': 'yú', 'def': 'fish'},
      '牛': {'pinyin': 'niú', 'def': 'cow; ox'},
      '羊': {'pinyin': 'yáng', 'def': 'sheep; goat'},
      '狗': {'pinyin': 'gǒu', 'def': 'dog'},
      '猪': {'pinyin': 'zhū', 'def': 'pig'},
      '鸟': {'pinyin': 'niǎo', 'def': 'bird'},
      '虫': {'pinyin': 'chóng', 'def': 'insect; worm'},
      '蛇': {'pinyin': 'shé', 'def': 'snake'},
      '龙': {'pinyin': 'lóng', 'def': 'dragon'},
      '虎': {'pinyin': 'hǔ', 'def': 'tiger'},
      '兔': {'pinyin': 'tù', 'def': 'rabbit'},
      '鼠': {'pinyin': 'shǔ', 'def': 'rat; mouse'},
      '象': {'pinyin': 'xiàng', 'def': 'elephant'},
      '熊': {'pinyin': 'xióng', 'def': 'bear'},
      '狼': {'pinyin': 'láng', 'def': 'wolf'},
      '狮': {'pinyin': 'shī', 'def': 'lion'},
      '猴': {'pinyin': 'hóu', 'def': 'monkey'},
      '蜂': {'pinyin': 'fēng', 'def': 'bee'},
      '蚁': {'pinyin': 'yǐ', 'def': 'ant'},
      '蝶': {'pinyin': 'dié', 'def': 'butterfly'},
      
      // Earthly branches that appear in HSK
      '子': {'pinyin': 'zǐ/zi', 'def': 'child; son'},
      '丑': {'pinyin': 'chǒu', 'def': 'ugly; clown'},
      '寅': {'pinyin': 'yín', 'def': 'tiger year'},
      '卯': {'pinyin': 'mǎo', 'def': 'rabbit year'}, 
      '辰': {'pinyin': 'chén', 'def': 'morning; time'},
      '巳': {'pinyin': 'sì', 'def': 'snake year'},
      '未': {'pinyin': 'wèi', 'def': 'not yet'},
      '申': {'pinyin': 'shēn', 'def': 'apply; state'},
      '酉': {'pinyin': 'yǒu', 'def': 'rooster year'},
      '戌': {'pinyin': 'xū', 'def': 'dog year'},
      '亥': {'pinyin': 'hài', 'def': 'pig year'},
      
      // Heavenly stems that appear in HSK
      '甲': {'pinyin': 'jiǎ', 'def': 'first; armor'},
      '乙': {'pinyin': 'yǐ', 'def': 'second; bent'},
      '丙': {'pinyin': 'bǐng', 'def': 'third'},
      '丁': {'pinyin': 'dīng', 'def': 'fourth; person'},
      '戊': {'pinyin': 'wù', 'def': 'fifth'},
      '己': {'pinyin': 'jǐ', 'def': 'self; oneself'},
      '庚': {'pinyin': 'gēng', 'def': 'seventh; age'},
      '辛': {'pinyin': 'xīn', 'def': 'eighth; pungent'},
      '壬': {'pinyin': 'rén', 'def': 'ninth'},
      '癸': {'pinyin': 'guǐ', 'def': 'tenth; last'},
      
      // Common words with technical first definitions
      '为': {'pinyin': 'wèi/wéi', 'def': 'for; because'},
      '什': {'pinyin': 'shén/shí', 'def': 'what (什么)'},
      '么': {'pinyin': 'me/mo', 'def': 'what (什么)'},
      '师': {'pinyin': 'shī', 'def': 'teacher; master'},
      '生': {'pinyin': 'shēng', 'def': 'student; life'},
      '医': {'pinyin': 'yī', 'def': 'doctor; medicine'},
      '易': {'pinyin': 'yì', 'def': 'easy; change'},
      '所': {'pinyin': 'suǒ', 'def': 'place; that which'},
      '以': {'pinyin': 'yǐ', 'def': 'with; by means of'},
      '该': {'pinyin': 'gāi', 'def': 'should; ought to'},
      '假': {'pinyin': 'jiǎ/jià', 'def': 'fake; vacation'},
      '康': {'pinyin': 'kāng', 'def': 'healthy; well'},
      '健': {'pinyin': 'jiàn', 'def': 'healthy; strong'},
      '始': {'pinyin': 'shǐ', 'def': 'begin; start'},
      '终': {'pinyin': 'zhōng', 'def': 'end; finally'},
      '值': {'pinyin': 'zhí', 'def': 'value; worth'},
      '宜': {'pinyin': 'yí', 'def': 'suitable; proper'},
      '容': {'pinyin': 'róng', 'def': 'contain; allow'},
      '届': {'pinyin': 'jiè', 'def': 'session; period'},
      '属': {'pinyin': 'shǔ', 'def': 'belong to; genus'},
      '征': {'pinyin': 'zhēng', 'def': 'journey; sign'},
      '志': {'pinyin': 'zhì', 'def': 'will; aspiration'},
      '忌': {'pinyin': 'jì', 'def': 'avoid; taboo'},
      '既': {'pinyin': 'jì', 'def': 'already; since'},
      '旨': {'pinyin': 'zhǐ', 'def': 'purpose; decree'},
      '章': {'pinyin': 'zhāng', 'def': 'chapter; seal'},
      '童': {'pinyin': 'tóng', 'def': 'child; youth'},
      '端': {'pinyin': 'duān', 'def': 'end; proper'},
      '籍': {'pinyin': 'jí', 'def': 'record; native'},
      '素': {'pinyin': 'sù', 'def': 'plain; element'},
      '维': {'pinyin': 'wéi', 'def': 'maintain; tie'},
      '缘': {'pinyin': 'yuán', 'def': 'edge; fate'},
      '置': {'pinyin': 'zhì', 'def': 'place; set up'},
      '署': {'pinyin': 'shǔ', 'def': 'office; sign'},
      '臣': {'pinyin': 'chén', 'def': 'minister; official'},
      '良': {'pinyin': 'liáng', 'def': 'good; very'},
      '若': {'pinyin': 'ruò', 'def': 'if; like'},
      '范': {'pinyin': 'fàn', 'def': 'model; example'},
      '萌': {'pinyin': 'méng', 'def': 'sprout; cute'},
      '著': {'pinyin': 'zhù/zhuó', 'def': 'write; famous'},
      '衡': {'pinyin': 'héng', 'def': 'weigh; balance'},
      '览': {'pinyin': 'lǎn', 'def': 'look; view'},
      '触': {'pinyin': 'chù', 'def': 'touch; contact'},
      '订': {'pinyin': 'dìng', 'def': 'order; fix'},
      '访': {'pinyin': 'fǎng', 'def': 'visit; seek'},
      '议': {'pinyin': 'yì', 'def': 'discuss; opinion'},
      '诸': {'pinyin': 'zhū', 'def': 'various; all'},
      '谋': {'pinyin': 'móu', 'def': 'plan; seek'},
      '辅': {'pinyin': 'fǔ', 'def': 'assist; auxiliary'},
      '辖': {'pinyin': 'xiá', 'def': 'govern; control'},
      '迁': {'pinyin': 'qiān', 'def': 'move; transfer'},
      '迅': {'pinyin': 'xùn', 'def': 'rapid; quick'},
      '途': {'pinyin': 'tú', 'def': 'way; route'},
      '遇': {'pinyin': 'yù', 'def': 'meet; encounter'},
      '配': {'pinyin': 'pèi', 'def': 'match; distribute'},
      '鉴': {'pinyin': 'jiàn', 'def': 'mirror; inspect'},
      '阐': {'pinyin': 'chǎn', 'def': 'explain; clarify'},
      '陆': {'pinyin': 'lù', 'def': 'land; continent'},
      '隶': {'pinyin': 'lì', 'def': 'slave; belong'},
      '雅': {'pinyin': 'yǎ', 'def': 'elegant; refined'},
      '顽': {'pinyin': 'wán', 'def': 'stubborn; naughty'},
      '频': {'pinyin': 'pín', 'def': 'frequent; frequency'},
      '颇': {'pinyin': 'pō', 'def': 'rather; quite'},
      '第': {'pinyin': 'dì', 'def': 'ordinal number'},
    };
    
    final override = overrides[character];
    if (override != null) {
      // Get original entry if exists for traditional form
      final original = _dictionary?[character];
      return CedictEntry(
        simplified: character,
        traditional: original?.traditional ?? character,
        pinyin: override['pinyin']!,
        definition: override['def']!,
      );
    }
    
    return null;
  }
  
  /// Build a composite definition for multi-character phrases
  CedictEntry? _buildCompositeDefinition(String word) {
    if (_dictionary == null || word.isEmpty) return null;
    
    final definitions = <String>[];
    final pinyins = <String>[];
    
    // Get definition for each character
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      // Look up single character directly to avoid recursion
      final charEntry = _dictionary![char] ?? _getManualOverride(char);
      if (charEntry != null && !_shouldFilterDefinition(charEntry.definition)) {
        // Add the first/main definition
        String def = charEntry.definition.split(';').first.trim();
        // Remove "to" prefix for cleaner concatenation
        if (def.startsWith('to ')) {
          def = def.substring(3);
        }
        definitions.add(def);
        pinyins.add(charEntry.pinyin);
      }
    }
    
    // If we couldn't find definitions for most characters, return null
    if (definitions.length < word.length / 2) {
      return null;
    }
    
    // Create composite entry
    return CedictEntry(
      simplified: word,
      traditional: word,
      pinyin: pinyins.join(' '),
      definition: definitions.join(', '),
    );
  }
}