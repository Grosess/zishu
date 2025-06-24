import '../services/character_stroke_service.dart';
import '../services/character_database.dart';

/// A singleton cache for character preview data to ensure consistent SVG rendering
class CharacterPreviewCache {
  static final CharacterPreviewCache _instance = CharacterPreviewCache._internal();
  factory CharacterPreviewCache() => _instance;
  CharacterPreviewCache._internal();

  final Map<String, CharacterStroke?> _cache = {};
  final Set<String> _loadingCharacters = {};
  final CharacterDatabase _database = CharacterDatabase();
  bool _databaseInitialized = false;

  /// Initialize the database if not already initialized
  Future<void> _ensureInitialized() async {
    if (!_databaseInitialized) {
      await _database.initialize();
      _databaseInitialized = true;
    }
  }

  /// Get character stroke data with caching
  Future<CharacterStroke?> getCharacterStroke(String character) async {
    // Return cached data if available
    if (_cache.containsKey(character)) {
      return _cache[character];
    }

    // If already loading, wait a bit and return null to avoid multiple loads
    if (_loadingCharacters.contains(character)) {
      return null;
    }

    // Mark as loading
    _loadingCharacters.add(character);

    try {
      await _ensureInitialized();
      
      // First try to get from stroke service
      final strokeService = CharacterStrokeService();
      var characterStroke = strokeService.getCharacterStroke(character);
      
      // If not found, try loading from database
      if (characterStroke == null) {
        await _database.loadCharacters([character]);
        characterStroke = strokeService.getCharacterStroke(character);
      }
      
      // Cache the result (even if null)
      _cache[character] = characterStroke;
      
      return characterStroke;
    } finally {
      _loadingCharacters.remove(character);
    }
  }

  /// Preload multiple characters at once
  Future<void> preloadCharacters(List<String> characters) async {
    await _ensureInitialized();
    
    // Filter out already cached characters
    final toLoad = characters.where((c) => !_cache.containsKey(c)).toList();
    
    if (toLoad.isEmpty) return;
    
    // Load all at once
    await _database.loadCharacters(toLoad);
    
    // Cache the results
    final strokeService = CharacterStrokeService();
    for (final character in toLoad) {
      final stroke = strokeService.getCharacterStroke(character);
      _cache[character] = stroke;
    }
  }

  /// Clear the cache (useful for memory management)
  void clearCache() {
    _cache.clear();
    _loadingCharacters.clear();
  }
}