import 'package:flutter/material.dart';
import '../services/character_database.dart';
import '../services/character_stroke_service.dart';

class CharacterTestWidget extends StatefulWidget {
  const CharacterTestWidget({super.key});

  @override
  State<CharacterTestWidget> createState() => _CharacterTestWidgetState();
}

class _CharacterTestWidgetState extends State<CharacterTestWidget> {
  final CharacterDatabase _database = CharacterDatabase();
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  bool _isLoading = true;
  String _status = 'Initializing...';
  final Map<String, int> _testResults = {};

  @override
  void initState() {
    super.initState();
    _testCharacters();
  }

  Future<void> _testCharacters() async {
    setState(() {
      _status = 'Initializing database...';
    });
    
    await _database.initialize();
    
    final testChars = ['中', '国', '不', '见', '我', '你', '好', '人', '大', '小'];
    
    setState(() {
      _status = 'Loading test characters...';
    });
    
    await _database.loadCharacters(testChars);
    
    setState(() {
      _status = 'Testing characters...';
    });
    
    for (final char in testChars) {
      final strokeData = _strokeService.getCharacterStroke(char);
      if (strokeData != null) {
        _testResults[char] = strokeData.strokes.length;
      } else {
        _testResults[char] = -1; // Not found
      }
    }
    
    setState(() {
      _isLoading = false;
      _status = 'Test complete';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Database Test'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Character Stroke Count Test',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ..._testResults.entries.map((entry) {
                  final char = entry.key;
                  final strokeCount = entry.value;
                  final isCorrect = _isStrokeCountCorrect(char, strokeCount);
                  
                  return Card(
                    color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                    child: ListTile(
                      title: Text(
                        char,
                        style: const TextStyle(fontSize: 24),
                      ),
                      subtitle: Text(
                        strokeCount == -1
                            ? 'Not found in database'
                            : 'Strokes: $strokeCount',
                      ),
                      trailing: Icon(
                        isCorrect ? Icons.check_circle : Icons.error,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _testResults.clear();
                    });
                    _testCharacters();
                  },
                  child: const Text('Retest'),
                ),
              ],
            ),
    );
  }
  
  bool _isStrokeCountCorrect(String char, int strokeCount) {
    // Expected stroke counts for common characters
    final expected = {
      '中': 4,
      '国': 8,
      '不': 4,
      '见': 4,
      '我': 7,
      '你': 7,
      '好': 6,
      '人': 2,
      '大': 3,
      '小': 3,
    };
    
    return expected[char] == strokeCount;
  }
}