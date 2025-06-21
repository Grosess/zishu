import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../services/local_storage_service.dart';

class PracticeHistoryPage extends StatefulWidget {
  const PracticeHistoryPage({super.key});

  @override
  State<PracticeHistoryPage> createState() => _PracticeHistoryPageState();
}

class _PracticeHistoryPageState extends State<PracticeHistoryPage> {
  final StatisticsService _statsService = StatisticsService();
  final LocalStorageService _storageService = LocalStorageService();
  List<SetPracticeSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPracticeHistory();
  }

  Future<void> _loadPracticeHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Load practice sessions from local storage
      final sessionsData = await _storageService.getPracticeHistory();
      final sessions = <SetPracticeSession>[];
      
      // Filter for session summaries only
      for (final sessionJson in sessionsData) {
        if (sessionJson['isSessionSummary'] == true) {
          sessions.add(SetPracticeSession.fromJson(sessionJson));
        }
      }
      
      // Sort by date, most recent first
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      // Production: removed debug print
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No practice sessions yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start practicing to see your history here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final percentage = (session.successRate * 100).round();
                    final isSuccess = session.successRate >= 0.8;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: isSuccess
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: percentage == 100 ? 14 : 15,
                              fontWeight: FontWeight.bold,
                              color: isSuccess ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        title: Text(
                          session.setName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(session.timestamp),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(session.duration),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.style_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${session.totalCards} ${session.totalCards == 1 ? "card" : "cards"}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle : Icons.circle_outlined,
                              color: isSuccess ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.correctCards}/${session.totalCards}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class SetPracticeSession {
  final String setName;
  final DateTime timestamp;
  final Duration duration;
  final int totalCards;
  final int correctCards;
  final double successRate;

  SetPracticeSession({
    required this.setName,
    required this.timestamp,
    required this.duration,
    required this.totalCards,
    required this.correctCards,
    required this.successRate,
  });

  factory SetPracticeSession.fromJson(Map<String, dynamic> json) {
    return SetPracticeSession(
      setName: json['characterSet'] ?? 'Unknown Set',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      duration: Duration(seconds: json['duration'] ?? 0),
      totalCards: json['totalCards'] ?? 0,
      correctCards: json['correctCards'] ?? 0,
      successRate: (json['successRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characterSet': setName,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration.inSeconds,
      'totalCards': totalCards,
      'correctCards': correctCards,
      'successRate': successRate,
    };
  }
}