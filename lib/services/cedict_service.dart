import 'dart:math' as math;
import 'package:flutter/services.dart';

/// Dictionary entry with pinyin and definition from CEDICT
class CedictEntry {
  final String simplified;
  final String traditional;
  final String pinyin;
  final String definition;
  
  CedictEntry({
    required this.simplified,
    required this.traditional,
    required this.pinyin,
    required this.definition,
  });
}

/// Service for looking up definitions from CEDICT dictionary
class CedictService {
  static final CedictService _instance = CedictService._internal();
  factory CedictService() => _instance;
  CedictService._internal();
  
  Map<String, CedictEntry>? _dictionary;
  bool _isLoading = false;
  Future<void>? _loadingFuture;
  
  /// Initialize the dictionary by loading CEDICT data
  Future<void> initialize() async {
    if (_dictionary != null) return;
    
    // Return existing loading future if already loading
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }
    
    // Create new loading future
    _loadingFuture = _loadCedict();
    return _loadingFuture!;
  }
  
  Future<void> _loadCedict() async {
    _isLoading = true;
    try {
      // Load CEDICT file from assets
      final String cedictData = await rootBundle.loadString('assets/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
      
      // Parse in isolate for better performance
      _dictionary = _parseCedict(cedictData);
    } catch (e) {
      // Production: removed debug print
      _dictionary = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Parse CEDICT data into a dictionary
  Map<String, CedictEntry> _parseCedict(String data) {
    final Map<String, CedictEntry> dict = {};
    final lines = data.split(RegExp(r'\r?\n'));
    
    int parsed = 0;
    int skipped = 0;
    int failed = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Skip comments and empty lines
      if (line.startsWith('#') || line.trim().isEmpty) {
        skipped++;
        continue;
      }
      
      // Parse line format: Traditional Simplified [pinyin] /definition1/definition2/
      final match = RegExp(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$').firstMatch(line);
      if (match != null) {
        final traditional = match.group(1)!;
        final simplified = match.group(2)!;
        final pinyin = match.group(3)!;
        final definitions = match.group(4)!;
        
        // Check if this is a surname entry BEFORE cleaning
        final isSurnameEntry = definitions.toLowerCase().contains('surname');
        
        // Clean up definition - take first one and remove extra info
        String cleanDef = _cleanDefinition(definitions);
        
        final entry = CedictEntry(
          simplified: simplified,
          traditional: traditional,
          pinyin: pinyin,
          definition: cleanDef,
        );
        
        // Store by simplified character
        // Special handling for characters with multiple pronunciations
        if (simplified == '好') {
          // For 好, prefer hǎo (3rd tone) over hào (4th tone)
          if (pinyin.contains('hao3')) {
            dict[simplified] = entry;
          } else if (!dict.containsKey(simplified)) {
            dict[simplified] = entry;
          }
        } else if (simplified == '东西') {
          // For 东西, prefer dong1 xi5 (thing/stuff) over dong1 xi1 (east and west)
          if (pinyin.contains('dong1 xi5')) {
            dict[simplified] = entry;
          } else if (!dict.containsKey(simplified)) {
            dict[simplified] = entry;
          }
        } else if (!dict.containsKey(simplified)) {
          // For other characters, keep the first entry (usually most common)
          dict[simplified] = entry;
        } else {
          // Check if we should replace the existing entry
          final existingDef = dict[simplified]!.definition.toLowerCase();
          final newDef = cleanDef.toLowerCase();
          
          // Replace if:
          // 1. Existing is surname and new is not
          // 2. Existing contains "variant of", "used in", "see also", "same as" and new doesn't
          if ((!isSurnameEntry && existingDef.contains('surname')) ||
              ((existingDef.contains('variant of') || 
                existingDef.contains('used in') || 
                existingDef.contains('see also') || 
                existingDef.contains('same as')) &&
               !newDef.contains('variant of') &&
               !newDef.contains('used in') &&
               !newDef.contains('see also') &&
               !newDef.contains('same as'))) {
            dict[simplified] = entry;
          }
        }
        
        // Also store by traditional if different
        if (traditional != simplified) {
          if (traditional == '好') {
            // Same special handling for traditional form
            if (pinyin.contains('hao3')) {
              dict[traditional] = entry;
            } else if (!dict.containsKey(traditional)) {
              dict[traditional] = entry;
            }
          } else if (traditional == '東西') {
            // For 東西, prefer dong1 xi5 (thing/stuff) over dong1 xi1 (east and west)
            if (pinyin.contains('dong1 xi5')) {
              dict[traditional] = entry;
            } else if (!dict.containsKey(traditional)) {
              dict[traditional] = entry;
            }
          } else if (!dict.containsKey(traditional)) {
            dict[traditional] = entry;
          } else {
            // Apply same replacement logic for traditional
            final existingDef = dict[traditional]!.definition.toLowerCase();
            final newDef = cleanDef.toLowerCase();
            
            if ((!isSurnameEntry && existingDef.contains('surname')) ||
                ((existingDef.contains('variant of') || 
                  existingDef.contains('used in') || 
                  existingDef.contains('see also') || 
                  existingDef.contains('same as')) &&
                 !newDef.contains('variant of') &&
                 !newDef.contains('used in') &&
                 !newDef.contains('see also') &&
                 !newDef.contains('same as'))) {
              dict[traditional] = entry;
            }
          }
        }
        
        parsed++;
        if (parsed % 10000 == 0) {
          // Production: removed debug print
        }
        
        // Debug: Check if we found our test characters and phrases
        if (simplified == '客' || simplified == '气' || simplified == '得' || 
            traditional == '客' || traditional == '气' || traditional == '得' ||
            simplified == '为什么' || traditional == '為什麼' ||
            simplified == '冷' || simplified == '束' || simplified == '好' ||
            simplified == '万' || traditional == '萬') {
          // Found test entry in CEDICT
          // Found test entry in CEDICT
          // Validated simplified text
          // Production: removed debug print
          // Production: removed debug print
          // Checked surname status
          // Production: removed debug print
        }
      } else {
        // Failed to match
        failed++;
        if (failed <= 5) {
          // Failed to parse line
        }
      }
    }
    
    // Final debug check
    // Parsed CEDICT successfully
    // Final dictionary contains all entries
    
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Validated dictionary contents
    if (dict.containsKey('客')) {
      final e = dict['客']!;
      // Production: removed debug print
    }
    if (dict.containsKey('气')) {
      final e = dict['气']!;
      // Production: removed debug print
    }
    if (dict.containsKey('为什么')) {
      final e = dict['为什么']!;
      // Production: removed debug print
    }
    if (dict.containsKey('冷')) {
      final e = dict['冷']!;
      // Production: removed debug print
    }
    if (dict.containsKey('束')) {
      final e = dict['束']!;
      // Production: removed debug print
    }
    if (dict.containsKey('好')) {
      final e = dict['好']!;
      // Production: removed debug print
    }
    
    return dict;
  }
  
  /// Clean up definition for display
  String _cleanDefinition(String definitions) {
    // Split by / and take first meaningful definition
    final parts = definitions.split('/').where((s) => s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '';
    
    // Skip surname entries if there are other definitions
    String def = parts.first;
    if (parts.length > 1 && def.toLowerCase().contains('surname')) {
      // Use the second definition if the first is just a surname
      def = parts[1];
    }
    
    // Remove CL: classifiers
    def = def.replaceAll(RegExp(r'CL:[^\s,;]+'), '');
    
    // Remove content in parentheses
    def = def.replaceAll(RegExp(r'\([^)]*\)'), '');
    
    // Clean up whitespace
    def = def.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Make first letter lowercase
    if (def.isNotEmpty) {
      def = def[0].toLowerCase() + def.substring(1);
    }
    
    // If definition is too short or empty after cleaning, try next one
    if (def.length < 3 && parts.length > 1) {
      return _cleanDefinition(parts.sublist(1).join('/'));
    }
    
    // SHORTEN LONG DEFINITIONS
    // Special case for Beijing - just show "Beijing" instead of the full definition
    if (def.toLowerCase().contains('beijing municipality') || 
        def.toLowerCase().contains('capital of')) {
      return 'Beijing';
    }
    
    // For definitions with semicolons, take only the first part
    if (def.contains(';')) {
      def = def.split(';').first.trim();
    }
    
    // For definitions with "to" verbs, simplify
    if (def.startsWith('to ')) {
      // Remove "to" and take first verb only
      def = def.substring(3);
      if (def.contains(',')) {
        def = def.split(',').first.trim();
      }
      if (def.contains(';')) {
        def = def.split(';').first.trim();
      }
    }
    
    // Limit length to 20 characters for display
    if (def.length > 20) {
      // Try to cut at a word boundary
      final cutoff = def.substring(0, 20).lastIndexOf(' ');
      if (cutoff > 10) {
        def = def.substring(0, cutoff) + '...';
      } else {
        def = def.substring(0, 17) + '...';
      }
    }
    
    return def;
  }
  
  /// Look up a word in the dictionary
  CedictEntry? lookup(String word) {
    if (_dictionary == null) {
      // Production: removed debug print
      return null;
    }
    
    final entry = _dictionary![word];
    if (entry != null) {
      // Found entry in dictionary
      // Filter out definitions containing "variant of" or "used in"
      if (_shouldFilterDefinition(entry.definition)) {
        // Filtering out unhelpful definition
        // Return null to indicate no useful definition
        return null;
      }
    } else {
      // No entry found in dictionary
    }
    return entry;
  }
  
  /// Check if a definition should be filtered out
  bool _shouldFilterDefinition(String definition) {
    final lowerDef = definition.toLowerCase();
    
    // Filter out offensive terms
    if (lowerDef.contains('nigger') || lowerDef.contains('negro')) {
      return true;
    }
    
    return lowerDef.contains('variant of') || 
           lowerDef.contains('used in') ||
           lowerDef.contains('see also') ||
           lowerDef.contains('same as');
  }
  
  /// Get definition for a word (returns null if not found)
  String? getDefinition(String word) {
    final entry = lookup(word);
    return entry?.definition;
  }
  
  /// Get pinyin for a word (returns null if not found)
  String? getPinyin(String word) {
    final entry = lookup(word);
    return entry?.pinyin;
  }
  
  /// Get formatted display string with pinyin and definition
  String? getFormattedDisplay(String word) {
    final entry = lookup(word);
    if (entry == null) return null;
    
    return '${entry.pinyin} - ${entry.definition}';
  }
  
  /// Check if dictionary is loaded
  bool get isLoaded => _dictionary != null;
  
  /// Get total number of entries
  int get entryCount => _dictionary?.length ?? 0;
  
  /// Search the dictionary by pinyin or English definition
  List<CedictEntry> search(String query, {int maxResults = 100}) {
    if (_dictionary == null || query.isEmpty) return [];
    
    final results = <CedictEntry>[];
    final processedQuery = query.toLowerCase().trim();
    // Also create a version without spaces for pinyin matching
    final processedQueryNoSpaces = processedQuery.replaceAll(RegExp(r'\s+'), '');
    
    // First pass: exact matches
    for (final entry in _dictionary!.values) {
      if (results.length >= maxResults) break;
      
      // Skip entries with unhelpful definitions
      if (_shouldFilterDefinition(entry.definition)) continue;
      
      final pinyinNoTone = _removeTones(entry.pinyin).toLowerCase();
      final definitionLower = entry.definition.toLowerCase();
      
      // Exact match in pinyin (without tones and spaces)
      if (pinyinNoTone == processedQueryNoSpaces) {
        results.add(entry);
        continue;
      }
      
      // Exact word match in definition
      final definitionWords = definitionLower.split(RegExp(r'[\s,;/()]+'));
      if (definitionWords.contains(processedQuery)) {
        results.add(entry);
        continue;
      }
    }
    
    // Second pass: partial matches if not enough results
    if (results.length < 20) {
      for (final entry in _dictionary!.values) {
        if (results.length >= maxResults) break;
        if (results.contains(entry)) continue; // Skip already added
        
        // Skip entries with unhelpful definitions
        if (_shouldFilterDefinition(entry.definition)) continue;
        
        final pinyinNoTone = _removeTones(entry.pinyin).toLowerCase();
        final definitionLower = entry.definition.toLowerCase();
        
        // Partial match in pinyin or definition
        if (pinyinNoTone.contains(processedQueryNoSpaces) || 
            definitionLower.contains(processedQuery)) {
          results.add(entry);
        }
      }
    }
    
    // Sort results by relevance
    results.sort((a, b) {
      // Single characters before multi-character words
      if (a.simplified.length != b.simplified.length) {
        return a.simplified.length.compareTo(b.simplified.length);
      }
      
      // Then by pinyin
      return a.pinyin.compareTo(b.pinyin);
    });
    
    return results;
  }
  
  /// Remove tone marks from pinyin for easier searching
  String _removeTones(String pinyin) {
    return pinyin
        .replaceAll(RegExp(r'[āáǎàa]'), 'a')
        .replaceAll(RegExp(r'[ēéěèe]'), 'e')
        .replaceAll(RegExp(r'[īíǐìi]'), 'i')
        .replaceAll(RegExp(r'[ōóǒòo]'), 'o')
        .replaceAll(RegExp(r'[ūúǔùu]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜü]'), 'u')
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'\s+'), ''); // Remove all whitespace
  }
}