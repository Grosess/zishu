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
    await prefs.remove(_practiceDataKey);
    await prefs.remove(_userSettingsKey);
  }

  // Export data for backup
  Future<String> exportData() async {
    final practiceData = await getPracticeData();
    final userSettings = await getUserSettings();
    
    final exportData = {
      'version': 1,
      'deviceId': _deviceId,
      'exportDate': DateTime.now().toIso8601String(),
      'practiceData': practiceData,
      'userSettings': userSettings,
    };
    
    return json.encode(exportData);
  }

  // Import data from backup
  Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonData);
      
      // Validate version
      if (importData['version'] != 1) {
        return false;
      }
      
      // Import practice data
      if (importData['practiceData'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_practiceDataKey, json.encode(importData['practiceData']));
      }
      
      // Import user settings
      if (importData['userSettings'] != null) {
        await saveUserSettings(importData['userSettings']);
      }
      
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}