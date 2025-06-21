/// Service to provide information about why characters might not be available
class CharacterInfoService {
  static final CharacterInfoService _instance = CharacterInfoService._internal();
  factory CharacterInfoService() => _instance;
  CharacterInfoService._internal();

  // Categories of characters that might not be in MakeMeAHanzi
  static const Map<String, String> _characterCategories = {
    // Dialectal characters
    '覅': 'Dialectal character (Wu Chinese) - not in standard character sets',
    '嘸': 'Dialectal character - not commonly used in standard Mandarin',
    '乜': 'Dialectal character (Cantonese) - limited usage',
    
    // Rare/archaic characters
    '龘': 'Extremely rare character - not commonly taught',
    '靐': 'Archaic character - rarely used in modern Chinese',
    
    // Japanese-specific kanji
    '峠': 'Japanese-only kanji - not used in Chinese',
    '辻': 'Japanese-only kanji - not used in Chinese',
    
    // Simplified vs Traditional issues
    '説': 'Traditional variant - the simplified form 说 may be available',
    '國': 'Traditional form - the simplified form 国 may be available',
  };

  static const Map<String, List<String>> _characterAlternatives = {
    '覅': ['不要', '别'],
    '説': ['说'],
    '國': ['国'],
    '學': ['学'],
    '愛': ['爱'],
    '書': ['书'],
    '見': ['见'],
    '會': ['会'],
  };

  /// Get information about why a character might not be available
  String getCharacterInfo(String character) {
    // Check if it's a known problematic character
    if (_characterCategories.containsKey(character)) {
      return _characterCategories[character]!;
    }
    
    // Check Unicode range
    final codePoint = character.codeUnitAt(0);
    
    // CJK Unified Ideographs Extension B-G (rare characters)
    if (codePoint >= 0x20000 && codePoint <= 0x2CEAF) {
      return 'Extended Unicode character - very rare, not in common databases';
    }
    
    // CJK Compatibility Ideographs
    if (codePoint >= 0xF900 && codePoint <= 0xFAFF) {
      return 'Compatibility character - use the standard unified form instead';
    }
    
    // Check if it's a variant selector
    if (codePoint >= 0xFE00 && codePoint <= 0xFE0F) {
      return 'Variant selector - not a character itself';
    }
    
    // Default message
    return 'Character not found in MakeMeAHanzi database (covers ~9,500 common characters)';
  }

  /// Get alternative characters if available
  List<String>? getAlternatives(String character) {
    return _characterAlternatives[character];
  }

  /// Check if character is likely traditional
  bool isLikelyTraditional(String character) {
    // Simple heuristic based on stroke count (traditional characters tend to have more strokes)
    final traditionalMarkers = ['門', '馬', '魚', '鳥', '車', '貝', '見', '言', '金'];
    for (final marker in traditionalMarkers) {
      if (character.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  /// Get a user-friendly explanation for missing characters
  String getDetailedExplanation(String character) {
    final info = getCharacterInfo(character);
    final alternatives = getAlternatives(character);
    
    var explanation = info;
    
    if (alternatives != null && alternatives.isNotEmpty) {
      explanation += '\n\nAlternatives you can use:\n';
      explanation += alternatives.map((alt) => '• $alt').join('\n');
    }
    
    if (isLikelyTraditional(character)) {
      explanation += '\n\nThis appears to be a traditional character. ';
      explanation += 'Try using the simplified version instead.';
    }
    
    return explanation;
  }
}