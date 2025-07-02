import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zishu/services/cedict_service.dart';
import 'package:zishu/utils/pinyin_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('Check specific definition issues', () async {
    print('\n=== Checking Definition Issues ===\n');
    
    final cedictService = CedictService();
    await cedictService.initialize();
    print('CEDICT loaded with ${cedictService.entryCount} entries\n');
    
    // Test characters with issues
    final testCases = [
      {'char': '猫', 'issue': 'Check for parentheses in definition'},
      {'char': '发烧', 'issue': 'Check if defined'},
      {'char': '啊', 'issue': 'Check definition'},
      {'char': '马', 'issue': 'Check definition'},
      {'char': '中国', 'issue': 'Check pinyin capitalization'},
    ];
    
    for (final testCase in testCases) {
      final char = testCase['char']!;
      final issue = testCase['issue']!;
      
      print('Character: $char');
      print('Issue: $issue');
      
      final entry = cedictService.lookup(char);
      if (entry != null) {
        print('  Raw pinyin: ${entry.pinyin}');
        print('  Raw definition: ${entry.definition}');
        print('  Converted pinyin: ${PinyinUtils.convertToneNumbersToMarks(entry.pinyin)}');
        print('  Definition length: ${entry.definition.length}');
        
        // Check for parentheses
        if (entry.definition.contains('(') || entry.definition.contains(')')) {
          print('  WARNING: Definition contains parentheses!');
        }
        
        // Check for capitalization in pinyin
        if (entry.pinyin.contains(RegExp(r'[A-Z]'))) {
          print('  WARNING: Pinyin contains capital letters!');
        }
      } else {
        print('  NOT FOUND in CEDICT!');
      }
      
      print('---\n');
    }
    
    // Also check the raw CEDICT data for these entries
    print('\n=== Checking Raw CEDICT Data ===\n');
    final cedictData = await rootBundle.loadString('database/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
    
    for (final testCase in testCases) {
      final char = testCase['char']!;
      print('Searching for "$char" in raw data...');
      
      final lines = cedictData.split('\n');
      var found = false;
      for (final line in lines) {
        if (line.contains(' $char ') && !line.startsWith('#')) {
          print('  Found: ${line.length > 150 ? line.substring(0, 150) + '...' : line}');
          found = true;
          // Don't break - show all occurrences
        }
      }
      if (!found) {
        print('  NOT FOUND in raw data');
      }
      print('');
    }
  });
}