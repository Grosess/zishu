import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;
  
  // Cache for frequently accessed data
  Set<String>? _cachedLearnedCharacters;
  Set<String>? _cachedLearnedWords;
  TotalStats? _cachedTotalStats;
  DateTime? _lastCacheUpdate;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }
  
  void clearCache() {
    _cachedLearnedCharacters = null;
    _cachedLearnedWords = null;
    _cachedTotalStats = null;
    _lastCacheUpdate = null;
  }

  // Track a practice session
  Future<void> recordPracticeSession({
    required String character,
    required bool isWord,
    required bool success,
    required Duration duration,
    required int attempts,
    required bool usedHint,
  }) async {
    await initialize();
    
    final today = _getTodayKey();
    
    // Update daily statistics
    final dailyStats = await getDailyStats(today);
    dailyStats.charactersStudied++;
    if (success) {
      if (isWord) {
        dailyStats.wordsLearned++;
      } else {
        dailyStats.charactersLearned++;
      }
    }
    dailyStats.totalTime += duration;
    dailyStats.totalAttempts += attempts;
    if (usedHint) dailyStats.hintsUsed++;
    
    await _saveDailyStats(today, dailyStats);
    
    // Update total statistics
    final totalStats = await getTotalStats();
    totalStats.charactersStudied++;
    if (success) {
      if (isWord) {
        totalStats.wordsLearned++;
      } else {
        totalStats.charactersLearned++;
      }
    }
    totalStats.totalTime += duration;
    totalStats.totalAttempts += attempts;
    if (usedHint) totalStats.hintsUsed++;
    
    await _saveTotalStats(totalStats);
    
    // Update character-specific stats
    await _updateCharacterStats(character, success, attempts, duration);
    
    // Update streak
    await _updateStreak();
  }

  Future<DailyStats> getDailyStats(String? date) async {
    await initialize();
    final key = date ?? _getTodayKey();
    final json = _prefs.getString('daily_stats_$key');
    if (json == null) return DailyStats();
    return DailyStats.fromJson(jsonDecode(json));
  }

  Future<TotalStats> getTotalStats() async {
    await initialize();
    
    // Return cached data if available and recent
    if (_cachedTotalStats != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      return _cachedTotalStats!;
    }
    
    final json = _prefs.getString('total_stats');
    _cachedTotalStats = json != null ? TotalStats.fromJson(jsonDecode(json)) : TotalStats();
    _lastCacheUpdate = DateTime.now();
    return _cachedTotalStats!;
  }

  Future<int> getCurrentStreak() async {
    await initialize();
    return _prefs.getInt('current_streak') ?? 0;
  }

  Future<int> getLongestStreak() async {
    await initialize();
    return _prefs.getInt('longest_streak') ?? 0;
  }

  Future<Set<String>> getLearnedCharacters() async {
    await initialize();
    
    // Return cached data if available and recent
    if (_cachedLearnedCharacters != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      return _cachedLearnedCharacters!;
    }
    
    // Load from storage and cache
    final list = _prefs.getStringList('learned_characters') ?? [];
    _cachedLearnedCharacters = list.toSet();
    _lastCacheUpdate = DateTime.now();
    return _cachedLearnedCharacters!;
  }

  Future<Set<String>> getLearnedWords() async {
    await initialize();
    
    // Return cached data if available and recent
    if (_cachedLearnedWords != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      return _cachedLearnedWords!;
    }
    
    // Load from storage and cache
    final list = _prefs.getStringList('learned_words') ?? [];
    _cachedLearnedWords = list.toSet();
    _lastCacheUpdate = DateTime.now();
    return _cachedLearnedWords!;
  }

  // Private methods
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveDailyStats(String date, DailyStats stats) async {
    await _prefs.setString('daily_stats_$date', jsonEncode(stats.toJson()));
  }

  Future<void> _saveTotalStats(TotalStats stats) async {
    await _prefs.setString('total_stats', jsonEncode(stats.toJson()));
    // Update cache
    _cachedTotalStats = stats;
    _lastCacheUpdate = DateTime.now();
  }

  Future<void> _updateCharacterStats(String character, bool success, int attempts, Duration duration) async {
    final key = 'char_stats_$character';
    final json = _prefs.getString(key);
    final stats = json != null 
        ? CharacterStats.fromJson(jsonDecode(json))
        : CharacterStats(character: character);
    
    stats.practiceCount++;
    if (success) stats.successCount++;
    stats.totalAttempts += attempts;
    stats.totalTime += duration;
    stats.lastPracticed = DateTime.now();
    
    await _prefs.setString(key, jsonEncode(stats.toJson()));
    
    // Update learned characters list
    if (success && stats.successCount == 1) {
      final learned = await getLearnedCharacters();
      if (!learned.contains(character)) {
        learned.add(character);
        await _prefs.setStringList('learned_characters', learned.toList());
        // Update cache
        _cachedLearnedCharacters = learned;
      }
    }
  }

  Future<void> _updateStreak() async {
    final lastPractice = _prefs.getString('last_practice_date');
    final today = _getTodayKey();
    
    if (lastPractice == today) {
      // Already practiced today
      return;
    }
    
    final currentStreak = await getCurrentStreak();
    final longestStreak = await getLongestStreak();
    
    if (lastPractice == null) {
      // First practice
      await _prefs.setInt('current_streak', 1);
      await _prefs.setInt('longest_streak', 1);
    } else {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      
      if (lastPractice == yesterdayKey) {
        // Continuing streak
        final newStreak = currentStreak + 1;
        await _prefs.setInt('current_streak', newStreak);
        if (newStreak > longestStreak) {
          await _prefs.setInt('longest_streak', newStreak);
        }
      } else {
        // Streak broken
        await _prefs.setInt('current_streak', 1);
      }
    }
    
    await _prefs.setString('last_practice_date', today);
  }
}

