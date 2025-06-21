# Character Loading Optimization Guide

## Overview

The Zishu app uses several optimization techniques to handle the large MakeMeAHanzi character database efficiently:

1. **Lazy Loading**: Characters are loaded only when needed
2. **Batch Processing**: Multiple characters loaded together for efficiency
3. **Caching**: Loaded characters are kept in memory for quick access
4. **Progress Tracking**: Users see loading progress for better UX
5. **Preloading**: Adjacent characters loaded in background

## Implementation Details

### 1. OptimizedCharacterLoader Service

Located at: `lib/services/optimized_character_loader.dart`

Key features:
- Singleton pattern for centralized loading
- Progress callbacks for UI updates
- Batch loading with configurable size
- Memory management with cache clearing

### 2. Character Loading Widget

Located at: `lib/widgets/character_loading_indicator.dart`

Provides:
- Loading overlay with progress bar
- Inline loading indicators
- Mixin for easy integration

### 3. Database Optimizations

The `CharacterDatabase` service includes:
- Index-based lookups (O(1) character access)
- Chunked file reading for large databases
- Placeholder fallback for missing characters

## Usage Examples

### Basic Character Loading

```dart
final loader = OptimizedCharacterLoader();

// Load a set of characters
await loader.loadCharacters(['你', '好', '世', '界']);

// Load with progress tracking
loader.setProgressCallback((loaded, total, message) {
  print('Progress: $loaded/$total - $message');
});
```

### In Practice Screen

```dart
class WritingPracticePageState extends State<WritingPracticePage> 
    with CharacterLoadingMixin {
  
  @override
  void initState() {
    super.initState();
    _loadCharacterSet();
  }
  
  Future<void> _loadCharacterSet() async {
    // This will automatically show progress
    await loadCharactersWithProgress(widget.characters);
    
    // Preload next characters
    loader.preloadAdjacentCharacters(
      widget.characters,
      _currentIndex,
      lookAhead: 5,
    );
  }
}
```

### With Loading Indicator Widget

```dart
@override
Widget build(BuildContext context) {
  return CharacterLoadingIndicator(
    showOverlay: true,
    child: Scaffold(
      // Your UI here
    ),
  );
}
```

## Performance Tips

### 1. Batch Size Selection

- Small sets (< 10 chars): Load individually
- Medium sets (10-100 chars): Use batch size 25-50
- Large sets (> 100 chars): Use batch size 50-100

### 2. Memory Management

```dart
// Clear cache when switching between large sets
loader.clearCache(keepCharacters: currentSetCharacters);

// Check memory usage
final stats = loader.getLoadingStats();
print('Loaded: ${stats['loadedCount']} chars');
print('Memory: ${stats['memoryEstimateMB']} MB');
```

### 3. Preloading Strategy

```dart
// Preload based on user behavior
if (userIsScrollingForward) {
  loader.preloadAdjacentCharacters(
    characters, 
    currentIndex,
    lookAhead: 10,
    lookBehind: 2,
  );
}
```

## Debugging

Enable debug logging:

```dart
// In CharacterDatabase
print('Loading character $character from line $lineIndex');
print('Cache hit rate: ${cacheHits / totalRequests}');
```

Common issues:

1. **Slow initial load**: 
   - Check if index is built
   - Verify batch size is appropriate

2. **Memory issues**:
   - Implement cache size limits
   - Clear cache between sessions

3. **Missing characters**:
   - Check placeholder fallback
   - Verify database path

## Future Optimizations

### 1. Background Threading
```dart
// TODO: Move loading to isolate
await compute(loadCharacterBatch, characters);
```

### 2. Persistent Cache
```dart
// TODO: Save frequently used characters
await saveCharacterCache(topCharacters);
```

### 3. Smart Preloading
```dart
// TODO: ML-based prediction
final predicted = await predictNextCharacters(history);
loader.preloadCharacters(predicted);
```

## Benchmarks

Current performance (tested on mid-range device):
- Index building: ~2 seconds for 10,000 characters
- Single character load: < 10ms (from cache)
- Batch load (50 chars): ~200ms
- Memory per character: ~50KB

Target improvements:
- Reduce index building to < 1 second
- Batch load optimization to < 100ms
- Memory usage reduction by 30%

## Integration Checklist

When adding character loading to a new screen:

- [ ] Import OptimizedCharacterLoader
- [ ] Add CharacterLoadingMixin if using StatefulWidget
- [ ] Wrap in CharacterLoadingIndicator for progress UI
- [ ] Call loadCharacters before displaying
- [ ] Implement error handling
- [ ] Consider preloading strategy
- [ ] Test with large character sets
- [ ] Monitor memory usage