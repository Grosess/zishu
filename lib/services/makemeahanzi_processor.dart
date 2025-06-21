import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'character_stroke_service.dart';

class MakeMeAHanziProcessor {
  static final MakeMeAHanziProcessor _instance = MakeMeAHanziProcessor._internal();
  factory MakeMeAHanziProcessor() => _instance;
  MakeMeAHanziProcessor._internal();
  
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  
  // Cache for processed data
  final Map<String, CharacterStroke> _cache = {};
  
  // Path to the graphics.txt file
  String? _graphicsFilePath;
  
  // In-memory index for fast character lookup
  Map<String, int>? _characterIndex;
  
  // Initialize with graphics file path
  Future<void> initialize(String graphicsPath) async {
    _graphicsFilePath = graphicsPath;
    await _buildIndex();
  }
  
  // Build an index of character positions in the file for fast lookup
  Future<void> _buildIndex() async {
    if (_graphicsFilePath == null) return;
    
    try {
      _characterIndex = {};
      
      // For Flutter app, we'll use rootBundle if it's an asset
      if (_graphicsFilePath!.startsWith('assets/')) {
        // Load from assets
        final content = await rootBundle.loadString(_graphicsFilePath!);
        final lines = content.split('\n');
        
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          
          try {
            final json = jsonDecode(lines[i]);
            final character = json['character'] as String;
            _characterIndex![character] = i;
          } catch (e) {
            // Skip invalid lines
          }
        }
      } else {
        // Load from file system (for processing tools)
        final file = File(_graphicsFilePath!);
        if (await file.exists()) {
          final lines = await file.readAsLines();
          
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].trim().isEmpty) continue;
            
            try {
              final json = jsonDecode(lines[i]);
              final character = json['character'] as String;
              _characterIndex![character] = i;
            } catch (e) {
              // Skip invalid lines
            }
          }
        }
      }
      
      // Production: removed debug print
    } catch (e) {
      // Production: removed debug print
    }
  }
  
  // Process a list of characters and add them to the stroke service
  Future<void> processCharacters(List<String> characters) async {
    if (_graphicsFilePath == null) {
      // If no graphics file is set, try to use the default location
      await _tryDefaultPaths();
    }
    
    final processedData = <String, CharacterStroke>{};
    
    for (final character in characters) {
      // Check cache first
      if (_cache.containsKey(character)) {
        processedData[character] = _cache[character]!;
        continue;
      }
      
      // Try to load from graphics file
      final strokeData = await _loadCharacterData(character);
      if (strokeData != null) {
        _cache[character] = strokeData;
        processedData[character] = strokeData;
      }
    }
    
    // Update the stroke service with all processed data
    for (final entry in processedData.entries) {
      _strokeService.addCharacterStroke(entry.value);
    }
  }
  
  // Try default paths for graphics.txt
  Future<void> _tryDefaultPaths() async {
    final paths = [
      'assets/makemeahanzi/graphics.txt',
      'database-sample/makemeahanzi-master/makemeahanzi-master/graphics.txt',
      'assets/graphics.txt',
    ];
    
    for (final path in paths) {
      try {
        if (path.startsWith('assets/')) {
          // Check if asset exists
          try {
            await rootBundle.load(path);
            _graphicsFilePath = path;
            await _buildIndex();
            return;
          } catch (e) {
            continue;
          }
        } else {
          // Check if file exists
          final file = File(path);
          if (await file.exists()) {
            _graphicsFilePath = path;
            await _buildIndex();
            return;
          }
        }
      } catch (e) {
        continue;
      }
    }
  }
  
  // Load character data from graphics file
  Future<CharacterStroke?> _loadCharacterData(String character) async {
    if (_graphicsFilePath == null || _characterIndex == null) {
      return null;
    }
    
    // Check if character exists in index
    if (!_characterIndex!.containsKey(character)) {
      return null;
    }
    
    try {
      if (_graphicsFilePath!.startsWith('assets/')) {
        // Load from assets
        final content = await rootBundle.loadString(_graphicsFilePath!);
        final lines = content.split('\n');
        final lineIndex = _characterIndex![character]!;
        
        if (lineIndex < lines.length) {
          final json = jsonDecode(lines[lineIndex]);
          return CharacterStroke.fromJson(json);
        }
      } else {
        // Load from file system
        final file = File(_graphicsFilePath!);
        final lines = await file.readAsLines();
        final lineIndex = _characterIndex![character]!;
        
        if (lineIndex < lines.length) {
          final json = jsonDecode(lines[lineIndex]);
          return CharacterStroke.fromJson(json);
        }
      }
    } catch (e) {
      // Production: removed debug print
    }
    
    return null;
  }
  
  // Check if a character is available in the database
  Future<bool> isCharacterAvailable(String character) async {
    if (_characterIndex == null) {
      await _tryDefaultPaths();
    }
    
    return _characterIndex?.containsKey(character) ?? false;
  }
  
  // Get all available characters (for browsing)
  List<String> getAllAvailableCharacters() {
    return _characterIndex?.keys.toList() ?? [];
  }
  
  // Process characters from a raw string and save to a JSON file
  Future<void> processAndSaveCharacters(
    List<String> characters,
    String outputPath,
  ) async {
    final characterData = <Map<String, dynamic>>[];
    
    for (final character in characters) {
      final strokeData = await _loadCharacterData(character);
      if (strokeData != null) {
        characterData.add({
          'character': strokeData.character,
          'strokes': strokeData.strokes,
          'medians': strokeData.medians,
        });
      }
    }
    
    final output = {'characters': characterData};
    final file = File(outputPath);
    await file.writeAsString(jsonEncode(output));
    
    // Production: removed debug print
  }
}