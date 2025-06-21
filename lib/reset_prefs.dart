import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clear all preferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print('Preferences cleared!');
  
  // Set default theme to system
  await prefs.setString('theme_mode', 'system');
  await prefs.setString('accent_color', 'blue');
  print('Default theme set to system mode');
  
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Preferences Reset!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Theme set to System Mode',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'You can close the app now',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    ),
  ));
}