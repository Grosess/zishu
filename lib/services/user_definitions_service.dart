import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user-defined custom definitions that override database definitions
class UserDefinitionsService {
  static final UserDefinitionsService _instance = UserDefinitionsService._internal();
  factory UserDefinitionsService() => _instance;
  UserDefinitionsService._internal();

  static const String _storageKey = 'user_custom_definitions';

  SharedPreferences? _prefs;
  Map<String, String> _definitions = {};

  /// Initialize the service and load saved definitions
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadDefinitions();
  }

  /// Load user definitions from storage
  Future<void> _loadDefinitions() async {
    final jsonString = _prefs?.getString(_storageKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _definitions = decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        print('UserDefinitionsService: Error loading definitions: $e');
        _definitions = {};
      }
    }
  }

  /// Save user definitions to storage
  Future<void> _saveDefinitions() async {
    try {
      final jsonString = jsonEncode(_definitions);
      await _prefs?.setString(_storageKey, jsonString);
    } catch (e) {
      print('UserDefinitionsService: Error saving definitions: $e');
    }
  }

  /// Get a user-defined definition for a character/word
  /// Returns null if no user definition exists
  String? getDefinition(String character) {
    return _definitions[character];
  }

  /// Set or update a user definition for a character/word
  Future<void> setDefinition(String character, String definition) async {
    if (definition.isEmpty) {
      // If empty, remove the custom definition to fall back to database
      await removeDefinition(character);
    } else {
      _definitions[character] = definition;
      await _saveDefinitions();
    }
  }

  /// Remove a user definition (falls back to database definition)
  Future<void> removeDefinition(String character) async {
    _definitions.remove(character);
    await _saveDefinitions();
  }

  /// Get all user definitions
  Map<String, String> getAllDefinitions() {
    return Map.from(_definitions);
  }

  /// Clear all user definitions
  Future<void> clearAll() async {
    _definitions.clear();
    await _saveDefinitions();
  }

  /// Check if a character has a user-defined definition
  bool hasDefinition(String character) {
    return _definitions.containsKey(character);
  }
}
