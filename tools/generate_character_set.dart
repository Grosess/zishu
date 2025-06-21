import 'dart:io';
import 'dart:convert';

/// Command-line tool to generate character set data from MakeMeAHanzi graphics.txt
/// 
/// Usage: dart generate_character_set.dart <character_list> [output_file]
/// Example: dart generate_character_set.dart "一二三四五" numbers.json
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart generate_character_set.dart <character_list> [output_file]');
    print('Example: dart generate_character_set.dart "一二三四五" numbers.json');
    print('\nOr provide a file with characters:');
    print('dart generate_character_set.dart @characters.txt output.json');
    return;
  }
  
  // Get characters from argument
  String characterInput = args[0];
  List<String> characters;
  
  if (characterInput.startsWith('@')) {
    // Read from file
    final fileName = characterInput.substring(1);
    final file = File(fileName);
    if (!await file.exists()) {
      print('Error: File $fileName not found');
      return;
    }
    final content = await file.readAsString();
    characters = content.split('').where((c) => c.trim().isNotEmpty && c != '\n').toList();
  } else {
    // Use direct input
    characters = characterInput.split('').where((c) => c.trim().isNotEmpty).toList();
  }
  
  // Output file
  final outputFile = args.length > 1 ? args[1] : 'character_set.json';
  
  // Path to graphics.txt
  final graphicsPath = 'database-sample/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final graphicsFile = File(graphicsPath);
  
  if (!await graphicsFile.exists()) {
    print('Error: graphics.txt not found at $graphicsPath');
    print('Please ensure MakeMeAHanzi data is available');
    return;
  }
  
  print('Processing ${characters.length} characters: ${characters.join(", ")}');
  print('Reading from: $graphicsPath');
  
  // Process graphics.txt
  final lines = await graphicsFile.readAsLines();
  final characterData = <Map<String, dynamic>>[];
  final foundCharacters = <String>{};
  final notFoundCharacters = <String>[];
  
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    
    try {
      final json = jsonDecode(line);
      final character = json['character'] as String;
      
      if (characters.contains(character)) {
        characterData.add({
          'character': character,
          'strokes': json['strokes'],
          'medians': json['medians'],
        });
        foundCharacters.add(character);
        print('✓ Found: $character');
      }
    } catch (e) {
      // Skip invalid lines
    }
  }
  
  // Check for missing characters
  for (final char in characters) {
    if (!foundCharacters.contains(char)) {
      notFoundCharacters.add(char);
      print('✗ Not found: $char');
    }
  }
  
  // Generate output
  final output = {
    'metadata': {
      'generated': DateTime.now().toIso8601String(),
      'source': 'MakeMeAHanzi',
      'requested_characters': characters,
      'found_characters': foundCharacters.toList(),
      'missing_characters': notFoundCharacters,
      'total_found': foundCharacters.length,
      'total_missing': notFoundCharacters.length,
    },
    'characters': characterData,
  };
  
  // Write output
  final file = File(outputFile);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(output));
  
  print('\nSummary:');
  print('- Characters found: ${foundCharacters.length}/${characters.length}');
  if (notFoundCharacters.isNotEmpty) {
    print('- Missing characters: ${notFoundCharacters.join(", ")}');
  }
  print('- Output written to: $outputFile');
  
  // Also generate a compact version for assets
  if (outputFile.endsWith('.json')) {
    final compactFile = outputFile.replaceAll('.json', '_compact.json');
    final compactOutput = {'characters': characterData};
    await File(compactFile).writeAsString(jsonEncode(compactOutput));
    print('- Compact version: $compactFile');
  }
}