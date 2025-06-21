import 'dart:io';
import 'dart:convert';

void main() async {
  // Test if we can read the graphics file
  final graphicsPath = 'assets/database/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final file = File(graphicsPath);
  
  if (!await file.exists()) {
    print('ERROR: Graphics file not found at $graphicsPath');
    return;
  }
  
  print('Graphics file found at $graphicsPath');
  print('File size: ${await file.length()} bytes');
  
  // Read first few lines to check for 三 and 上
  final lines = await file.readAsLines();
  print('Total lines in database: ${lines.length}');
  
  int sanLine = -1;
  int shangLine = -1;
  
  for (int i = 0; i < lines.length && i < 100; i++) {
    if (lines[i].contains('"character":"三"')) {
      sanLine = i;
      print('Found 三 at line $i');
    }
    if (lines[i].contains('"character":"上"')) {
      shangLine = i;
      print('Found 上 at line $i');
    }
  }
  
  if (sanLine >= 0) {
    final data = jsonDecode(lines[sanLine]);
    print('三 data: ${data['character']} with ${data['strokes'].length} strokes');
  }
  
  if (shangLine >= 0) {
    final data = jsonDecode(lines[shangLine]);
    print('上 data: ${data['character']} with ${data['strokes'].length} strokes');
  }
}