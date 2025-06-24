import 'character_stroke_service.dart';

/// Provides placeholder data for common characters when they're not available in the sample database
class PlaceholderCharacters {
  // Empty placeholder map - all characters should be loaded from the database
  static final Map<String, CharacterStroke> placeholders = {};
  
  /// Get placeholder data for a character if available
  static CharacterStroke? getPlaceholder(String character) {
    return placeholders[character];
  }
  
  /// Check if a character has placeholder data
  static bool hasPlaceholder(String character) {
    return placeholders.containsKey(character);
  }
}