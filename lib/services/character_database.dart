import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'character_stroke_service.dart';
import 'placeholder_characters.dart';
import '../config/database_config.dart';

/// Manages the character database and provides on-demand loading
class CharacterDatabase {
  static final CharacterDatabase _instance = CharacterDatabase._internal();
  factory CharacterDatabase() => _instance;
  
  CharacterDatabase._internal() {
    // Database initialization
  }
  
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  
  // Cache loaded characters with LRU eviction
  final Map<String, CharacterStroke> _cache = {};
  static const int _maxCacheSize = 200; // Reduced for better memory management
  final List<String> _cacheOrder = [];
  
  // Index mapping characters to line numbers in graphics.txt
  Map<String, int>? _index;
  
  // The graphics data lines (loaded once)
  List<String>? _graphicsLines;
  
  // Path to graphics file - get dynamically to avoid caching issues
  String get _graphicsPath => DatabaseConfig.databasePath;
  
  bool _initialized = false;
  bool _isLoading = false;
  
  // For large databases, we'll load in chunks
  static const int CHUNK_SIZE = 1000;
  
  /// Initialize the database by loading the index
  Future<void> initialize() async {
    if (_initialized || _isLoading) {
      return;
    }
    
    _isLoading = true;
    
    // Initialize database
    
    // Clear any stale data if switching databases
    _index = null;
    _graphicsLines = null;
    _cache.clear();
    
    // Only clear stroke service on first initialization or when switching databases
    // Don't clear if we already have data loaded
    if (_strokeService.availableCharacters.isEmpty) {
      _strokeService.clearData();
    }
    
    try {
      // For large databases, we load the index but not all data
      await _loadIndex();
    } catch (e) {
      // Initialize empty index so placeholder fallback works
      _index = {};
      _graphicsLines = [];
    } finally {
      _isLoading = false;
    }
    
    _initialized = true;
  }
  
  /// Force reload the database - useful for debugging
  Future<void> forceReload() async {
    
    _initialized = false;
    _isLoading = false;
    _index = null;
    _graphicsLines = null;
    _cache.clear();
    
    // Only clear the stroke service if we're force reloading
    // Don't clear it during normal initialization as it might contain valid data
    _strokeService.clearData();
    
    await initialize();
  }
  
  Future<void> _loadIndex() async {
    try {
      // Try to load a pre-built index first
      await _loadPrebuiltIndex();
    } catch (e) {
      // Build index from graphics file
      await _buildIndexFromGraphics();
    }
  }
  
  Future<void> _loadPrebuiltIndex() async {
    try {
      final indexData = await rootBundle.loadString('assets/character_index.json');
      final json = jsonDecode(indexData);
      _index = Map<String, int>.from(json['index'] ?? {});
      // Production: removed debug print
    } catch (e) {
      throw Exception('No pre-built index found');
    }
  }
  
  Future<void> _buildIndexFromGraphics() async {
    try {
      // Production: removed debug print
      
      // Load file in a more memory-efficient way
      final stopwatch = Stopwatch()..start();
      final file = await rootBundle.loadString(_graphicsPath);
      
      // Don't keep entire file in memory - just build index
      final lines = file.split('\n');
      // Production: removed debug print
      
      // Always keep lines in memory for now to fix character loading issues
      // TODO: Implement a more efficient solution later
      _graphicsLines = lines;
      await _buildIndexFromLines(lines);
      
      stopwatch.stop();
      // Production: removed debug print
    } catch (e) {
      // Production: removed debug print
      rethrow;
    }
  }
  
  Future<void> _loadMinimalData() async {
    // Don't load sample data when using full database
    if (!DatabaseConfig.USE_FULL_DATABASE) {
      // Production: removed debug print
      await _strokeService.loadSampleData();
    } else {
      // Production: removed debug print
    }
  }
  
  Future<void> _buildIndex() async {
    _index = {};
    
    if (_graphicsLines == null) {
      // Production: removed debug print
      return;
    }
    
    await _buildIndexFromLines(_graphicsLines!);
  }
  
