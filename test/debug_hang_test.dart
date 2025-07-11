import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zishu/services/cedict_service.dart';
import 'package:zishu/services/character_dictionary.dart';
import 'package:zishu/services/character_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('Debug 行 character definition', () async {
    print('\n=== Debugging 行 character definition ===\n');
    
    // Initialize services
    final cedictService = CedictService();
    await cedictService.initialize();
    
    final dictionary = CharacterDictionary();
    final infoService = CharacterInfoService();
    
    // Test CEDICT lookup
    print('1. CEDICT Service lookup:');
    final cedictEntry = cedictService.lookup('行');
    if (cedictEntry != null) {
      print('   Simplified: ${cedictEntry.simplified}');
      print('   Traditional: ${cedictEntry.traditional}');
      print('   Pinyin: ${cedictEntry.pinyin}');
      print('   Definition: "${cedictEntry.definition}"');
    } else {
      print('   No CEDICT entry found');
    }
    
    // Test dictionary lookup
    print('\n2. Character Dictionary lookup:');
    final dictInfo = dictionary.getCharacterInfo('行');
    if (dictInfo != null) {
      print('   Character: ${dictInfo.character}');
      print('   Pinyin: ${dictInfo.pinyin}');
      print('   Definition: "${dictInfo.definition}"');
    } else {
      print('   No dictionary entry found');
    }
    
    // Test word info
    print('\n3. Word info lookup:');
    final wordInfo = dictionary.getWordInfo('行');
    if (wordInfo != null) {
      print('   Word: ${wordInfo.word}');
      print('   Pinyin: ${wordInfo.pinyin}');
      print('   Definition: "${wordInfo.definition}"');
    } else {
      print('   No word info found');
    }
    
    // Test character info service
    print('\n4. Character Info Service:');
    final charInfoResult = infoService.getCharacterInfo('行');
    print('   Result: "$charInfoResult"');
    
    // Search for "hang" in CEDICT raw data
    print('\n5. Searching for 行 in raw CEDICT data:');
    try {
      final String cedictData = await rootBundle.loadString('assets/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
      final lines = cedictData.split('\n');
      for (final line in lines) {
        if (line.startsWith('行 行 [')) {
          print('   Found line: $line');
        }
      }
    } catch (e) {
      print('   Error loading CEDICT data: $e');
    }
    
    // Test all pronunciations of 行
    print('\n6. Testing all pronunciations:');
    final testPinyins = ['hang2', 'xing2', 'heng2'];
    for (final pinyin in testPinyins) {
      print('\n   Testing pinyin: $pinyin');
      // Search through CEDICT manually
      final results = cedictService.search(pinyin);
      for (final result in results) {
        if (result.simplified == '行') {
          print('   Found: ${result.pinyin} - ${result.definition}');
        }
      }
    }
    
    print('\n=== End of debug test ===\n');
  });
}