import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _firstLaunchKey = 'first_launch_completed';
  
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  Locale _locale = const Locale('en');
  bool _isFirstLaunch = true;
  
  Locale get locale => _locale;
  bool get isFirstLaunch => _isFirstLaunch;
  
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];
  
  Future<void> loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if this is first launch
    _isFirstLaunch = !(prefs.getBool(_firstLaunchKey) ?? false);
    
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Default to system locale if supported, otherwise English
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (supportedLocales.contains(systemLocale)) {
        _locale = systemLocale;
      } else {
        _locale = const Locale('en');
      }
    }
    notifyListeners();
  }
  
  Future<void> setLanguage(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }
  
  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
    notifyListeners();
  }
  
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return locale.languageCode;
    }
  }
}