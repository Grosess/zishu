import 'package:shared_preferences/shared_preferences.dart';
import 'streak_service.dart';
import '../main.dart' as main;

class LearningService {
  static final LearningService _instance = LearningService._internal();
  factory LearningService() => _instance;
  LearningService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;
  
  // Cache for learned items
  Set<String>? _cachedLearnedCharacters;
  Set<String>? _cachedLearnedWords;
  DateTime? _lastCacheUpdate;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Mark a character as learned
  Future<void> markCharacterAsLearned(String character, {bool updateTodayProgress = true}) async {
    await initialize();
    
    // Clear cache to force fresh read
    clearCache();
    
    final learned = await getLearnedCharacters();
    if (!learned.contains(character)) {
      learned.add(character);
      await _prefs.setStringList('learned_characters', learned);
      
      // Update cache with new data
      _cachedLearnedCharacters = learned.toSet();
      _lastCacheUpdate = DateTime.now();
      
      // Update the timestamp
      final key = 'learned_character_$character';
      await _prefs.setString(key, DateTime.now().toIso8601String());
      
      // Force sync to ensure persistence
      await _prefs.reload();
      
      // Update streak progress only if requested
      if (updateTodayProgress) {
        final streakService = StreakService();
        await streakService.updateLearnedProgress(1);
        
        // Refresh UI if possible
        try {
          main.refreshStreakDisplay();
        } catch (_) {
          // Ignore if main screen is not available
        }
      }
    }
  }

  // Mark multiple characters as learned
  Future<void> markCharactersAsLearned(List<String> characters, {bool updateTodayProgress = true}) async {
    await initialize();
    
    // Clear cache to force fresh read
    clearCache();
    
    final learned = await getLearnedCharacters();
    final newLearned = <String>[];
    
    for (final char in characters) {
      if (!learned.contains(char)) {
        newLearned.add(char);
        learned.add(char);
        
        // Update the timestamp
        final key = 'learned_character_$char';
        await _prefs.setString(key, DateTime.now().toIso8601String());
      }
    }
    
    if (newLearned.isNotEmpty) {
      await _prefs.setStringList('learned_characters', learned);
      
      // Update cache with new data
      _cachedLearnedCharacters = learned.toSet();
      _lastCacheUpdate = DateTime.now();
      
      // Force sync to ensure persistence
      await _prefs.reload();
      
      // Update streak progress only if requested
      if (updateTodayProgress) {
        final streakService = StreakService();
        await streakService.updateLearnedProgress(newLearned.length);
      }
    }
  }

  // Check if a character is learned
  Future<bool> isCharacterLearned(String character) async {
    await initialize();
    
    // Check cache first if available
    if (_cachedLearnedCharacters != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inSeconds < 30) {
      return _cachedLearnedCharacters!.contains(character);
    }
    
    final learned = await getLearnedCharacters();
    return learned.contains(character);
  }

  // Clear the cache to force fresh data
  void clearCache() {
    _cachedLearnedCharacters = null;
    _cachedLearnedWords = null;
    _lastCacheUpdate = null;
  }

  // Get all learned characters
  Future<List<String>> getLearnedCharacters() async {
    await initialize();
    
    // Always reload from SharedPreferences to ensure fresh data
    await _prefs.reload();
    
    // Load from storage
    final list = _prefs.getStringList('learned_characters') ?? [];
    _cachedLearnedCharacters = list.toSet();
    _lastCacheUpdate = DateTime.now();
    return list;
  }

  // Get learned characters for a specific set
  Future<List<String>> getLearnedCharactersForSet(List<String> setCharacters) async {
    await initialize();
    final allLearnedCharacters = await getLearnedCharacters();
    final allLearnedWords = await getLearnedWords();
    return setCharacters.where((item) => 
      _isItemLearned(item, allLearnedCharacters, allLearnedWords)
    ).toList();
  }

  // Check if a set is fully learned
  Future<bool> isSetFullyLearned(List<String> setCharacters) async {
    await initialize();
    final allLearnedCharacters = await getLearnedCharacters();
    final allLearnedWords = await getLearnedWords();
    return setCharacters.every((item) => 
      _isItemLearned(item, allLearnedCharacters, allLearnedWords)
    );
  }

  // Get learning progress for a set
  Future<double> getSetProgress(List<String> setCharacters) async {
    if (setCharacters.isEmpty) return 0.0;
    
    await initialize();
    final allLearnedCharacters = await getLearnedCharacters();
    final allLearnedWords = await getLearnedWords();
    
    // Check both characters and words
    final learnedCount = setCharacters.where((item) => 
      _isItemLearned(item, allLearnedCharacters, allLearnedWords)
    ).length;
    
    return learnedCount / setCharacters.length;
  }

  // Mark a set as learned (all characters in the set)
  Future<void> markSetAsLearned(String setId, List<String> items) async {
    await initialize();
    
    // Separate characters and words
    final singleCharacters = <String>[];
    final multiCharacterWords = <String>[];
    
    for (final item in items) {
      if (item.length == 1) {
        singleCharacters.add(item);
      } else {
        multiCharacterWords.add(item);
      }
    }
    
    // Mark all single characters as learned
    if (singleCharacters.isNotEmpty) {
      await markCharactersAsLearned(singleCharacters);
    }
    
    // Mark all multi-character words as learned
    if (multiCharacterWords.isNotEmpty) {
      await markWordsAsLearned(multiCharacterWords);
    }
    
    // Track the set learning completion
    final learnedSets = _prefs.getStringList('learned_sets') ?? [];
    if (!learnedSets.contains(setId)) {
      learnedSets.add(setId);
      await _prefs.setStringList('learned_sets', learnedSets);
      
      // Save timestamp
      final key = 'learned_set_$setId';
      await _prefs.setString(key, DateTime.now().toIso8601String());
    }
  }

