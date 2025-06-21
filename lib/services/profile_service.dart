import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  String _userName = '';
  String _firstName = '';
  Uint8List? _profileImageBytes;
  bool _isLoaded = false;

  String get userName => _userName;
  String get firstName => _firstName;
  Uint8List? get profileImageBytes => _profileImageBytes;
  bool get isLoaded => _isLoaded;

  Future<void> loadProfile() async {
    if (_isLoaded) return; // Already loaded
    
    final prefs = await SharedPreferences.getInstance();
    
    final fullName = prefs.getString('user_name') ?? '';
    _userName = fullName;
    _firstName = fullName.split(' ').first;
    
    // Load profile image
    final imageString = prefs.getString('user_profile_image');
    if (imageString != null) {
      try {
        _profileImageBytes = base64Decode(imageString);
      } catch (e) {
        // Production: removed debug print
      }
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, Uint8List? imageBytes}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (name != null) {
      _userName = name;
      _firstName = name.split(' ').first;
      await prefs.setString('user_name', name);
    }
    
    if (imageBytes != null) {
      _profileImageBytes = imageBytes;
      await prefs.setString('user_profile_image', base64Encode(imageBytes));
    } else if (imageBytes == null && name == null) {
      // Clear image
      _profileImageBytes = null;
      await prefs.remove('user_profile_image');
    }
    
    notifyListeners();
  }

  void clearCache() {
    _isLoaded = false;
  }
}