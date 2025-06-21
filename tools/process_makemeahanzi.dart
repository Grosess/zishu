import 'dart:io';
import 'dart:convert';

void main() async {
  if (Platform.script.pathSegments.isEmpty) {
    print('Usage: dart process_makemeahanzi.dart');
    print('Run from the project root directory');
    return;
  }
  
  // Character list to extract (can be expanded)
  final targetCharacters = ['一', '人', '大', '小', '中', '天', '地', '山', '水', '火'];
  
  final graphicsPath = 'database-sample/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final outputPath = 'assets/character_data.json';
  
  try {
    final file = File(graphicsPath);
    if (!await file.exists()) {
      print('Error: graphics.txt not found at $graphicsPath');
      return;
    }
    
    final lines = await file.readAsLines();
    final characters = <Map<String, dynamic>>[];
    
    print('Processing ${lines.length} entries...');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      try {
        final json = jsonDecode(line);
        final character = json['character'];
        
        if (targetCharacters.contains(character)) {
          characters.add({
            'character': character,
            'strokes': json['strokes'],
            'medians': json['medians'],
          });
          print('Found character: $character');
        }
      } catch (e) {
        print('Error parsing line: $e');
      }
    }
    
    print('\nExtracted ${characters.length} characters');
    
    // Write output
    final output = {'characters': characters};
    final outputFile = File(outputPath);
    await outputFile.writeAsString(jsonEncode(output), mode: FileMode.write);
    
    print('Successfully wrote character data to $outputPath');
    
  } catch (e) {
    print('Error: $e');
  }
}