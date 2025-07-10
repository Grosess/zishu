import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zishu/services/character_database.dart';
import 'package:zishu/services/character_stroke_service.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Testing Character Loading ===');
  
  // Create instances
  final database = CharacterDatabase();
  final strokeService = CharacterStrokeService();
  
  print('\n1. Initializing database...');
  await database.initialize();
  
  print('\n2. Loading character 举...');
  await database.loadCharacters(['举']);
  
  print('\n3. Checking if character is in stroke service...');
  final stroke = strokeService.getCharacterStroke('举');
  
  if (stroke != null) {
    print('SUCCESS: Character 举 found with ${stroke.strokes.length} strokes');
  } else {
    print('FAILURE: Character 举 not found in stroke service');
  }
  
  print('\n4. Checking available characters in stroke service...');
  final available = strokeService.availableCharacters;
  print('Available characters: ${available.join(", ")}');
  
  print('\n=== Test Complete ===');
  
  // Exit
  SystemNavigator.pop();
}