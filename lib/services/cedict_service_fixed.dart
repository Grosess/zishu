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
class CedictServiceFixed {
  static final CedictServiceFixed _instance = CedictServiceFixed._internal();
  factory CedictServiceFixed() => _instance;
  CedictServiceFixed._internal();
  
  Map<String, CedictEntry>? _dictionary;
  bool _isLoading = false;
  
  /// Initialize the dictionary by loading CEDICT data
  Future<void> initialize() async {
    if (_dictionary != null || _isLoading) return;
    
    _isLoading = true;
    // Production: removed debug print
    try {
      // Load CEDICT file from assets
      final String cedictData = await rootBundle.loadString('database/cedict_1_0_ts_utf-8_mdbg/cedict_ts.u8');
      // Production: removed debug print
      _dictionary = _parseCedict(cedictData);
      // Production: removed debug print
    } catch (e) {
      // Production: removed debug print
      // Production: removed debug print
      _dictionary = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Parse CEDICT data into a dictionary
  Map<String, CedictEntry> _parseCedict(String data) {
    final Map<String, CedictEntry> dict = {};
    final lines = data.split('\n');
    
    int parsed = 0;
    int lineNum = 0;
    
    for (final line in lines) {
      lineNum++;
      
      // Skip comments and empty lines
      if (line.startsWith('#') || line.trim().isEmpty) continue;
      
      // Debug specific lines
      if (lineNum % 10000 == 0) {
        // Production: removed debug print
      }
      
      // Parse line format: Traditional Simplified [pinyin] /definition1/definition2/
      // Fixed regex to handle edge cases better
      final trimmedLine = line.trim();
      
      // Split by spaces first to get components
      final parts = trimmedLine.split(' ');
      if (parts.length < 3) continue;
      
      final traditional = parts[0];
      final simplified = parts[1];
      
      // Find the pinyin part
      final pinyinStart = trimmedLine.indexOf('[');
      final pinyinEnd = trimmedLine.indexOf(']');
      if (pinyinStart == -1 || pinyinEnd == -1 || pinyinEnd <= pinyinStart) continue;
      
      final pinyin = trimmedLine.substring(pinyinStart + 1, pinyinEnd);
      
      // Find the definition part
      final defStart = trimmedLine.indexOf('/', pinyinEnd);
      final defEnd = trimmedLine.lastIndexOf('/');
      if (defStart == -1 || defEnd == -1 || defEnd <= defStart) continue;
      
      final definitions = trimmedLine.substring(defStart + 1, defEnd);
      
      // Clean up definition
      String cleanDef = _cleanDefinition(definitions);
      
      final entry = CedictEntry(
        simplified: simplified,
        traditional: traditional,
        pinyin: pinyin,
        definition: cleanDef,
      );
      
      // Store by simplified character
      dict[simplified] = entry;
      
      // Also store by traditional if different
      if (traditional != simplified) {
        dict[traditional] = entry;
      }
      
      parsed++;
      
      // Debug: Check if we found our test characters
      if (simplified == '客' || simplified == '气' || simplified == '得') {
        // Production: removed debug print
        // Production: removed debug print
        // Production: removed debug print
        // Production: removed debug print
        // Production: removed debug print
      }
    }
    
    // Final debug check
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Validated dictionary contents
    
    // Sample some entries
    // Production: removed debug print
    int count = 0;
    for (final key in dict.keys) {
      if (count >= 5) break;
      final e = dict[key]!;
      // Production: removed debug print
      count++;
    }
    
    return dict;
  }
  
  /// Clean up definition for display
  String _cleanDefinition(String definitions) {
    // Split by / and take first meaningful definition
    final parts = definitions.split('/').where((s) => s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '';
    
    String def = parts.first;
    
    // Remove CL: classifiers
    def = def.replaceAll(RegExp(r'CL:[^\s,;]+'), '');
    
    // Remove content in parentheses
    def = def.replaceAll(RegExp(r'\([^)]*\)'), '');
    
    // Clean up whitespace
    def = def.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // If definition is too short or empty after cleaning, try next one
    if (def.length < 3 && parts.length > 1) {
      return _cleanDefinition(parts.sublist(1).join('/'));
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
    if (entry == null) {
      // No entry found in CEDICT
    } else {
      // Production: removed debug print
    }
    return entry;
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
}