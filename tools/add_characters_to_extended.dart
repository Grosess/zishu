import 'dart:io';
import 'dart:convert';

/// Adds specific characters from graphics.txt to character_data_extended.json
void main() async {
  // Characters to add
  final targetCharacters = ['我', '你', '的', '好'];
  
  final graphicsPath = 'database/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final extendedDataPath = 'assets/character_data_extended.json';
  
  try {
    // Load graphics file
    final graphicsFile = File(graphicsPath);
    if (!await graphicsFile.exists()) {
      print('Error: graphics.txt not found at $graphicsPath');
      print('Trying sample database...');
      
      // Try sample database as fallback
      final samplePath = 'database-sample/makemeahanzi-master/makemeahanzi-master/graphics.txt';
      final sampleFile = File(samplePath);
      if (!await sampleFile.exists()) {
        print('Error: No database file found');
        return;
      }
    }
    
    // Load existing extended data
    final extendedFile = File(extendedDataPath);
    final extendedData = jsonDecode(await extendedFile.readAsString());
    final existingCharacters = List<Map<String, dynamic>>.from(extendedData['characters']);
    
    // Get existing character list
    final existingChars = existingCharacters.map((c) => c['character'] as String).toSet();
    print('Existing characters: ${existingChars.join(", ")}');
    
    // Read graphics file
    final lines = await graphicsFile.readAsLines();
    final newCharacters = <Map<String, dynamic>>[];
    
    print('\nSearching for target characters...');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      try {
        final json = jsonDecode(line);
        final character = json['character'] as String;
        
        if (targetCharacters.contains(character) && !existingChars.contains(character)) {
          newCharacters.add({
            'character': character,
            'strokes': json['strokes'],
            'medians': json['medians'],
          });
          print('Found character: $character');
        }
      } catch (e) {
        // Skip invalid lines
      }
    }
    
    if (newCharacters.isEmpty) {
      print('\nNo new characters found to add.');
      return;
    }
    
    print('\nAdding ${newCharacters.length} new characters');
    
    // Combine existing and new characters
    existingCharacters.addAll(newCharacters);
    
    // Sort by character code for consistency
    existingCharacters.sort((a, b) => 
      (a['character'] as String).compareTo(b['character'] as String));
    
    // Write updated data
    final output = {'characters': existingCharacters};
    await extendedFile.writeAsString(
      const JsonEncoder.withIndent('').convert(output),
      mode: FileMode.write,
    );
    
    print('Successfully updated $extendedDataPath');
    print('Total characters: ${existingCharacters.length}');
    
  } catch (e) {
    print('Error: $e');
  }
}