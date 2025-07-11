import 'package:flutter_test/flutter_test.dart';
import 'package:zishu/services/cedict_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('Test 行 character definition display', () async {
    final cedictService = CedictService();
    await cedictService.initialize();
    
    print('\nTesting character: 行\n');
    
    // Direct lookup
    final entry = cedictService.lookup('行');
    if (entry != null) {
      print('Raw entry:');
      print('  Pinyin: ${entry.pinyin}');
      print('  Definition: "${entry.definition}"');
      
      // Check what getFormattedDisplay returns
      final formatted = cedictService.getFormattedDisplay('行');
      print('\nFormatted display: "$formatted"');
      
      // Check if definition contains "hang"
      print('\nDoes definition contain "hang"? ${entry.definition.contains("hang")}');
      print('Does definition contain comma? ${entry.definition.contains(",")}');
      
      // What would be displayed if we showed pinyin + definition?
      final hangPart = entry.pinyin.replaceAll(RegExp(r'[0-9]'), '');
      print('\nPinyin without tone: "$hangPart"');
      print('If we showed "$hangPart, ${entry.definition}" it would be: "$hangPart, ${entry.definition}"');
    }
  });
}