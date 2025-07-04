import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();
  
  bool _isEnabled = true;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('haptic_feedback_enabled') ?? true;
    _initialized = true;
  }
  
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback_enabled', enabled);
  }
  
  bool get isEnabled => _isEnabled;
  
  // Light impact - for taps on UI elements
  void lightImpact() {
    if (_isEnabled) {
      HapticFeedback.lightImpact();
    }
  }
  
  // Selection click - for toggles and selections
  void selectionClick() {
    if (_isEnabled) {
      HapticFeedback.selectionClick();
    }
  }
  
  // Medium impact - for important actions
  void mediumImpact() {
    if (_isEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
  
  // Heavy impact - for errors or important confirmations
  void heavyImpact() {
    if (_isEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
  
  // Ultra light - for very subtle feedback like stroke validation
  void ultraLight() {
    if (_isEnabled) {
      // selectionClick is the lightest haptic available
      HapticFeedback.selectionClick();
    }
  }
}