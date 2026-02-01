import 'makemeahanzi_processor.dart';
import 'character_stroke_service.dart';
import 'character_database.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String? source;
  final Map<String, String>? definitions; // Store OCR-imported definitions
  final int? groupSize; // Custom group size for OCR-imported sets
  
  CharacterSet({
    required this.id,
    required this.name,
    required this.characters,
    this.description,
    this.isWordSet = false,
    this.color,
    this.icon,
    this.keywords,
    this.source,
    this.definitions,
    this.groupSize,
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
    'source': source,
    'definitions': definitions,
    'groupSize': groupSize,
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
    
    // Handle definitions - could be null or a Map
    Map<String, String>? definitions;
    if (json['definitions'] != null && json['definitions'] is Map) {
      definitions = Map<String, String>.from(json['definitions']);
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
      source: json['source'],
      definitions: definitions,
      groupSize: json['groupSize'] != null ? int.tryParse(json['groupSize'].toString()) : null,
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
    String? source,
    Map<String, String>? definitions,
    int? groupSize,
  }) async {
    // Filter out phrases longer than 8 characters and remove duplicates
    final filteredCharacters = characters
        .where((item) => item.length <= 8)
        .toSet()
        .toList();
    
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final set = CharacterSet(
      id: id,
      name: name,
      characters: filteredCharacters,
      description: description,
      isWordSet: isWordSet,
      source: source,
      definitions: definitions,
      groupSize: groupSize,
    );
    
    _userSets[id] = set;
    
    // Save to local storage
    await _saveCustomSetsToStorage();
    
    return set;
  }
  
  // Update an existing custom set
  Future<CharacterSet> updateCustomSet(CharacterSet updatedSet) async {
    // Filter out phrases longer than 8 characters and remove duplicates
    final filteredCharacters = updatedSet.characters
        .where((item) => item.length <= 8)
        .toSet()
        .toList();
    
    final set = CharacterSet(
      id: updatedSet.id,
      name: updatedSet.name,
      characters: filteredCharacters,
      description: updatedSet.description,
      isWordSet: updatedSet.isWordSet,
      color: updatedSet.color,
      icon: updatedSet.icon,
      source: updatedSet.source,
      definitions: updatedSet.definitions,
      groupSize: updatedSet.groupSize,
    );
    
    _userSets[updatedSet.id] = set;
    
    // Save to local storage
    await _saveCustomSetsToStorage();
    
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
  
  // Save custom sets to SharedPreferences
  Future<void> _saveCustomSetsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customSetsJson = _userSets.values.map((set) => set.toJson()).toList();
      await prefs.setString('custom_character_sets', jsonEncode(customSetsJson));
      print('CharacterSetManager: Saved ${_userSets.length} custom sets to storage');
    } catch (e) {
      print('CharacterSetManager: Error saving custom sets: $e');
    }
  }
  
  // Load custom sets from SharedPreferences
  Future<void> _loadCustomSetsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customSetsString = prefs.getString('custom_character_sets');
      
      if (customSetsString != null) {
        final List<dynamic> customSetsJson = jsonDecode(customSetsString);
        _userSets.clear();
        
        for (final setJson in customSetsJson) {
          final set = CharacterSet.fromJson(setJson);
          _userSets[set.id] = set;
        }
        
        print('CharacterSetManager: Loaded ${_userSets.length} custom sets from storage');
      }
    } catch (e) {
      print('CharacterSetManager: Error loading custom sets: $e');
    }
  }
  
  // Get all custom sets
  List<CharacterSet> getCustomSets() {
    return _userSets.values.toList();
  }

  // Delete a custom set
  Future<void> deleteCustomSet(String setId) async {
    _userSets.remove(setId);
    await _saveCustomSetsToStorage();
  }

  // Initialize the manager and load custom sets
  Future<void> initialize() async {
    await _loadCustomSetsFromStorage();
    await loadPredefinedSets();
  }
}