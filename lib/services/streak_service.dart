import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StreakService {
  static const String _streakKey = 'streak_data';
  static const String _dailyPracticeGoalKey = 'daily_practice_goal'; // Use same key as progress page
  static const int _defaultDailyGoal = 3; // Default 3 items per day (more reasonable default)
  
  late SharedPreferences _prefs;
  
  // Singleton pattern
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }
  
  // Get current streak data
  Future<StreakData> getStreakData() async {
    await initialize(); // Ensure prefs is initialized
    final jsonString = _prefs.getString(_streakKey);
    
    // Always get the current daily goal based on progress
    final currentDailyGoal = await getDailyGoal();
    
    if (jsonString == null) {
      return StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastPracticeDate: null,
        todayProgress: 0,
        dailyGoal: currentDailyGoal,
      );
    }
    
    final json = jsonDecode(jsonString);
    final data = StreakData.fromJson(json);
    
    // Update the daily goal to match current progress goal
    data.dailyGoal = currentDailyGoal;
    
    // Check if streak should be reset (missed a day)
    if (data.lastPracticeDate != null) {
      final lastDate = DateTime.parse(data.lastPracticeDate!);
      final today = DateTime.now();
      final difference = today.difference(lastDate).inDays;
      
      if (difference > 1) {
        // Missed more than one day, reset streak
        data.currentStreak = 0;
        data.todayProgress = 0;
        await _saveStreakData(data);
      } else if (difference == 1) {
        // It's a new day, reset today's progress
        data.todayProgress = 0;
        await _saveStreakData(data);
      }
    }
    
    return data;
  }
  
  // Update practice progress
  Future<void> updateProgress(int itemsCompleted) async {
    final data = await getStreakData();
    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    // Check if this is a new day
    final bool isNewDay = data.lastPracticeDate != todayString;
    
    // If it's a new day
    if (isNewDay) {
      // Check if yesterday's goal was met (for streak continuation)
      if (data.lastPracticeDate != null && data.todayProgress < data.dailyGoal) {
        // Yesterday's goal was not met, reset streak
        data.currentStreak = 0;
      }
      // Reset today's progress for the new day
      data.todayProgress = 0;
    }
    
    // Update progress
    data.todayProgress += itemsCompleted;
    
    // Check if daily goal is met for the first time today
    if (data.todayProgress >= data.dailyGoal && data.todayProgress - itemsCompleted < data.dailyGoal) {
      // We just crossed the goal threshold
      data.currentStreak += 1;
      if (data.currentStreak > data.longestStreak) {
        data.longestStreak = data.currentStreak;
      }
    }
    
    // Update the last practice date
    data.lastPracticeDate = todayString;
    await _saveStreakData(data);
  }
  
  // Get daily goal (calculated from progress page settings)
  Future<int> getDailyGoal() async {
    await initialize(); // Ensure prefs is initialized
    // Get the character goal and deadline
    final characterGoal = _prefs.getInt('character_goal') ?? 100;
    final deadlineString = _prefs.getString('goal_deadline');
    
    if (deadlineString != null) {
      final deadline = DateTime.parse(deadlineString);
      final today = DateTime.now();
      final daysRemaining = deadline.difference(today).inDays;
      
      if (daysRemaining > 0) {
        // Get how many characters already learned
        final totalLearned = await _getTotalLearnedCount();
        final remaining = characterGoal - totalLearned;
        
        if (remaining > 0) {
          // Calculate how many per day needed
          final perDay = (remaining / daysRemaining).ceil();
          return perDay > 0 ? perDay : 1;
        }
      }
    }
    
    // Fallback to stored daily practice goal
    return _prefs.getInt(_dailyPracticeGoalKey) ?? _defaultDailyGoal;
  }
  
  // Helper to get total learned count
  Future<int> _getTotalLearnedCount() async {
    await initialize(); // Ensure prefs is initialized
    // Count learned characters
    int count = 0;
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('learned_character_') || key.startsWith('learned_word_')) {
        count++;
      }
    }
    return count;
  }
  
  // Update progress when items are marked as learned (not practiced)
  Future<void> updateLearnedProgress(int itemsLearned) async {
    final data = await getStreakData();
    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    // Check if this is a new day
    final bool isNewDay = data.lastPracticeDate != todayString;
    
    // If it's a new day
    if (isNewDay) {
      // Check if yesterday's goal was met (for streak continuation)
      if (data.lastPracticeDate != null && data.todayProgress < data.dailyGoal) {
        // Yesterday's goal was not met, reset streak
        data.currentStreak = 0;
      }
      // Reset today's progress for the new day
      data.todayProgress = 0;
    }
    
    // Update progress with learned items
    data.todayProgress += itemsLearned;
    
    // Check if daily goal is met for the first time today
    if (data.todayProgress >= data.dailyGoal && data.todayProgress - itemsLearned < data.dailyGoal) {
      // We just crossed the goal threshold
      data.currentStreak += 1;
      if (data.currentStreak > data.longestStreak) {
        data.longestStreak = data.currentStreak;
      }
    }
    
    // Update the last practice date
    data.lastPracticeDate = todayString;
    await _saveStreakData(data);
  }
  
  // Get today's learned items count
  Future<int> getTodayLearnedCount() async {
    await initialize();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    int todayLearned = 0;
    
    // Check learned character timestamps
    final learnedCharacters = _prefs.getStringList('learned_characters') ?? [];
    for (final char in learnedCharacters) {
      final timestamp = _prefs.getString('learned_character_$char');
      if (timestamp != null) {
        final learnedDate = DateTime.parse(timestamp);
        final learnedKey = '${learnedDate.year}-${learnedDate.month.toString().padLeft(2, '0')}-${learnedDate.day.toString().padLeft(2, '0')}';
        if (learnedKey == todayKey) {
          todayLearned++;
        }
      }
    }
    
    // Check learned word timestamps
    final learnedWords = _prefs.getStringList('learned_words') ?? [];
    for (final word in learnedWords) {
      final timestamp = _prefs.getString('learned_word_$word');
      if (timestamp != null) {
        final learnedDate = DateTime.parse(timestamp);
        final learnedKey = '${learnedDate.year}-${learnedDate.month.toString().padLeft(2, '0')}-${learnedDate.day.toString().padLeft(2, '0')}';
        if (learnedKey == todayKey) {
          todayLearned++;
        }
      }
    }
    
    return todayLearned;
  }
  
  // Check if today's goal is complete
  Future<bool> isTodayGoalComplete() async {
    final data = await getStreakData();
    return data.todayProgress >= data.dailyGoal;
  }
  
  // Reset streak (for debugging/settings)
  Future<void> resetStreak() async {
    await initialize(); // Ensure prefs is initialized
    await _prefs.remove(_streakKey);
  }
  
  // Private method to save streak data
  Future<void> _saveStreakData(StreakData data) async {
    await initialize(); // Ensure prefs is initialized
    final json = jsonEncode(data.toJson());
    await _prefs.setString(_streakKey, json);
  }
}

class StreakData {
  int currentStreak;
  int longestStreak;
  String? lastPracticeDate;
  int todayProgress;
  int dailyGoal;
  
  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastPracticeDate,
    required this.todayProgress,
    required this.dailyGoal,
  });
  
  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastPracticeDate': lastPracticeDate,
    'todayProgress': todayProgress,
    'dailyGoal': dailyGoal,
  };
  
  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
    currentStreak: json['currentStreak'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
    lastPracticeDate: json['lastPracticeDate'],
    todayProgress: json['todayProgress'] ?? 0,
    dailyGoal: json['dailyGoal'] ?? 10,
  );
}