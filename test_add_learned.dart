import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Add some test learned characters
  final testCharacters = ['一', '二', '三', '四', '五'];
  final testWords = ['你好', '谢谢', '再见'];
  
  await prefs.setStringList('learned_characters', testCharacters);
  await prefs.setStringList('learned_words', testWords);
  
  print('Added test learned items:');
  print('Characters: $testCharacters');
  print('Words: $testWords');
  
  // Verify they were saved
  final savedChars = prefs.getStringList('learned_characters');
  final savedWords = prefs.getStringList('learned_words');
  
  print('\nVerification:');
  print('Saved characters: $savedChars');
  print('Saved words: $savedWords');
}