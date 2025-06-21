import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zishu/services/cedict_service.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CEDICT Debug Tests', () {
    test('Debug CEDICT loading and parsing', () async {
      print('\n=== CEDICT Debug Test Started ===\n');
      
      // Step 1: Test asset loading
      print('Step 1: Testing asset loading...');
      try {
        final String cedictData = await rootBundle.loadString('database/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
        print('✓ Asset loaded successfully');
        print('  File size: ${cedictData.length} bytes');
        print('  First 200 chars: ${cedictData.substring(0, 200)}');
        
        // Step 2: Check for test characters in raw data
        print('\nStep 2: Checking for test characters in raw data...');
        final testChars = ['客', '气', '得'];
        for (final char in testChars) {
          final hasChar = cedictData.contains(char);
          print('  Contains "$char": $hasChar');
          if (hasChar) {
            // Find the line containing this character
            final lines = cedictData.split('\n');
            for (final line in lines) {
              if (line.contains(char) && !line.startsWith('#')) {
                print('    Found in line: ${line.substring(0, 100)}...');
                break;
              }
            }
          }
        }
        
        // Step 3: Test CEDICT service initialization
        print('\nStep 3: Testing CedictService initialization...');
        final cedictService = CedictService();
        await cedictService.initialize();
        print('✓ CedictService initialized');
        print('  Dictionary size: ${cedictService.entryCount} entries');
        print('  Is loaded: ${cedictService.isLoaded}');
        
        // Step 4: Test character lookups
        print('\nStep 4: Testing character lookups...');
        for (final char in testChars) {
          print('\n  Looking up "$char"...');
          
          // Test raw lookup
          final entry = cedictService.lookup(char);
          if (entry != null) {
            print('  ✓ Found entry:');
            print('    Simplified: ${entry.simplified}');
            print('    Traditional: ${entry.traditional}');
            print('    Pinyin: ${entry.pinyin}');
            print('    Definition: ${entry.definition}');
          } else {
            print('  ✗ No entry found');
            
            // Debug: Check character encoding
            print('    Character info:');
            print('      Length: ${char.length}');
            print('      Code units: ${char.codeUnits}');
            print('      UTF-8 bytes: ${utf8.encode(char)}');
            print('      Runes: ${char.runes.toList()}');
          }
          
          // Test helper methods
          final pinyin = cedictService.getPinyin(char);
          final definition = cedictService.getDefinition(char);
          final formatted = cedictService.getFormattedDisplay(char);
          
          print('    getPinyin(): $pinyin');
          print('    getDefinition(): $definition');
          print('    getFormattedDisplay(): $formatted');
        }
        
        // Step 5: Test multi-character lookups
        print('\nStep 5: Testing multi-character lookups...');
        final multiCharTests = ['客人', '空气', '觉得'];
        for (final word in multiCharTests) {
          print('\n  Looking up "$word"...');
          final entry = cedictService.lookup(word);
          if (entry != null) {
            print('  ✓ Found: ${entry.pinyin} - ${entry.definition}');
          } else {
            print('  ✗ Not found');
          }
        }
        
        // Step 6: Parse test - try parsing a sample line
        print('\nStep 6: Testing line parsing...');
        final sampleLines = [
          '客 客 [ke4] /customer/visitor/guest/',
          '氣 气 [qi4] /gas/air/smell/weather/to anger/to get angry/to be enraged/',
          '得 得 [de2] /to obtain/to get/to gain/to catch (a disease)/proper/suitable/proud/contented/to allow/to permit/ready/finished/',
          '得 得 [de5] /structural particle: used after a verb (or adjective as main verb), linking it to following phrase indicating effect, degree, possibility etc/',
          '得 得 [dei3] /to have to/must/ought to/to need to/',
        ];
        
        for (final line in sampleLines) {
          print('\n  Parsing: $line');
          final match = RegExp(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$').firstMatch(line);
          if (match != null) {
            print('  ✓ Parsed successfully:');
            print('    Traditional: "${match.group(1)}"');
            print('    Simplified: "${match.group(2)}"');
            print('    Pinyin: "${match.group(3)}"');
            print('    Definitions: "${match.group(4)}"');
          } else {
            print('  ✗ Failed to parse');
          }
        }
        
        print('\n=== CEDICT Debug Test Completed ===\n');
        
      } catch (e, stack) {
        print('✗ Error during test: $e');
        print('Stack trace:\n$stack');
        fail('Test failed with error: $e');
      }
    });
    
    test('Character encoding comparison', () {
      print('\n=== Character Encoding Test ===\n');
      
      // Test different ways of representing the same character
      final char1 = '客'; // Direct literal
      final char2 = String.fromCharCode(0x5BA2); // From Unicode code point
      final char3 = '\u5BA2'; // Unicode escape
      
      print('Character representations for 客:');
      print('  Direct literal: "$char1"');
      print('  From char code: "$char2"');
      print('  Unicode escape: "$char3"');
      print('  Are they equal? ${char1 == char2 && char2 == char3}');
      
      print('\nCode unit comparison:');
      print('  char1 code units: ${char1.codeUnits}');
      print('  char2 code units: ${char2.codeUnits}');
      print('  char3 code units: ${char3.codeUnits}');
      
      // Test 气
      final qi1 = '气';
      final qi2 = String.fromCharCode(0x6C14);
      final qi3 = '\u6C14';
      
      print('\nCharacter representations for 气:');
      print('  Direct literal: "$qi1"');
      print('  From char code: "$qi2"');
      print('  Unicode escape: "$qi3"');
      print('  Are they equal? ${qi1 == qi2 && qi2 == qi3}');
      
      print('\nCode unit comparison:');
      print('  qi1 code units: ${qi1.codeUnits}');
      print('  qi2 code units: ${qi2.codeUnits}');
      print('  qi3 code units: ${qi3.codeUnits}');
    });
  });
}