import 'dart:io';
import 'dart:convert';

/// Tool to generate common definitions from Skritter CSV and other sources
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart generate_common_definitions.dart <skritter_csv_path>');
    exit(1);
  }

  final csvPath = args[0];
  final csvFile = File(csvPath);
  
  if (!await csvFile.exists()) {
    print('Error: CSV file not found at $csvPath');
    exit(1);
  }

  print('Processing Skritter CSV...');
  final lines = await csvFile.readAsLines();
  
  final definitions = <String, CommonDefinition>{};
  
  // Skip header if present
  final startIndex = lines.isNotEmpty && lines[0].contains('simplified') ? 1 : 0;
  
  for (int i = startIndex; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    
    final parts = line.split(',');
    if (parts.length >= 4) {
      final simplified = parts[0].trim();
      final traditional = parts[1].trim();
      final pinyin = parts[2].trim();
      final definition = parts.sublist(3).join(',').trim(); // Handle commas in definitions
      
      // Keep pinyin as-is from the CSV (it's already in the correct format)
      
      definitions[simplified] = CommonDefinition(
        character: simplified,
        pinyin: pinyin,
        definition: definition,
        priority: _getPriority(simplified, i),
      );
    }
  }
  
  print('Processed ${definitions.length} entries from Skritter CSV');
  
  // Add pronunciation rules for common multi-pronunciation characters
  _addPronunciationRules(definitions);
  
  // Generate the Dart file
  final output = StringBuffer();
  output.writeln('// Generated from Skritter CSV and pronunciation rules');
  output.writeln('// Do not edit manually - regenerate using tools/generate_common_definitions.dart');
  output.writeln();
  output.writeln('class CommonDefinition {');
  output.writeln('  final String character;');
  output.writeln('  final String pinyin;');
  output.writeln('  final String definition;');
  output.writeln('  final int priority;');
  output.writeln();
  output.writeln('  const CommonDefinition({');
  output.writeln('    required this.character,');
  output.writeln('    required this.pinyin,');
  output.writeln('    required this.definition,');
  output.writeln('    this.priority = 1,');
  output.writeln('  });');
  output.writeln('}');
  output.writeln();
  output.writeln('const Map<String, CommonDefinition> commonDefinitions = {');
  
  // Sort by priority then by character
  final sortedEntries = definitions.entries.toList()
    ..sort((a, b) {
      final priorityCompare = a.value.priority.compareTo(b.value.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.key.compareTo(b.key);
    });
  
  for (final entry in sortedEntries) {
    final def = entry.value;
    output.writeln("  '${_escapeString(entry.key)}': CommonDefinition(");
    output.writeln("    character: '${_escapeString(def.character)}',");
    output.writeln("    pinyin: '${_escapeString(def.pinyin)}',");
    output.writeln("    definition: '${_escapeString(def.definition)}',");
    output.writeln("    priority: ${def.priority},");
    output.writeln("  ),");
  }
  
  output.writeln('};');
  output.writeln();
  output.writeln('/// Get the most common definition for a character/word');
  output.writeln('CommonDefinition? getCommonDefinition(String text) {');
  output.writeln('  return commonDefinitions[text];');
  output.writeln('}');
  
  // Write to file
  final outputFile = File('lib/data/common_definitions.dart');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(output.toString());
  
  print('Generated ${outputFile.path} with ${definitions.length} entries');
  
  // Also generate a summary
  _generateSummary(definitions);
}

/// Add pronunciation rules for characters not in Skritter or with multiple common uses
void _addPronunciationRules(Map<String, CommonDefinition> definitions) {
  // Common particles and their preferred pronunciations
  final particleRules = {
    '的': ['de5', '(possessive particle)'],
    '地': ['de5', '(adverb particle)'],
    '得': ['de5', '(complement particle)'],
    '着': ['zhe5', '(aspect particle)'],
    '过': ['guo5', '(experiential particle)'],
  };
  
  // Add particle pronunciations if not already defined
  particleRules.forEach((char, data) {
    if (!definitions.containsKey(char) || 
        !definitions[char]!.pinyin.contains('5')) { // Prefer neutral tone
      definitions[char] = CommonDefinition(
        character: char,
        pinyin: data[0],
        definition: data[1],
        priority: 1, // High priority for particles
      );
    }
  });
  
  print('Added ${particleRules.length} pronunciation rules');
}

/// Assign priority based on position in Skritter (earlier = more common)
int _getPriority(String character, int position) {
  // Single characters get higher priority
  if (character.length == 1) {
    return position ~/ 100 + 1; // Group by 100s
  }
  // Multi-character words
  return position ~/ 50 + 10; // Start at 10, group by 50s
}

/// Escape strings for Dart string literals
String _escapeString(String s) {
  return s
    .replaceAll('\\', '\\\\')
    .replaceAll("'", "\\'")
    .replaceAll('\n', '\\n')
    .replaceAll('\r', '\\r')
    .replaceAll('\t', '\\t');
}

/// Generate a summary report
void _generateSummary(Map<String, CommonDefinition> definitions) {
  final singleChars = definitions.values.where((d) => d.character.length == 1).length;
  final multiChars = definitions.values.where((d) => d.character.length > 1).length;
  
  print('\nSummary:');
  print('- Single characters: $singleChars');
  print('- Multi-character words: $multiChars');
  print('- Total entries: ${definitions.length}');
  
  // Find characters with neutral tones (likely particles)
  final neutralTones = definitions.values
    .where((d) => d.pinyin.contains('5'))
    .map((d) => d.character)
    .toList();
  
  if (neutralTones.isNotEmpty) {
    print('- Neutral tone entries: ${neutralTones.length}');
    print('  Examples: ${neutralTones.take(10).join(', ')}');
  }
}

class CommonDefinition {
  final String character;
  final String pinyin;
  final String definition;
  final int priority;

  CommonDefinition({
    required this.character,
    required this.pinyin,
    required this.definition,
    this.priority = 1,
  });
}