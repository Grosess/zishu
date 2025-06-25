import 'dart:io';
import 'package:flutter/services.dart';
import 'lib/services/cedict_service.dart';

// Mock rootBundle for testing
class MockAssetBundle extends AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.contains('cedict_ts.u8')) {
      // Read the actual CEDICT file
      final file = File('assets/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
      return await file.readAsString();
    }
    throw FlutterError('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}

Future<void> main() async {
  // Set up mock
  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      final String key = String.fromCharCodes(message!.buffer.asUint8List());
      try {
        final bundle = MockAssetBundle();
        final data = await bundle.loadString(key);
        final bytes = Uint8List.fromList(data.codeUnits);
        return ByteData.view(bytes.buffer);
      } catch (e) {
        return null;
      }
    },
  );

  // Initialize service
  final cedictService = CedictService();
  print('Initializing CEDICT service...');
  await cedictService.initialize();
  print('CEDICT loaded with ${cedictService.entryCount} entries');
  
  // Test searches
  final testQueries = ['toilet', 'restaurant', 'africa', 'singapore'];
  
  for (final query in testQueries) {
    print('\nSearching for "$query":');
    final results = cedictService.search(query);
    
    if (results.isEmpty) {
      print('  No results found');
    } else {
      print('  Found ${results.length} results:');
      for (int i = 0; i < results.length && i < 5; i++) {
        final entry = results[i];
        print('    ${entry.simplified} (${entry.pinyin}) - ${entry.definition}');
      }
      if (results.length > 5) {
        print('    ... and ${results.length - 5} more');
      }
    }
  }
  
  // Also test Chinese input
  print('\nTesting Chinese character search:');
  final chineseResults = cedictService.search('厕');
  for (final entry in chineseResults) {
    print('  ${entry.simplified} (${entry.pinyin}) - ${entry.definition}');
  }
}