class DailyStats {
  int charactersStudied = 0;
  int charactersLearned = 0;
  int wordsLearned = 0;
  Duration totalTime = Duration.zero;
  int totalAttempts = 0;
  int hintsUsed = 0;

  DailyStats();

  DailyStats.fromJson(Map<String, dynamic> json) {
    charactersStudied = json['charactersStudied'] ?? 0;
    charactersLearned = json['charactersLearned'] ?? 0;
    wordsLearned = json['wordsLearned'] ?? 0;
    totalTime = Duration(seconds: json['totalTimeSeconds'] ?? 0);
    totalAttempts = json['totalAttempts'] ?? 0;
    hintsUsed = json['hintsUsed'] ?? 0;
  }

  Map<String, dynamic> toJson() => {
    'charactersStudied': charactersStudied,
    'charactersLearned': charactersLearned,
    'wordsLearned': wordsLearned,
    'totalTimeSeconds': totalTime.inSeconds,
    'totalAttempts': totalAttempts,
    'hintsUsed': hintsUsed,
  };
}

class TotalStats extends DailyStats {
  TotalStats();
  TotalStats.fromJson(super.json) : super.fromJson();
}

class CharacterStats {
  final String character;
  int practiceCount = 0;
  int successCount = 0;
  int totalAttempts = 0;
  Duration totalTime = Duration.zero;
  DateTime? lastPracticed;

  CharacterStats({required this.character});

  CharacterStats.fromJson(Map<String, dynamic> json)
      : character = json['character'],
        practiceCount = json['practiceCount'] ?? 0,
        successCount = json['successCount'] ?? 0,
        totalAttempts = json['totalAttempts'] ?? 0,
        totalTime = Duration(seconds: json['totalTimeSeconds'] ?? 0),
        lastPracticed = json['lastPracticed'] != null 
            ? DateTime.parse(json['lastPracticed']) 
            : null;

  Map<String, dynamic> toJson() => {
    'character': character,
    'practiceCount': practiceCount,
    'successCount': successCount,
    'totalAttempts': totalAttempts,
    'totalTimeSeconds': totalTime.inSeconds,
    'lastPracticed': lastPracticed?.toIso8601String(),
  };
}