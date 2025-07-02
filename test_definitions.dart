import 'package:flutter/services.dart';
import 'lib/services/cedict_service.dart';
import 'lib/utils/pinyin_utils.dart';

void main() async {
  // Initialize Flutter binding for assets
  TestWidgetsFlutterBinding.ensureInitialized();
  
  final cedict = CedictService();
  await cedict.initialize();
  
  print('CEDICT loaded with ${cedict.entryCount} entries\n');
  
  // Test characters
  final testChars = ['猫', '发烧', '啊', '马', '中国'];
  
  for (final char in testChars) {
    final entry = cedict.lookup(char);
    if (entry != null) {
      print('Character: $char');
      print('Pinyin: ${entry.pinyin}');
      print('Definition: ${entry.definition}');
      print('Formatted display: ${cedict.getFormattedDisplay(char)}');
      print('Converted pinyin: ${PinyinUtils.convertToneNumbersToMarks(entry.pinyin)}');
      print('---');
    } else {
      print('Character: $char - NOT FOUND');
      print('---');
    }
  }
}

class TestWidgetsFlutterBinding extends BindingBase with ServicesBinding {
  static void ensureInitialized() {
    TestWidgetsFlutterBinding();
  }
}