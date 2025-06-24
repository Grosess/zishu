import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

class Size {
  final double width;
  final double height;
  Size(this.width, this.height);
}

void main() async {
  // Test how character 生 would be rendered
  print('Testing rendering of character 生...\n');
  
  // Find and load the character data
  final graphicsPath = 'database/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  final file = File(graphicsPath);
  
  if (!await file.exists()) {
    print('ERROR: Graphics file not found');
    return;
  }
  
  // Search for 生
  final lines = await file.readAsLines();
  CharacterData? shengData;
  
  for (final line in lines) {
    if (line.contains('"character":"生"')) {
      try {
        final json = jsonDecode(line);
        shengData = CharacterData.fromJson(json);
        break;
      } catch (e) {
        print('Error parsing: $e');
      }
    }
  }
  
  if (shengData == null) {
    print('Character 生 not found!');
    return;
  }
  
  print('Found character 生 with ${shengData.strokes.length} strokes\n');
  
  // Simulate rendering at different sizes
  final testSizes = [300.0, 400.0, 500.0];
  
  for (final size in testSizes) {
    print('--- Testing at size ${size}x$size ---');
    
    for (int i = 0; i < shengData.strokes.length; i++) {
      print('\nStroke ${i + 1}:');
      final svgPath = shengData.strokes[i];
      
      // Analyze the path
      analyzeStrokePath(svgPath, Size(size, size), i);
    }
  }
}

void analyzeStrokePath(String svgPath, Size targetSize, int strokeIndex) {
  // Simulate SvgPathConverter.parsePath logic
  final commands = tokenize(svgPath);
  
  print('  Total commands: ${commands.length}');
  
  // Calculate transformation parameters
  final padding = targetSize.width * 0.1;
  final drawSize = targetSize.width - (padding * 2);
  
  // Check if this is a complex character
  final closeCount = svgPath.split('Z').length - 1;
  final isComplexCharacter = closeCount > 3;
  
  final scaleFactor = isComplexCharacter ? 1.0 : 1.03;
  final scale = drawSize / 1024.0 * scaleFactor;
  
  final scaledSize = 1024 * scale;
  final offsetX = (targetSize.width - scaledSize) / 2;
  final offsetY = (targetSize.height - scaledSize) / 2 - (targetSize.height * 0.07);
  
  print('  Padding: $padding');
  print('  Scale: $scale (factor: $scaleFactor)');
  print('  Offset: ($offsetX, $offsetY)');
  print('  Is complex: $isComplexCharacter (Z count: $closeCount)');
  
  // Parse and check bounds
  double minX = double.infinity, maxX = -double.infinity;
  double minY = double.infinity, maxY = -double.infinity;
  
  for (int i = 0; i < commands.length; i++) {
    switch (commands[i]) {
      case 'M':
      case 'L':
        if (i + 2 < commands.length) {
          final x = double.tryParse(commands[i + 1]);
          final y = double.tryParse(commands[i + 2]);
          if (x != null && y != null) {
            // Apply Y-flip transformation
            final flippedY = 1024.0 - y;
            final transformedX = x * scale + offsetX;
            final transformedY = flippedY * scale + offsetY;
            
            minX = math.min(minX, transformedX);
            maxX = math.max(maxX, transformedX);
            minY = math.min(minY, transformedY);
            maxY = math.max(maxY, transformedY);
            
            if (commands[i] == 'M') {
              print('  Move to: ($x, $y) -> ($transformedX, $transformedY)');
            }
          }
          i += 2;
        }
        break;
      case 'Q':
        if (i + 4 < commands.length) {
          final x2 = double.tryParse(commands[i + 3]);
          final y2 = double.tryParse(commands[i + 4]);
          if (x2 != null && y2 != null) {
            final flippedY = 1024.0 - y2;
            final transformedX = x2 * scale + offsetX;
            final transformedY = flippedY * scale + offsetY;
            
            minX = math.min(minX, transformedX);
            maxX = math.max(maxX, transformedX);
            minY = math.min(minY, transformedY);
            maxY = math.max(maxY, transformedY);
          }
          i += 4;
        }
        break;
    }
  }
  
  print('  Bounds: ($minX, $minY) to ($maxX, $maxY)');
  print('  Width: ${maxX - minX}, Height: ${maxY - minY}');
  
  // Check if bounds exceed canvas
  if (minX < 0 || minY < 0 || maxX > targetSize.width || maxY > targetSize.height) {
    print('  WARNING: Stroke extends outside canvas!');
    print('    Out of bounds: left=${minX < 0}, top=${minY < 0}, right=${maxX > targetSize.width}, bottom=${maxY > targetSize.height}');
  }
}

List<String> tokenize(String svgPath) {
  final tokens = <String>[];
  final regex = RegExp(r'([MLHVCSQTAZ])|(-?\d*\.?\d+)');
  
  for (final match in regex.allMatches(svgPath)) {
    tokens.add(match.group(0)!);
  }
  
  return tokens;
}

class CharacterData {
  final String character;
  final List<String> strokes;
  final List<List<List<double>>> medians;
  
  CharacterData({
    required this.character,
    required this.strokes,
    required this.medians,
  });
  
  factory CharacterData.fromJson(Map<String, dynamic> json) {
    final strokesList = List<String>.from(json['strokes'] ?? []);
    final mediansList = <List<List<double>>>[];
    
    if (json['medians'] != null) {
      for (final median in json['medians']) {
        final strokeMedian = <List<double>>[];
        for (final point in median) {
          strokeMedian.add([
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble()
          ]);
        }
        mediansList.add(strokeMedian);
      }
    }
    
    return CharacterData(
      character: json['character'] ?? '',
      strokes: strokesList,
      medians: mediansList,
    );
  }
}