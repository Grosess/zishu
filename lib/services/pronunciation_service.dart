import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PronunciationService {
  static final PronunciationService _instance = PronunciationService._internal();
  factory PronunciationService() => _instance;
  PronunciationService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _autoPronounceChinese = true;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _flutterTts = FlutterTts();
    
    // Configure audio session to play even in silent mode
    // iOS: Use playback category to play even when silent/DND
    await _flutterTts!.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      IosTextToSpeechAudioCategoryOptions.duckOthers, // Lower other audio temporarily
    ]);
    
    // Android: Don't request audio focus to avoid interrupting music
    await _flutterTts!.setSharedInstance(true);
    
    // Set default TTS settings
    final languages = await _flutterTts!.getLanguages;
    print('Available TTS languages: $languages');
    
    // Try different Chinese language codes
    bool languageSet = false;
    for (String langCode in ['zh-CN', 'zh_CN', 'cmn-Hans-CN', 'cmn-CN', 'zh']) {
      try {
        await _flutterTts!.setLanguage(langCode);
        languageSet = true;
        print('Successfully set TTS language to: $langCode');
        break;
      } catch (e) {
        print('Failed to set language $langCode: $e');
      }
    }
    
    if (!languageSet) {
      print('WARNING: Could not set Chinese language for TTS');
    }
    
    await _flutterTts!.setSpeechRate(0.4); // Slower for language learning
    await _flutterTts!.setVolume(0.8); // Slightly lower volume to blend better with music
    await _flutterTts!.setPitch(1.0);
    
    // Load settings
    final prefs = await SharedPreferences.getInstance();
    _autoPronounceChinese = prefs.getBool('auto_pronounce_chinese') ?? true;
    
    _isInitialized = true;
  }

  // Apply tone sandhi rules to pinyin
  String applyToneSandhi(String text, String pinyin) {
    // Split pinyin into syllables
    List<String> syllables = pinyin.split(' ');
    
    // Handle 一 (yī) tone changes
    if (text.contains('一')) {
      for (int i = 0; i < syllables.length; i++) {
        if (syllables[i].startsWith('yi') || syllables[i].startsWith('yī')) {
          // Check next syllable
          if (i + 1 < syllables.length) {
            String nextTone = _getTone(syllables[i + 1]);
            if (nextTone == '4') {
              // Before 4th tone → 2nd tone
              syllables[i] = _changeTone(syllables[i], '2');
            } else if (nextTone == '1' || nextTone == '2' || nextTone == '3') {
              // Before 1st, 2nd, 3rd → 4th tone
              syllables[i] = _changeTone(syllables[i], '4');
            }
          }
        }
      }
    }
    
    // Handle 不 (bù) tone changes
    if (text.contains('不')) {
      for (int i = 0; i < syllables.length; i++) {
        if (syllables[i].startsWith('bu') || syllables[i].startsWith('bù')) {
          // Check next syllable
          if (i + 1 < syllables.length) {
            String nextTone = _getTone(syllables[i + 1]);
            if (nextTone == '4') {
              // Before 4th tone → 2nd tone
              syllables[i] = _changeTone(syllables[i], '2');
            }
          }
        }
      }
    }
    
    // Handle 3rd + 3rd → 2nd + 3rd
    for (int i = 0; i < syllables.length - 1; i++) {
      if (_getTone(syllables[i]) == '3' && _getTone(syllables[i + 1]) == '3') {
        syllables[i] = _changeTone(syllables[i], '2');
      }
    }
    
    // Handle common exceptions
    String result = syllables.join(' ');
    
    // Common colloquial merges and exceptions
    result = result
        .replaceAll('yi dian er', 'yì diǎnr')
        .replaceAll('yī diǎn er', 'yì diǎnr')
        .replaceAll('zhè er', 'zhèr')
        .replaceAll('nà er', 'nàr')
        .replaceAll('nǎ er', 'nǎr')
        .replaceAll('shén me', 'shénme')
        .replaceAll('zěn me', 'zěnme')
        .replaceAll('nǎ gè', 'nǎge'); // Can also be něige in spoken
    
    return result;
  }

  // Get tone number from pinyin syllable
  String _getTone(String syllable) {
    if (syllable.contains('ā') || syllable.contains('ē') || syllable.contains('ī') || 
        syllable.contains('ō') || syllable.contains('ū') || syllable.contains('ǖ')) return '1';
    if (syllable.contains('á') || syllable.contains('é') || syllable.contains('í') || 
        syllable.contains('ó') || syllable.contains('ú') || syllable.contains('ǘ')) return '2';
    if (syllable.contains('ǎ') || syllable.contains('ě') || syllable.contains('ǐ') || 
        syllable.contains('ǒ') || syllable.contains('ǔ') || syllable.contains('ǚ')) return '3';
    if (syllable.contains('à') || syllable.contains('è') || syllable.contains('ì') || 
        syllable.contains('ò') || syllable.contains('ù') || syllable.contains('ǜ')) return '4';
    return '0'; // Neutral tone
  }

  // Change tone of a syllable
  String _changeTone(String syllable, String newTone) {
    // Map of tone marks
    Map<String, Map<String, String>> toneMap = {
      'a': {'1': 'ā', '2': 'á', '3': 'ǎ', '4': 'à'},
      'e': {'1': 'ē', '2': 'é', '3': 'ě', '4': 'è'},
      'i': {'1': 'ī', '2': 'í', '3': 'ǐ', '4': 'ì'},
      'o': {'1': 'ō', '2': 'ó', '3': 'ǒ', '4': 'ò'},
      'u': {'1': 'ū', '2': 'ú', '3': 'ǔ', '4': 'ù'},
      'ü': {'1': 'ǖ', '2': 'ǘ', '3': 'ǚ', '4': 'ǜ'},
    };
    
    // Remove existing tone marks
    String clean = syllable
        .replaceAll(RegExp(r'[āáǎà]'), 'a')
        .replaceAll(RegExp(r'[ēéěè]'), 'e')
        .replaceAll(RegExp(r'[īíǐì]'), 'i')
        .replaceAll(RegExp(r'[ōóǒò]'), 'o')
        .replaceAll(RegExp(r'[ūúǔù]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜ]'), 'ü');
    
    // Apply new tone
    // Priority: a > o > e > i/u/ü (whichever comes last)
    if (clean.contains('a')) {
      return clean.replaceFirst('a', toneMap['a']![newTone]!);
    } else if (clean.contains('o')) {
      return clean.replaceFirst('o', toneMap['o']![newTone]!);
    } else if (clean.contains('e')) {
      return clean.replaceFirst('e', toneMap['e']![newTone]!);
    } else if (clean.contains('ü')) {
      return clean.replaceFirst('ü', toneMap['ü']![newTone]!);
    } else if (clean.contains('iu')) {
      // Special case: iu → iù (tone on u)
      return clean.replaceFirst('u', toneMap['u']![newTone]!);
    } else if (clean.contains('ui')) {
      // Special case: ui → uì (tone on i)
      return clean.replaceFirst('i', toneMap['i']![newTone]!);
    } else if (clean.contains('i')) {
      return clean.replaceFirst('i', toneMap['i']![newTone]!);
    } else if (clean.contains('u')) {
      return clean.replaceFirst('u', toneMap['u']![newTone]!);
    }
    
    return syllable; // Return unchanged if no vowel found
  }

  // Speak Chinese text with proper pronunciation
  Future<void> speak(String text, {String? pinyin}) async {
    if (!_isInitialized) await initialize();
    if (_flutterTts == null) return;
    
    try {
      // Stop any ongoing speech first
      await _flutterTts!.stop();
      
      // If pinyin is provided, apply tone sandhi rules
      String textToSpeak = text;
      if (pinyin != null && pinyin.isNotEmpty) {
        // Apply tone sandhi rules to get proper pronunciation
        String adjustedPinyin = applyToneSandhi(text, pinyin);
        
        // For TTS, we still speak the Chinese characters, but we've validated the pronunciation
        // Some TTS engines support SSML or phonetic hints, but flutter_tts doesn't expose this
        // So we just speak the text and rely on the TTS engine's built-in rules
      }
      
      // Ensure we're using the correct language (try multiple codes)
      bool langSet = false;
      for (String langCode in ['zh-CN', 'zh_CN', 'cmn-Hans-CN', 'cmn-CN', 'zh']) {
        try {
          await _flutterTts!.setLanguage(langCode);
          langSet = true;
          break;
        } catch (e) {
          continue;
        }
      }
      
      // Start speaking
      final result = await _flutterTts!.speak(textToSpeak);
      if (result != 1) {
        print('TTS speak failed with result: $result');
      }
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  // Speak automatically if enabled
  Future<void> speakIfEnabled(String text, {String? pinyin}) async {
    if (!_isInitialized) await initialize();
    
    // Reload setting in case it changed
    final prefs = await SharedPreferences.getInstance();
    _autoPronounceChinese = prefs.getBool('auto_pronounce_chinese') ?? true;
    
    if (_autoPronounceChinese) {
      await speak(text, pinyin: pinyin);
    }
  }

  // Stop speaking
  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
  }

  // Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(rate);
    }
  }
}