  // Check if a set has been marked as learned
  Future<bool> isSetMarkedAsLearned(String setId) async {
    await initialize();
    final learnedSets = _prefs.getStringList('learned_sets') ?? [];
    return learnedSets.contains(setId);
  }

  // Get when a character was learned
  Future<DateTime?> getCharacterLearnedDate(String character) async {
    await initialize();
    final key = 'learned_character_$character';
    final dateStr = _prefs.getString(key);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }
  
  // Remove a character from learned list
  Future<void> removeLearnedCharacter(String character) async {
    await initialize();
    
    // Clear cache to force fresh read
    clearCache();
    
    final learned = await getLearnedCharacters();
    if (learned.contains(character)) {
      learned.remove(character);
      await _prefs.setStringList('learned_characters', learned);
      
      // Update cache with new data
      _cachedLearnedCharacters = learned.toSet();
      _lastCacheUpdate = DateTime.now();
      
      // Remove the timestamp key
      final key = 'learned_character_$character';
      await _prefs.remove(key);
      
      // Force sync to ensure persistence
      await _prefs.reload();
    }
  }

  // Remove a word from learned list
  Future<void> removeLearnedWord(String word) async {
    await initialize();
    
    // Clear cache to force fresh read
    clearCache();
    
    final learned = await getLearnedWords();
    if (learned.contains(word)) {
      learned.remove(word);
      await _prefs.setStringList('learned_words', learned);
      
      // Update cache with new data
      _cachedLearnedWords = learned.toSet();
      _lastCacheUpdate = DateTime.now();
      
      // Remove the timestamp key
      final key = 'learned_word_$word';
      await _prefs.remove(key);
      
      // Force sync to ensure persistence
      await _prefs.reload();
    }
  }

  // Mark a word as learned
  Future<void> markWordAsLearned(String word, {bool updateTodayProgress = true}) async {
    await initialize();
    final learned = await getLearnedWords();
    if (!learned.contains(word)) {
      learned.add(word);
      await _prefs.setStringList('learned_words', learned);
      
      // Update the timestamp
      final key = 'learned_word_$word';
      await _prefs.setString(key, DateTime.now().toIso8601String());
      
      // Force sync to ensure persistence
      await _prefs.reload();
      
      // Update streak progress only if requested
      if (updateTodayProgress) {
        final streakService = StreakService();
        await streakService.updateLearnedProgress(1);
        
        // Refresh UI if possible
        try {
          main.refreshStreakDisplay();
        } catch (_) {
          // Ignore if main screen is not available
        }
      }
      
      // Log for debugging
      // Marked word as learned
    } else {
      // Word already learned
      // Force save anyway in case there was a sync issue
      await _prefs.setStringList('learned_words', learned);
      await _prefs.reload();
      // Force saved learned words list
    }
  }

  // Mark multiple words as learned
  Future<void> markWordsAsLearned(List<String> words) async {
    await initialize();
    final learned = await getLearnedWords();
    final newLearned = <String>[];
    
    for (final word in words) {
      if (!learned.contains(word)) {
        newLearned.add(word);
        learned.add(word);
        
        // Update the timestamp
        final key = 'learned_word_$word';
        await _prefs.setString(key, DateTime.now().toIso8601String());
      }
    }
    
    if (newLearned.isNotEmpty) {
      await _prefs.setStringList('learned_words', learned);
      
      // Update streak progress with count of newly learned items
      final streakService = StreakService();
      await streakService.updateLearnedProgress(newLearned.length);
    }
  }

  // Get all learned words
  Future<List<String>> getLearnedWords() async {
    await initialize();
    return _prefs.getStringList('learned_words') ?? [];
  }

  // Check if a word is learned
  Future<bool> isWordLearned(String word) async {
    await initialize();
    final learned = await getLearnedWords();
    return learned.contains(word);
  }

  // Get when a word was learned
  Future<DateTime?> getWordLearnedDate(String word) async {
    await initialize();
    final key = 'learned_word_$word';
    final dateStr = _prefs.getString(key);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // Reset learning data (for testing or user request)
  Future<void> resetLearningData() async {
    await initialize();
    await _prefs.remove('learned_characters');
    await _prefs.remove('learned_words');
    await _prefs.remove('learned_sets');
    
    // Remove all individual timestamps
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('learned_character_') || key.startsWith('learned_word_') || key.startsWith('learned_set_')) {
        await _prefs.remove(key);
      }
    }
  }
  
  // Check if an item (character or word) is learned
  Future<bool> isItemLearned(String item) async {
    await initialize();
    final learnedCharacters = await getLearnedCharacters();
    final learnedWords = await getLearnedWords();
    return _isItemLearned(item, learnedCharacters, learnedWords);
  }
  
  // Get all unlearned items from a list
  Future<List<String>> getUnlearnedItems(List<String> items) async {
    await initialize();
    final learnedCharacters = await getLearnedCharacters();
    final learnedWords = await getLearnedWords();
    
    return items.where((item) => 
      !_isItemLearned(item, learnedCharacters, learnedWords)
    ).toList();
  }
  
  // Helper method to check if an item (character or word) is learned
  bool _isItemLearned(String item, List<String> learnedCharacters, List<String> learnedWords) {
    // If it's a single character, check if it's in learned characters
    if (item.length == 1) {
      return learnedCharacters.contains(item);
    }
    
    // If it's a multi-character word, only consider it learned if explicitly marked
    // Don't auto-mark as learned just because all characters are learned
    return learnedWords.contains(item);
  }
}