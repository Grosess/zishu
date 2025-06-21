import 'dart:async';
import 'character_database.dart';
import 'character_stroke_service.dart';

/// Callback for progress updates during character loading
typedef LoadProgressCallback = void Function(int loaded, int total, String message);

/// Optimized character loading with progress tracking and caching
class OptimizedCharacterLoader {
  static final OptimizedCharacterLoader _instance = OptimizedCharacterLoader._internal();
  factory OptimizedCharacterLoader() => _instance;
  OptimizedCharacterLoader._internal();

  final CharacterDatabase _database = CharacterDatabase();
  
  // Loading state
  bool _isLoading = false;
  final Set<String> _loadingCharacters = {};
  final Set<String> _loadedCharacters = {};
  
  // Progress tracking
  LoadProgressCallback? _progressCallback;
  
  /// Set a callback to receive loading progress updates
  void setProgressCallback(LoadProgressCallback? callback) {
    _progressCallback = callback;
  }
  
  /// Check if characters are currently being loaded
  bool get isLoading => _isLoading;
  
  /// Get the set of already loaded characters
  Set<String> get loadedCharacters => Set.unmodifiable(_loadedCharacters);
  
  /// Initialize the loader and database
  Future<void> initialize() async {
    _reportProgress(0, 1, 'Initializing character database...');
    await _database.initialize();
    _reportProgress(1, 1, 'Database initialized');
  }
  
  /// Load characters with progress tracking and optimization
  Future<void> loadCharacters(
    List<String> characters, {
    bool preloadRelated = false,
    int batchSize = 50,
  }) async {
    if (_isLoading) {
      // Production: removed debug print
      // Wait for current loading to complete
      await _waitForLoading();
    }
    
    _isLoading = true;
    
    try {
      // Filter out already loaded characters
      final charactersToLoad = characters
          .where((char) => !_loadedCharacters.contains(char))
          .toList();
      
      if (charactersToLoad.isEmpty) {
        _reportProgress(1, 1, 'All characters already loaded');
        return;
      }
      
      // Production: removed debug print
      
      // Load in batches for better performance and progress tracking
      final totalBatches = (charactersToLoad.length / batchSize).ceil();
      
      for (int i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = (start + batchSize).clamp(0, charactersToLoad.length);
        final batch = charactersToLoad.sublist(start, end);
        
        _reportProgress(
          start,
          charactersToLoad.length,
          'Loading characters ${start + 1}-$end of ${charactersToLoad.length}...',
        );
        
        // Mark batch as loading
        _loadingCharacters.addAll(batch);
        
        // Load the batch
        await _database.loadCharacters(batch);
        
        // Mark as loaded
        _loadedCharacters.addAll(batch);
        _loadingCharacters.removeAll(batch);
        
        // Small delay between batches to prevent UI freezing
        if (i < totalBatches - 1) {
          await Future.delayed(Duration(milliseconds: 10));
        }
      }
      
      _reportProgress(
        charactersToLoad.length,
        charactersToLoad.length,
        'Completed loading ${charactersToLoad.length} characters',
      );
      
      // Optionally preload related characters (radicals, components)
      if (preloadRelated) {
        await _preloadRelatedCharacters(characters);
      }
      
    } finally {
      _isLoading = false;
    }
  }
  
  /// Load a single character with optimization
  Future<bool> loadCharacter(String character) async {
    if (_loadedCharacters.contains(character)) {
      return true;
    }
    
    if (_loadingCharacters.contains(character)) {
      // Wait for this specific character to load
      await _waitForCharacter(character);
      return _loadedCharacters.contains(character);
    }
    
    try {
      _loadingCharacters.add(character);
      await _database.loadCharacters([character]);
      _loadedCharacters.add(character);
      return true;
    } catch (e) {
      // Production: removed debug print
      return false;
    } finally {
      _loadingCharacters.remove(character);
    }
  }
  
  /// Preload characters that are likely to be needed soon
  Future<void> preloadAdjacentCharacters(
    List<String> currentSet,
    int currentIndex, {
    int lookAhead = 10,
    int lookBehind = 5,
  }) async {
    final charactersToPreload = <String>[];
    
    // Look ahead
    for (int i = currentIndex + 1; 
         i < currentSet.length && i <= currentIndex + lookAhead; 
         i++) {
      if (!_loadedCharacters.contains(currentSet[i])) {
        charactersToPreload.add(currentSet[i]);
      }
    }
    
    // Look behind (in case user goes back)
    for (int i = currentIndex - 1; 
         i >= 0 && i >= currentIndex - lookBehind; 
         i--) {
      if (!_loadedCharacters.contains(currentSet[i])) {
        charactersToPreload.add(currentSet[i]);
      }
    }
    
    if (charactersToPreload.isNotEmpty) {
      // Load in background without blocking
      loadCharacters(charactersToPreload, batchSize: 5).catchError((e) {
        // Production: removed debug print
      });
    }
  }
  
  /// Clear loaded characters to free memory
  void clearCache({List<String>? keepCharacters}) {
    if (keepCharacters != null) {
      _loadedCharacters.removeWhere((char) => !keepCharacters.contains(char));
    } else {
      _loadedCharacters.clear();
    }
    
    // Also clear from stroke service
    CharacterStrokeService().clearData();
    
    // Reload kept characters if any
    if (keepCharacters != null && keepCharacters.isNotEmpty) {
      loadCharacters(keepCharacters).catchError((e) {
        // Production: removed debug print
      });
    }
  }
  
  /// Get loading statistics
  Map<String, dynamic> getLoadingStats() {
    return {
      'loadedCount': _loadedCharacters.length,
      'isLoading': _isLoading,
      'loadingCount': _loadingCharacters.length,
      'memoryEstimateMB': (_loadedCharacters.length * 0.05).toStringAsFixed(2), // Rough estimate
    };
  }
  
  // Private helper methods
  
  void _reportProgress(int loaded, int total, String message) {
    _progressCallback?.call(loaded, total, message);
  }
  
  Future<void> _waitForLoading() async {
    while (_isLoading) {
      await Future.delayed(Duration(milliseconds: 50));
    }
  }
  
  Future<void> _waitForCharacter(String character) async {
    while (_loadingCharacters.contains(character)) {
      await Future.delayed(Duration(milliseconds: 50));
    }
  }
  
  Future<void> _preloadRelatedCharacters(List<String> characters) async {
    // This could be expanded to load character components, radicals, etc.
    // For now, just a placeholder
    _reportProgress(0, 1, 'Analyzing related characters...');
    
    // Example: Find and load common radicals
    final relatedChars = <String>{};
    
    // Add common radicals that might appear
    final commonRadicals = ['氵', '亻', '口', '土', '女', '心', '手', '日', '月', '木'];
    for (final radical in commonRadicals) {
      if (!_loadedCharacters.contains(radical)) {
        relatedChars.add(radical);
      }
    }
    
    if (relatedChars.isNotEmpty) {
      await loadCharacters(relatedChars.toList(), batchSize: 10);
    }
    
    _reportProgress(1, 1, 'Related characters loaded');
  }
}