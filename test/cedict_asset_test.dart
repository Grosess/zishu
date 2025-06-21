import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zishu/services/cedict_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CEDICT Asset Tests', () {
    test('CEDICT asset can be loaded', () async {
      try {
        final String cedictData = await rootBundle.loadString('database/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
        print('CEDICT loaded successfully: ${cedictData.length} bytes');
        expect(cedictData.length, greaterThan(0));
      } catch (e) {
        fail('Failed to load CEDICT asset: $e');
      }
    });
    
    test('CEDICT service initializes and finds characters', () async {
      final cedict = CedictService();
      
      // Initialize
      await cedict.initialize();
      expect(cedict.isLoaded, true);
      expect(cedict.entryCount, greaterThan(0));
      print('CEDICT initialized with ${cedict.entryCount} entries');
      
      // Test lookups
      final testChars = ['客', '气', '氣', '你', '好'];
      for (final char in testChars) {
        final entry = cedict.lookup(char);
        print('Lookup $char: ${entry != null ? "Found - ${entry.pinyin}" : "NOT FOUND"}');
        expect(entry, isNotNull, reason: 'Character $char should be found');
      }
    });
  });
}