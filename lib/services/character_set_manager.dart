import 'makemeahanzi_processor.dart';
import 'character_stroke_service.dart';
import 'character_database.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class CharacterSet {
  final String id;
  final String name;
  final List<String> characters;
  final String? description;
  final bool isWordSet;
  final int? color;
  final String? icon;
  final String? keywords;
  
  CharacterSet({
    required this.id,
    required this.name,
    required this.characters,
    this.description,
    this.isWordSet = false,
    this.color,
    this.icon,
    this.keywords,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'characters': characters,
    'description': description,
    'isWordSet': isWordSet,
    'color': color,
    'icon': icon,
    'keywords': keywords,
  };
  
  factory CharacterSet.fromJson(Map<String, dynamic> json) {
    // Handle characters - could be a String (comma-separated) or List
    List<String> characters;
    if (json['characters'] is String) {
      final isWordSet = json['isWordSet'] ?? false;
      if (isWordSet) {
        characters = json['characters'].split(',').map((s) => s.trim()).toList();
      } else {
        characters = json['characters'].split('').toList();
      }
    } else if (json['characters'] is List) {
      characters = List<String>.from(json['characters']);
    } else {
      characters = [];
    }
    
    return CharacterSet(
      id: json['id'],
      name: json['name'],
      characters: characters,
      description: json['description'],
      isWordSet: json['isWordSet'] ?? false,
      color: json['color'] != null ? int.tryParse(json['color'].toString()) : null,
      icon: json['icon'],
      keywords: json['keywords'],
    );
  }
}

class CharacterSetManager {
  static final CharacterSetManager _instance = CharacterSetManager._internal();
  factory CharacterSetManager() => _instance;
  CharacterSetManager._internal();
  
  final MakeMeAHanziProcessor _processor = MakeMeAHanziProcessor();
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  
  // Predefined character sets - now loaded from JSON
  final Map<String, CharacterSet> _predefinedSets = {};
  
  // User-created sets stored locally
  final Map<String, CharacterSet> _userSets = {};
  
  bool _predefinedSetsLoaded = false;
  
  // Load predefined sets from JSON
  Future<void> loadPredefinedSets() async {
    if (_predefinedSetsLoaded) {
      print('CharacterSetManager: Predefined sets already loaded, found ${_predefinedSets.length} sets');
      return;
    }
    
    print('CharacterSetManager: Loading predefined sets from JSON...');
    try {
      final String jsonString = await rootBundle.loadString('assets/character_sets_full.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> setsData = jsonData['sets'] ?? [];
      
      print('CharacterSetManager: Found ${setsData.length} sets in JSON');
      
      for (final setData in setsData) {
        if (setData['characters'] != null) {
          final String charactersStr = setData['characters'] as String;
          final bool isWordSet = setData['isWordSet'] ?? false;
          
          List<String> characters;
          if (isWordSet) {
            characters = charactersStr.split(',').map((s) => s.trim()).toList();
          } else {
            characters = charactersStr.split('').toList();
          }
          
          final set = CharacterSet(
            id: setData['id'],
            name: setData['name'],
            characters: characters,
            description: setData['description'],
            isWordSet: isWordSet,
            icon: setData['icon'],
          );
          
          _predefinedSets[set.id] = set;
        }
      }
      
      _predefinedSetsLoaded = true;
      print('CharacterSetManager: Successfully loaded ${_predefinedSets.length} predefined sets');
    } catch (e) {
      print('CharacterSetManager: Error loading predefined sets: $e');
      // Error loading predefined sets
    }
  }
  
  // Get all available sets
  List<CharacterSet> getAllSets() {
    return [..._predefinedSets.values, ..._userSets.values];
  }
  
  // Get a specific set by ID
  CharacterSet? getSet(String id) {
    return _predefinedSets[id] ?? _userSets[id];
  }
  
  // Load characters for a set from MakeMeAHanzi database
  Future<bool> loadCharacterSet(String setId) async {
    final set = getSet(setId);
    if (set == null) return false;
    
    try {
      // Use the more efficient database loading for better performance
      final database = CharacterDatabase();
      await database.initialize();
      await database.loadCharacters(set.characters);
      
      return true;
    } catch (e) {
      // Production: removed debug print
      return false;
    }
  }
  
  // Preload multiple character sets efficiently
  Future<void> preloadCharacterSets(List<String> setIds) async {
    final allCharacters = <String>{};
    
    for (final setId in setIds) {
      final set = getSet(setId);
      if (set != null) {
        allCharacters.addAll(set.characters);
      }
    }
    
    if (allCharacters.isNotEmpty) {
      final database = CharacterDatabase();
      await database.initialize();
      await database.loadCharacters(allCharacters.toList());
    }
  }
  
  // Create a custom character set
  Future<CharacterSet> createCustomSet({
    required String name,
    required List<String> characters,
    String? description,
    bool isWordSet = false,
  }) async {
    // Filter out phrases longer than 8 characters
    final filteredCharacters = characters.where((item) => item.length <= 8).toList();
    
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final set = CharacterSet(
      id: id,
      name: name,
      characters: filteredCharacters,
      description: description,
      isWordSet: isWordSet,
    );
    
    _userSets[id] = set;
    
    // TODO: Save to local storage
    
    return set;
  }
  
  // Load a character set from a string (e.g., "一二三四五" or "我,你,出生,的")
  Future<CharacterSet> createSetFromString(String input, String name) async {
    // Replace Chinese comma with English comma for consistent parsing
    String processedInput = input.replaceAll('，', ',');
    
    // Remove English letters (a-z, A-Z) and keep only Chinese characters and punctuation
    processedInput = processedInput.replaceAll(RegExp(r'[a-zA-Z]'), '');
    
    List<String> items;
    bool isWordSet = false;
    
    // Check if input contains commas
    if (processedInput.contains(',')) {
      // Split by comma and trim each item, filter out items longer than 8 characters
      items = processedInput.split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item.length <= 8)
          .toList();
      isWordSet = true;
    } else {
      // Split into individual characters
      items = processedInput.split('').where((c) => c.trim().isNotEmpty).toList();
    }
    
    // Check if any valid items remain after filtering
    if (items.isEmpty) {
      throw Exception('Sorry, all terms were over 8 characters. Please use terms under 9 characters.');
    }
    
    return createCustomSet(
      name: name,
      characters: items,
      description: 'Created from: $input',
      isWordSet: isWordSet,
    );
  }
  
  // Check if all characters in a set are available
  Future<Map<String, bool>> checkCharacterAvailability(String setId) async {
    final set = getSet(setId);
    if (set == null) return {};
    
    final availability = <String, bool>{};
    for (final char in set.characters) {
      availability[char] = await _processor.isCharacterAvailable(char);
    }
    
    return availability;
  }
}