  Future<void> _buildIndexFromLines(List<String> lines) async {
    _index = {};
    
    // Process in chunks to avoid blocking UI
    const chunkSize = 5000;
    
    for (int start = 0; start < lines.length; start += chunkSize) {
      final end = math.min(start + chunkSize, lines.length);
      
      for (int i = start; i < end; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Optimize JSON parsing by only extracting character field
          final charIndex = line.indexOf('"character":');
          if (charIndex != -1) {
            final charStart = line.indexOf('"', charIndex + 12) + 1;
            final charEnd = line.indexOf('"', charStart);
            if (charStart > 0 && charEnd > charStart) {
              final character = line.substring(charStart, charEnd);
              _index![character] = i;
            }
          }
        } catch (e) {
          // Skip malformed lines
        }
      }
      
      // Yield to prevent blocking UI
      if (end < lines.length) {
        await Future.delayed(Duration.zero);
      }
    }
    
    // Production: removed debug print
  }
  
  /// Load specific characters into the stroke service
  Future<void> loadCharacters(List<String> characters) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Loading characters
    
    // For large character sets, load in batches
    if (characters.length > 10) {
      await _loadCharactersBatch(characters);
    } else {
      await _loadCharactersIndividual(characters);
    }
  }
  
  Future<void> _loadCharactersIndividual(List<String> characters) async {
    // Ensure graphics lines are loaded
    if (_graphicsLines == null) {
      await _ensureGraphicsLoaded();
    }
    
    for (final character in characters) {
      // Check if already in stroke service first
      if (_strokeService.hasCharacter(character)) {
        // Debug: Character "$character" already in stroke service, skipping load
        continue;
      }
      
      // Check cache next
      if (_cache.containsKey(character)) {
        _strokeService.addCharacterStroke(_cache[character]!);
        continue;
      }
      
      // Load from database or placeholder
      final strokeData = await _loadCharacter(character);
      if (strokeData != null) {
        _addToCache(character, strokeData);
        _strokeService.addCharacterStroke(strokeData);
      } else {
        // Production: removed debug print
      }
    }
  }
  
  Future<void> _loadCharactersBatch(List<String> characters) async {
    // Filter out characters already loaded
    final charactersToLoad = <String>[];
    for (final character in characters) {
      if (!_strokeService.hasCharacter(character) && !_cache.containsKey(character)) {
        charactersToLoad.add(character);
      } else if (_cache.containsKey(character) && !_strokeService.hasCharacter(character)) {
        // Add from cache to stroke service
        _strokeService.addCharacterStroke(_cache[character]!);
      }
    }
    
    if (charactersToLoad.isEmpty) return;
    
    // Ensure graphics lines are loaded for batch processing
    if (_graphicsLines == null) {
      await _ensureGraphicsLoaded();
    }
    
    if (_graphicsLines == null || _index == null) {
      // Fallback to individual loading
      await _loadCharactersIndividual(charactersToLoad);
      return;
    }
    
    // Process characters in optimized batch
    for (final character in charactersToLoad) {
      
      // Check if character exists in index
      final lineIndex = _index![character];
      
      // If character not in index, try placeholder
      if (lineIndex == null) {
        // Try to load the character directly by searching through the file
        final strokeData = await _loadCharacterDirectly(character);
        if (strokeData != null) {
          _addToCache(character, strokeData);
          _strokeService.addCharacterStroke(strokeData);
          continue;
        }
        
        // Fall back to placeholder if available
        final placeholderData = PlaceholderCharacters.getPlaceholder(character);
        if (placeholderData != null) {
          // Using placeholder data
          _addToCache(character, placeholderData);
          _strokeService.addCharacterStroke(placeholderData);
          continue;
        } else {
          // Production: removed debug print
          continue;
        }
      }
      
      // Log what we're about to load for problematic characters
      if (character == '国' || character == '出' || character == '生') {
        // Production: removed debug print
      }
      
      if (lineIndex < _graphicsLines!.length) {
        try {
          final line = _graphicsLines![lineIndex];
          if (line.trim().isEmpty) {
            // Production: removed debug print
            continue;
          }
          final json = jsonDecode(line);
          
          // Verify we got the right character
          final loadedChar = json['character'] as String;
          if (loadedChar != character) {
            // Production: removed debug print
            // Production: removed debug print
            // Production: removed debug print
            
            // Don't use mismatched data! Try placeholder instead
            final placeholderData = PlaceholderCharacters.getPlaceholder(character);
            if (placeholderData != null) {
              // Production: removed debug print
              _cache[character] = placeholderData;
              _strokeService.addCharacterStroke(placeholderData);
            }
            continue;
          }
          
          final strokeData = CharacterStroke.fromJson(json);
          // Production: removed debug print
          _cache[character] = strokeData;
          _strokeService.addCharacterStroke(strokeData);
        } catch (e) {
          // Production: removed debug print
          // Error loading character
        }
      } else {
        // Production: removed debug print
      }
    }
  }
  
  Future<void> _ensureGraphicsLoaded() async {
    if (_graphicsLines == null) {
      try {
        // Production: removed debug print
        // Production: removed debug print
        // Production: removed debug print
        
        final stopwatch = Stopwatch()..start();
        final file = await rootBundle.loadString(_graphicsPath);
        // Production: removed debug print
        _graphicsLines = file.split('\n');
        // Production: removed debug print
        
        // Verify we loaded the right database
        if (_graphicsLines!.length < 1000 && DatabaseConfig.USE_FULL_DATABASE) {
          // Production: removed debug print
          // Production: removed debug print
        }
        
        stopwatch.stop();
      } catch (e) {
        // Production: removed debug print
        // Production: removed debug print
      }
    }
  }
  
  /// Load a single character
  Future<CharacterStroke?> _loadCharacter(String character) async {
    if (_index == null || _graphicsLines == null) {
      // If database not loaded, try placeholder data
      final placeholderData = PlaceholderCharacters.getPlaceholder(character);
      if (placeholderData != null) {
        // Using placeholder data - database not loaded
        return placeholderData;
      }
      return null;
    }
    
    final lineIndex = _index![character];
    if (lineIndex == null || lineIndex >= _graphicsLines!.length) {
      // Character not in database, try placeholder
      final placeholderData = PlaceholderCharacters.getPlaceholder(character);
      if (placeholderData != null) {
        // Using placeholder data - not in database
        return placeholderData;
      }
      return null;
    }
    
    try {
      final line = _graphicsLines![lineIndex];
      if (line.trim().isEmpty) {
        // Production: removed debug print
        return null;
      }
      final json = jsonDecode(line);
      
      // Verify we got the right character
      final loadedChar = json['character'] as String;
      if (loadedChar != character) {
        // Production: removed debug print
        // Try to find the correct line
        for (int i = 0; i < _graphicsLines!.length; i++) {
          try {
            final testLine = _graphicsLines![i].trim();
            if (testLine.isEmpty) continue;
            final testJson = jsonDecode(testLine);
            if (testJson['character'] == character) {
              // Found correct character at different line
              _index![character] = i; // Fix the index
              return CharacterStroke.fromJson(testJson);
            }
          } catch (_) {}
        }
        return null;
      }
      
      // Production: removed debug print
      
      // Validate the loaded data
      final strokeData = CharacterStroke.fromJson(json);
      
      // Additional validation logging
      if (strokeData.strokes.isNotEmpty) {
        final firstStroke = strokeData.strokes.first;
        final hasQ = firstStroke.contains(' Q ');
        // Production: removed debug print
        
        // Check if this looks like placeholder data
        int qCount = 0;
        for (final stroke in strokeData.strokes) {
          if (stroke.contains(' Q ')) qCount++;
        }
        if (qCount == 0) {
          // Production: removed debug print
        }
      }
      
      return strokeData;
    } catch (e) {
      // Production: removed debug print
      return null;
    }
  }
  
  /// Check if a character is available
  bool hasCharacter(String character) {
    // Check cache first
    if (_cache.containsKey(character)) {
      return true;
    }
    // Check if it's already loaded in stroke service
    if (_strokeService.hasCharacter(character)) {
      return true;
    }
    // Check index
    if (_index?.containsKey(character) ?? false) {
      return true;
    }
    // If not in database, check placeholder as fallback
    if (PlaceholderCharacters.hasPlaceholder(character)) {
      return true;
    }
    return false;
  }
  
  /// Check if all characters in a string are available
  Future<Map<String, bool>> checkCharactersAvailability(List<String> characters) async {
    if (!_initialized) {
      await initialize();
    }
    
    final availability = <String, bool>{};
    for (final char in characters) {
      availability[char] = hasCharacter(char);
    }
    return availability;
  }
  
  /// Get all available characters
  List<String> get availableCharacters {
    return _index?.keys.toList() ?? [];
  }
  
  /// Load a character directly by searching through the file
  Future<CharacterStroke?> _loadCharacterDirectly(String character) async {
    try {
      // Debug: Direct search for "$character" (codePoint: ${character.codeUnitAt(0)}) starting...
      
      // Load the graphics file if not already loaded
      if (_graphicsLines == null) {
        // Debug: Graphics lines not in memory, loading...
        await _ensureGraphicsLoaded();
      }
      
      if (_graphicsLines == null) {
        // Debug: ERROR: Failed to load graphics lines
        return null;
      }
      
      // Debug: Searching through ${_graphicsLines!.length} lines...
      
      // Also try to rebuild the index if it's incomplete
      if (_index != null && _index!.length < 1000) {
        // Debug: Index seems incomplete (${_index!.length} entries), rebuilding...
        await _buildIndexFromLines(_graphicsLines!);
        
        // Check if character is now in the rebuilt index
        if (_index!.containsKey(character)) {
          final lineIndex = _index![character]!;
          // Debug: Found "$character" in rebuilt index at line $lineIndex
          if (lineIndex < _graphicsLines!.length) {
            try {
              final line = _graphicsLines![lineIndex].trim();
              if (!line.isEmpty) {
                final json = jsonDecode(line);
                if (json['character'] == character) {
                  return CharacterStroke.fromJson(json);
                }
              }
            } catch (e) {
              // Debug: Error parsing line $lineIndex: $e
            }
          }
        }
      }
      
      // Search through the lines for this character
      int foundCount = 0;
      for (int i = 0; i < _graphicsLines!.length; i++) {
        final line = _graphicsLines![i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Quick check if this line contains our character
          if (line.contains('"character":"$character"')) {
            final json = jsonDecode(line);
            if (json['character'] == character) {
              // Debug: Found "$character" at line $i
              // Found it! Update the index
              _index ??= {};
              _index![character] = i;
              
              final strokeData = CharacterStroke.fromJson(json);
              return strokeData;
            } else {
              // Debug: False positive: line contains "$character" but parsed as "${json['character']}"
            }
          }
          
          // Also check if this is "切" specifically since it's problematic
          if (character == '切' && line.contains('切')) {
            foundCount++;
            if (foundCount <= 3) {
              // Debug: Line $i contains 切: ${line.substring(0, math.min(100, line.length))}...
            }
          }
        } catch (e) {
          // Skip malformed lines
        }
      }
      
      // Debug: Character "$character" not found in any line. Total lines containing "切": $foundCount
    } catch (e) {
      // Debug: ERROR in direct search: $e
    }
    
    return null;
  }
  
  /// Preload common characters for better performance
  Future<void> preloadCommonCharacters() async {
    if (DatabaseConfig.PRELOAD_COMMON_CHARACTERS && DatabaseConfig.COMMON_CHARACTERS.isNotEmpty) {
      // Production: removed debug print
      
      final available = DatabaseConfig.COMMON_CHARACTERS.where((c) => hasCharacter(c)).toList();
      // Production: removed debug print
      
      if (available.isNotEmpty) {
        await loadCharacters(available);
      }
    }
  }
  
  void _addToCache(String character, CharacterStroke stroke) {
    // Add to cache with LRU eviction
    if (_cache.containsKey(character)) {
      _cacheOrder.remove(character);
    }
    
    _cache[character] = stroke;
    _cacheOrder.add(character);
    
    // Evict oldest if cache is too large
    if (_cache.length > _maxCacheSize) {
      final oldest = _cacheOrder.removeAt(0);
      _cache.remove(oldest);
    }
  }
}