import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final String _deviceIdKey = 'device_id';
  final String _practiceDataKey = 'practice_data';
  final String _userSettingsKey = 'user_settings';
  
  String? _deviceId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get or create device ID
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  String get deviceId => _deviceId ?? '';

  // Save practice data locally
  Future<void> savePracticeData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing data
    final existingDataJson = prefs.getString(_practiceDataKey);
    final List<dynamic> practiceList = existingDataJson != null 
        ? json.decode(existingDataJson) 
        : [];
    
    // Add new data with timestamp
    data['deviceId'] = _deviceId;
    data['timestamp'] = DateTime.now().toIso8601String();
    practiceList.add(data);
    
    // Keep only last 1000 entries to prevent storage issues
    if (practiceList.length > 1000) {
      practiceList.removeRange(0, practiceList.length - 1000);
    }
    
    // Save back to storage
    await prefs.setString(_practiceDataKey, json.encode(practiceList));
  }

  // Get practice data
  Future<List<Map<String, dynamic>>> getPracticeData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_practiceDataKey);
    
    if (dataJson == null) return [];
    
    final List<dynamic> dataList = json.decode(dataJson);
    return dataList.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Get practice history for display
  Future<List<Map<String, dynamic>>> getPracticeHistory() async {
    return getPracticeData();
  }

  // Save user settings
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userSettingsKey, json.encode(settings));
  }

  // Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_userSettingsKey);
    
    if (settingsJson == null) {
      return {
        'userName': 'User',
        'email': 'user@example.com',
        'dailyGoal': 10,
        'reminderEnabled': false,
      };
    }
    
    return Map<String, dynamic>.from(json.decode(settingsJson));
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all keys
    final keys = prefs.getKeys().toList();
    
    // Remove all keys (including theme preferences)
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    // Reset the first launch flag to show tutorial again
    await prefs.setBool('has_launched_before', false);
  }

  // Export data for backup
  Future<String> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final practiceData = await getPracticeData();
    final userSettings = await getUserSettings();
    
    // Get all keys and values for comprehensive backup
    final allData = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value != null) {
        allData[key] = value;
      }
    }
    
    final exportData = {
      'version': 2,  // Updated version for new format
      'deviceId': _deviceId,
      'exportDate': DateTime.now().toIso8601String(),
      'practiceData': practiceData,
      'userSettings': userSettings,
      'allPreferences': allData,  // All SharedPreferences data
    };
    
    return json.encode(exportData);
  }

  // Import data from backup
  Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonData);
      final prefs = await SharedPreferences.getInstance();
      
      // Handle different versions
      final version = importData['version'] ?? 1;
      
      if (version == 2 && importData['allPreferences'] != null) {
        // Version 2: Import all preferences
        final allPrefs = Map<String, dynamic>.from(importData['allPreferences']);
        
        // Clear existing data first (but keep theme preferences during import)
        final currentTheme = prefs.getString('selected_theme');
        final currentAccent = prefs.getString('selected_accent_color');
        await clearAllData();
        // Restore theme preferences for import
        if (currentTheme != null) await prefs.setString('selected_theme', currentTheme);
        if (currentAccent != null) await prefs.setString('selected_accent_color', currentAccent);
        
        // Restore all preferences
        for (final entry in allPrefs.entries) {
          final key = entry.key;
          final value = entry.value;
          
          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is List) {
            await prefs.setStringList(key, List<String>.from(value));
          }
        }
      } else if (version == 1) {
        // Version 1: Legacy import
        if (importData['practiceData'] != null) {
          await prefs.setString(_practiceDataKey, json.encode(importData['practiceData']));
        }
        
        if (importData['userSettings'] != null) {
          await saveUserSettings(importData['userSettings']);
        }
      } else {
        return false;
      }
      
      return true;
    } catch (e) {
      // Production: removed debug print
      return false;
    }
  }
}