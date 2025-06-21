import 'dart:io';
import 'dart:convert';

/// Combines multiple character set JSON files into a master database
void main() async {
  final setsDir = Directory('assets/character_sets');
  
  if (!await setsDir.exists()) {
    print('Error: assets/character_sets directory not found');
    return;
  }
  
  final allCharacters = <String, Map<String, dynamic>>{};
  final setMetadata = <Map<String, dynamic>>[];
  
  // Read all JSON files in the directory
  await for (final file in setsDir.list()) {
    if (file is File && file.path.endsWith('.json') && !file.path.endsWith('_compact.json')) {
      print('Processing ${file.path}...');
      
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        
        if (data['characters'] != null) {
          // Extract set name from filename
          final setName = file.path.split('/').last.replaceAll('.json', '');
          
          // Add metadata
          if (data['metadata'] != null) {
            setMetadata.add({
              'name': setName,
              'total_characters': data['metadata']['total_found'],
              'missing_characters': data['metadata']['missing_characters'],
            });
          }
          
          // Add characters to master list
          for (final charData in data['characters']) {
            final character = charData['character'];
            allCharacters[character] = charData;
          }
        }
      } catch (e) {
        print('Error processing ${file.path}: $e');
      }
    }
  }
  
  print('\nTotal unique characters: ${allCharacters.length}');
  
  // Create master database
  final masterDb = {
    'metadata': {
      'generated': DateTime.now().toIso8601String(),
      'total_characters': allCharacters.length,
      'sets': setMetadata,
    },
    'characters': allCharacters.values.toList(),
  };
  
  // Write master database
  final masterFile = File('assets/character_database.json');
  await masterFile.writeAsString(const JsonEncoder.withIndent('  ').convert(masterDb));
  print('Master database written to: assets/character_database.json');
  
  // Create compact version
  final compactDb = {'characters': allCharacters.values.toList()};
  final compactFile = File('assets/character_database_compact.json');
  await compactFile.writeAsString(jsonEncode(compactDb));
  print('Compact database written to: assets/character_database_compact.json');
  
  // Create character index
  final index = allCharacters.keys.toList()..sort();
  final indexFile = File('assets/character_index.json');
  await indexFile.writeAsString(jsonEncode({'characters': index}));
  print('Character index written to: assets/character_index.json');
}