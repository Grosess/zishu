import 'dart:io';
import 'dart:convert';

/// Generates an index file for fast character lookup in graphics.txt
void main() async {
  final graphicsPath = 'database-sample/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final outputPath = 'assets/character_index.json';
  
  final graphicsFile = File(graphicsPath);
  
  if (!await graphicsFile.exists()) {
    print('Error: graphics.txt not found at $graphicsPath');
    return;
  }
  
  print('Building character index...');
  
  final lines = await graphicsFile.readAsLines();
  final index = <String, int>{};
  final characterList = <String>[];
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    
    try {
      final json = jsonDecode(lines[i]);
      final character = json['character'] as String;
      index[character] = i;
      characterList.add(character);
    } catch (e) {
      // Skip invalid lines
    }
  }
  
  print('Found ${index.length} characters');
  
  // Group characters by type for easier browsing
  final groups = <String, List<String>>{
    'radicals': [],
    'simple': [],
    'complex': [],
    'other': [],
  };
  
  for (final char in characterList) {
    if (char.startsWith('⺀') || char.startsWith('⺈') || char.startsWith('⺊') || 
        char.startsWith('⺌') || char.startsWith('⺍') || char.startsWith('⺗') ||
        char.startsWith('⺮') || char.startsWith('⺳') || char.startsWith('⺼')) {
      groups['radicals']!.add(char);
    } else if (char.codeUnitAt(0) >= 0x3400 && char.codeUnitAt(0) <= 0x4DBF) {
      // CJK Extension A
      groups['complex']!.add(char);
    } else if (char.codeUnitAt(0) >= 0x4E00 && char.codeUnitAt(0) <= 0x9FFF) {
      // CJK Unified Ideographs
      groups['simple']!.add(char);
    } else {
      groups['other']!.add(char);
    }
  }
  
  // Create output
  final output = {
    'metadata': {
      'generated': DateTime.now().toIso8601String(),
      'total_characters': index.length,
      'source': 'MakeMeAHanzi graphics.txt',
    },
    'index': index,
    'groups': groups,
    'all_characters': characterList,
  };
  
  // Write index file
  final indexFile = File(outputPath);
  await indexFile.writeAsString(const JsonEncoder.withIndent('  ').convert(output));
  
  print('Index written to: $outputPath');
  print('\nCharacter breakdown:');
  groups.forEach((key, value) {
    print('  $key: ${value.length} characters');
  });
  
  // Also create a compact version
  final compactOutput = {'index': index};
  final compactFile = File('assets/character_index_compact.json');
  await compactFile.writeAsString(jsonEncode(compactOutput));
  print('\nCompact index written to: assets/character_index_compact.json');
}