import 'package:shared_preferences/shared_preferences.dart';

/// Manages cached character data to ensure clean loading
class CharacterCacheManager {
  static const String _cacheVersionKey = 'character_cache_version';
  static const String _currentVersion = '2.7'; // Increment this when data format changes
  
  /// Clear cache if version has changed
  static Future<void> checkAndClearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_cacheVersionKey);
    
    if (cachedVersion != _currentVersion) {
      // Production: removed debug print
      // Clear any cached character data
      await clearCharacterCache(prefs);
      // Update version
      await prefs.setString(_cacheVersionKey, _currentVersion);
    }
  }
  
  /// Clear all character-related cache
  static Future<void> clearCharacterCache(SharedPreferences prefs) async {
    // Clear any keys that might contain cached character data
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.contains('character_') || key.contains('stroke_')) {
        await prefs.remove(key);
      }
    }
    // Production: removed debug print
  }
}