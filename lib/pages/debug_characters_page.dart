import 'package:flutter/material.dart';
import 'writing_practice_page.dart';
import '../services/character_stroke_service.dart';
import '../services/cedict_service.dart';
import '../services/character_database.dart';

class DebugCharactersPage extends StatefulWidget {
  const DebugCharactersPage({super.key});

  @override
  State<DebugCharactersPage> createState() => _DebugCharactersPageState();
}

class _DebugCharactersPageState extends State<DebugCharactersPage> {
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  final CedictService _cedictService = CedictService();
  bool _isLoading = true;

  static final List<String> debugCharacters = [
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
    '下', '上', '国', '中', '大', '小', '人', '日', '月', '年',
    '时', '分', '今', '天', '明', '昨', '后', '前', '左', '右',
    '东', '西', '南', '北', '男', '女', '子', '好', '很', '不',
    '是', '有', '在', '这', '那', '什', '么', '谁', '的', '了',
    '吗', '呢', '吧', '啊', '和', '与', '或', '但', '因', '为',
    '所', '以', '如', '果', '要', '就', '会', '能', '可', '应',
    '该', '必', '须', '得', '把', '被', '让', '给', '跟', '对',
    '向', '从', '到', '过', '去', '来', '回', '出', '进', '起',
    '走', '跑', '飞', '跳', '看', '见', '听', '说', '话', '读',
    '写', '画', '唱', '跳', '舞', '玩', '打', '踢', '拍', '抓',
    '学', '习', '教', '书', '本', '笔', '纸', '包', '桌', '椅',
    '门', '窗', '墙', '地', '天', '空', '云', '雨', '雪', '风',
    '水', '火', '土', '木', '金', '石', '山', '河', '海', '湖',
    '草', '花', '树', '林', '鸟', '鱼', '虫', '兽', '狗', '猫',
    '牛', '马', '羊', '鸡', '鸭', '猪', '虎', '龙', '蛇', '兔'
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Load sample data first
    await _strokeService.loadSampleData();
    
    // Then load from the database for all debug characters
    final database = CharacterDatabase();
    await database.initialize();
    
    // Load all debug characters at once
    await database.loadCharacters(debugCharacters);
    
    await _cedictService.initialize();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPinyin(String character) {
    // Simple lookup - CEDICT should already have the most common pronunciation first
    final entry = _cedictService.lookup(character);
    if (entry != null) {
      // Special cases for very common particles that might have wrong primary entry
      if (character == '了' && !entry.pinyin.contains('le')) {
        return 'le5'; // Completed action marker
      }
      if (character == '着' && !entry.pinyin.contains('zhe')) {
        return 'zhe5'; // Continuous aspect marker
      }
      if (character == '的' && !entry.pinyin.contains('de')) {
        return 'de5'; // Possessive particle
      }
      if (character == '地' && entry.pinyin.contains('de')) {
        return 'di4'; // "ground/place" is more common than adverb marker
      }
      if (character == '得') {
        // Could be de2 (obtain), de5 (structural particle), or dei3 (must)
        return 'de2'; // "obtain" is a good default
      }
      if (character == '么' && entry.pinyin.contains('yao1')) {
        return 'me5'; // Question particle is more common
      }
      
      return entry.pinyin;
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Characters'),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: debugCharacters.length,
              itemBuilder: (context, index) {
                final character = debugCharacters[index];
                final strokeData = _strokeService.getCharacterStroke(character);
                final pinyin = _getPinyin(character);
                
                return Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WritingPracticePage(
                            character: character,
                            characterSet: 'Debug',
                            allCharacters: [character],
                            isWord: false,
                            mode: PracticeMode.learning,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pinyin
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            pinyin,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Character comparison
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Font rendering
                            Column(
                              children: [
                                Text(
                                  character,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const Text(
                                  'Font',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            // SVG rendering
                            Column(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: strokeData != null
                                      ? CustomPaint(
                                          painter: SimpleStrokePainter(
                                            strokes: strokeData.strokes,
                                          ),
                                        )
                                      : Container(
                                          color: Colors.red.withOpacity(0.2),
                                          child: const Center(
                                            child: Text(
                                              '!',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ),
                                ),
                                const Text(
                                  'SVG',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
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

// Simple painter to show all strokes
class SimpleStrokePainter extends CustomPainter {
  final List<String> strokes;

  SimpleStrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final strokeSvg in strokes) {
      final path = SvgPathConverter.parsePath(strokeSvg, size);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}