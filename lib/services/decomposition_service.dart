import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/database_config.dart';

class DecompositionInfo {
  final String character;
  final String decomposition;
  final String? radical;
  final Map<String, dynamic>? etymology;
  final List<String> components;

  DecompositionInfo({
    required this.character,
    required this.decomposition,
    this.radical,
    this.etymology,
    required this.components,
  });
}

class DecompositionService {
  static final DecompositionService _instance = DecompositionService._internal();
  factory DecompositionService() => _instance;
  DecompositionService._internal();

  bool _isInitialized = false;
  Map<String, DecompositionInfo> _decompositionData = {};
  
  // IDS (Ideographic Description Sequence) characters
  static const Map<String, String> _idsDescriptions = {
    '⿰': 'left-right',
    '⿱': 'top-bottom',
    '⿲': 'left-middle-right',
    '⿳': 'top-middle-bottom',
    '⿴': 'surround',
    '⿵': 'surround-above',
    '⿶': 'surround-below',
    '⿷': 'surround-left',
    '⿸': 'surround-upper-left',
    '⿹': 'surround-upper-right',
    '⿺': 'surround-lower-left',
    '⿻': 'overlaid',
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load dictionary from MakeMeAHanzi
      final dictionaryPath = DatabaseConfig.USE_FULL_DATABASE
          ? 'database/makemeahanzi-master/makemeahanzi-master/dictionary.txt'
          : 'database-sample/makemeahanzi-master/makemeahanzi-master/dictionary.txt';
      
      // Production: removed debug print
      final content = await rootBundle.loadString(dictionaryPath);
      final lines = content.split('\n');
      
      int validEntries = 0;
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final json = jsonDecode(line);
          final character = json['character'] as String;
          final decomposition = json['decomposition'] as String?;
          
          if (decomposition != null && decomposition != '？') {
            final components = _parseDecomposition(decomposition);
            _decompositionData[character] = DecompositionInfo(
              character: character,
              decomposition: decomposition,
              radical: json['radical'] as String?,
              etymology: json['etymology'] as Map<String, dynamic>?,
              components: components,
            );
            validEntries++;
          }
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      // Production: removed debug print
      _isInitialized = true;
    } catch (e) {
      // Production: removed debug print
    }
  }

  List<String> _parseDecomposition(String decomposition) {
    final components = <String>[];
    
    // Remove IDS characters and extract components
    String remaining = decomposition;
    for (final ids in _idsDescriptions.keys) {
      remaining = remaining.replaceAll(ids, '');
    }
    
    // Extract individual characters (components)
    for (int i = 0; i < remaining.length; i++) {
      final char = remaining[i];
      if (char != '？' && char != '〾' && char.trim().isNotEmpty) {
        components.add(char);
      }
    }
    
    return components;
  }

  DecompositionInfo? getDecomposition(String character) {
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    final result = _decompositionData[character];
    // Production: removed debug print
    return result;
  }
  
  List<String> getComponents(String character) {
    final info = _decompositionData[character];
    if (info == null) return [];
    
    // Recursively get components
    final allComponents = <String>{};
    _collectComponents(character, allComponents);
    
    // Remove the character itself
    allComponents.remove(character);
    
    return allComponents.toList();
  }
  
  void _collectComponents(String character, Set<String> components) {
    final info = _decompositionData[character];
    if (info == null) return;
    
    for (final component in info.components) {
      components.add(component);
      // Recursively get sub-components
      _collectComponents(component, components);
    }
  }
  
  String? getRadical(String character) {
    return _decompositionData[character]?.radical;
  }
  
  Map<String, dynamic>? getEtymology(String character) {
    return _decompositionData[character]?.etymology;
  }

  bool get isInitialized => _isInitialized;
}