import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterStatistic {
  final String character;
  int totalAttempts;
  int wrongAttempts;

  CharacterStatistic({
    required this.character,
    this.totalAttempts = 0,
    this.wrongAttempts = 0,
  });

  double get errorRate => totalAttempts > 0 ? (wrongAttempts / totalAttempts) : 0.0;
  double get errorPercentage => errorRate * 100;

  Map<String, dynamic> toJson() => {
    'character': character,
    'totalAttempts': totalAttempts,
    'wrongAttempts': wrongAttempts,
  };

  factory CharacterStatistic.fromJson(Map<String, dynamic> json) => CharacterStatistic(
    character: json['character'] as String,
    totalAttempts: json['totalAttempts'] as int,
    wrongAttempts: json['wrongAttempts'] as int,
  );
}

class CharacterStatisticsService {
  static const String _storageKey = 'character_statistics';
  final Map<String, CharacterStatistic> _statistics = {};

  // Singleton
  static final CharacterStatisticsService _instance = CharacterStatisticsService._internal();
  factory CharacterStatisticsService() => _instance;
  CharacterStatisticsService._internal();

  /// Load statistics from storage
  Future<void> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        _statistics.clear();
        for (var item in jsonList) {
          final stat = CharacterStatistic.fromJson(item as Map<String, dynamic>);
          _statistics[stat.character] = stat;
        }
      } catch (e) {
        // If there's an error, start fresh
        _statistics.clear();
      }
    }
  }

  /// Save statistics to storage
  Future<void> saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _statistics.values.map((stat) => stat.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Record a practice attempt for a character
  Future<void> recordAttempt(String character, bool isCorrect) async {
    if (!_statistics.containsKey(character)) {
      _statistics[character] = CharacterStatistic(character: character);
    }

    _statistics[character]!.totalAttempts++;
    if (!isCorrect) {
      _statistics[character]!.wrongAttempts++;
    }

    await saveStatistics();
  }

  /// Get statistics for a specific character
  CharacterStatistic? getStatistic(String character) {
    return _statistics[character];
  }

  /// Get all statistics sorted by error rate (descending)
  List<CharacterStatistic> getMostMissedCharacters({int? limit}) {
    final sortedStats = _statistics.values.toList()
      ..sort((a, b) {
        // Sort by error percentage descending, then by total attempts descending
        final errorCompare = b.errorPercentage.compareTo(a.errorPercentage);
        if (errorCompare != 0) return errorCompare;
        return b.totalAttempts.compareTo(a.totalAttempts);
      });

    // Filter: require at least 3 attempts to appear in the list
    final filtered = sortedStats.where((stat) =>
      stat.totalAttempts >= 3 && stat.wrongAttempts > 0
    ).toList();

    if (limit != null && filtered.length > limit) {
      return filtered.sublist(0, limit);
    }

    return filtered;
  }

  /// Reset statistics for a specific character
  Future<void> resetCharacter(String character) async {
    _statistics.remove(character);
    await saveStatistics();
  }

  /// Get total number of characters with statistics
  int get totalCharactersTracked => _statistics.length;

  /// Clear all statistics
  Future<void> clearAllStatistics() async {
    _statistics.clear();
    await saveStatistics();
  }
}
