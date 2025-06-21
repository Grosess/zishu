import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/hanzi_character.dart';

class HanziDatabaseService {
  static final HanziDatabaseService _instance = HanziDatabaseService._internal();
  factory HanziDatabaseService() => _instance;
  HanziDatabaseService._internal();

  Database? _database;
  
  /// Filter out meanings containing "variant of" or "used in"
  List<String> _filterMeanings(List<String> meanings) {
    return meanings.where((meaning) {
      final lowerMeaning = meaning.toLowerCase();
      return !lowerMeaning.contains('variant of') && 
             !lowerMeaning.contains('used in') &&
             !lowerMeaning.contains('see also') &&
             !lowerMeaning.contains('same as');
    }).toList();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the application documents directory
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'hanzi.db');

    // Check if database exists
    final exists = await File(path).exists();

    if (!exists) {
      // Copy from assets
      ByteData data = await rootBundle.load('assets/hanzi.db');
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes);
    }

    // Open the database
    return await openDatabase(
      path,
      version: 1,
      readOnly: true,
    );
  }

  Future<HanziCharacter?> getCharacter(String character) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      where: 'character = ?',
      whereArgs: [character],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return HanziCharacter(
      character: map['character'],
      pinyin: map['pinyin'] ?? '',
      meanings: map['meanings'] != null 
          ? _filterMeanings(List<String>.from(json.decode(map['meanings'])))
          : [],
      strokeCount: map['stroke_count'] ?? 0,
      strokeOrder: map['stroke_order'] != null
          ? List<String>.from(json.decode(map['stroke_order']))
          : [],
      svgPath: map['svg_path'],
      radical: map['radical'],
      frequency: map['frequency'] ?? 0,
    );
  }

  Future<List<CharacterSet>> getCharacterSets() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query('character_sets');
    
    return List.generate(maps.length, (i) {
      return CharacterSet(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'],
        description: maps[i]['description'] ?? '',
        level: maps[i]['level'] ?? '',
        characters: List<String>.from(json.decode(maps[i]['characters'])),
      );
    });
  }

  Future<List<HanziCharacter>> getCharactersBySet(String setId) async {
    final db = await database;
    
    // First get the character set
    final List<Map<String, dynamic>> setMaps = await db.query(
      'character_sets',
      where: 'id = ?',
      whereArgs: [setId],
      limit: 1,
    );

    if (setMaps.isEmpty) return [];

    final characters = List<String>.from(json.decode(setMaps.first['characters']));
    final List<HanziCharacter> result = [];

    // Get each character
    for (final char in characters) {
      final character = await getCharacter(char);
      if (character != null) {
        result.add(character);
      }
    }

    return result;
  }

  Future<List<HanziCharacter>> searchCharacters(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      where: 'character LIKE ? OR pinyin LIKE ? OR meanings LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 20,
    );

    return maps.map((map) => HanziCharacter(
      character: map['character'],
      pinyin: map['pinyin'] ?? '',
      meanings: map['meanings'] != null 
          ? _filterMeanings(List<String>.from(json.decode(map['meanings'])))
          : [],
      strokeCount: map['stroke_count'] ?? 0,
      strokeOrder: map['stroke_order'] != null
          ? List<String>.from(json.decode(map['stroke_order']))
          : [],
      svgPath: map['svg_path'],
      radical: map['radical'],
      frequency: map['frequency'] ?? 0,
    )).toList();
  }

  Future<List<HanziCharacter>> getMostFrequent(int limit) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      orderBy: 'frequency DESC',
      limit: limit,
    );

    return maps.map((map) => HanziCharacter(
      character: map['character'],
      pinyin: map['pinyin'] ?? '',
      meanings: map['meanings'] != null 
          ? _filterMeanings(List<String>.from(json.decode(map['meanings'])))
          : [],
      strokeCount: map['stroke_count'] ?? 0,
      strokeOrder: map['stroke_order'] != null
          ? List<String>.from(json.decode(map['stroke_order']))
          : [],
      svgPath: map['svg_path'],
      radical: map['radical'],
      frequency: map['frequency'] ?? 0,
    )).toList();
  }
}