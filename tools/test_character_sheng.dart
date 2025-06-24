import 'dart:io';
import 'dart:convert';

void main() async {
  // Test if we can find and parse the character 生
  final graphicsPath = 'database/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final file = File(graphicsPath);
  
  if (!await file.exists()) {
    print('ERROR: Graphics file not found at $graphicsPath');
    return;
  }
  
  print('Graphics file found at $graphicsPath');
  print('Searching for character 生...\n');
  
  // Read all lines and search for 生
  final lines = await file.readAsLines();
  int shengLine = -1;
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('"character":"生"')) {
      shengLine = i;
      print('Found 生 at line $i');
      break;
    }
  }
  
  if (shengLine < 0) {
    print('ERROR: Character 生 not found in database!');
    return;
  }
  
  try {
    final data = jsonDecode(lines[shengLine]);
    print('\nCharacter: ${data['character']}');
    print('Number of strokes: ${data['strokes'].length}');
    print('\nStrokes:');
    
    for (int i = 0; i < data['strokes'].length; i++) {
      print('\nStroke ${i + 1}:');
      print('  SVG Path: ${data['strokes'][i]}');
      
      // Parse the SVG path to check for Q commands
      final path = data['strokes'][i] as String;
      final hasQ = path.contains(' Q ');
      final qCount = ' Q '.allMatches(path).length;
      print('  Has Q commands: $hasQ (count: $qCount)');
      
      // Extract first few commands
      final commands = path.split(' ').take(10).join(' ');
      print('  First few commands: $commands...');
      
      if (data['medians'] != null && i < data['medians'].length) {
        print('  Median points: ${data['medians'][i].length} points');
        if (data['medians'][i].length > 0) {
          print('    First point: ${data['medians'][i][0]}');
          print('    Last point: ${data['medians'][i][data['medians'][i].length - 1]}');
        }
      }
    }
    
    // Check if this looks like placeholder data
    int totalQCount = 0;
    for (final stroke in data['strokes']) {
      if ((stroke as String).contains(' Q ')) {
        totalQCount += ' Q '.allMatches(stroke).length;
      }
    }
    
    print('\n--- Analysis ---');
    print('Total Q commands across all strokes: $totalQCount');
    if (totalQCount == 0) {
      print('WARNING: This might be placeholder data (no Q commands found)');
    }
    
    // Also check a few characters before and after
    print('\n--- Nearby characters ---');
    for (int offset = -2; offset <= 2; offset++) {
      if (offset == 0) continue;
      final idx = shengLine + offset;
      if (idx >= 0 && idx < lines.length) {
        try {
          final nearbyData = jsonDecode(lines[idx]);
          print('Line ${idx}: ${nearbyData['character']} (${nearbyData['strokes'].length} strokes)');
        } catch (e) {
          print('Line ${idx}: [Error parsing]');
        }
      }
    }
    
  } catch (e) {
    print('ERROR parsing character data: $e');
    print('Raw line content: ${lines[shengLine]}');
  }
}