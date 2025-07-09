import 'package:shared_preferences/shared_preferences.dart';
import 'lib/services/character_set_manager.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Load character sets to understand which items are words
  final characterSetManager = CharacterSetManager();
  await characterSetManager.loadPredefinedSets();
  final allSets = characterSetManager.getAllSets();
  
  // Get current learned data
  final learnedCharacters = prefs.getStringList('learned_characters') ?? [];
  final learnedWords = prefs.getStringList('learned_words') ?? [];
  
  print('Current state:');
  print('Learned characters: ${learnedCharacters.length}');
  print('Learned words: ${learnedWords.length}');
  
  // Build a set of all multi-character items from sets
  final multiCharItems = <String>{};
  for (final set in allSets) {
    for (final item in set.characters) {
      if (item.length > 1) {
        multiCharItems.add(item);
      }
    }
  }
  
  print('\nFound ${multiCharItems.length} multi-character items in sets');
  
  // Check which multi-character items have all their characters learned
  final newLearnedWords = <String>{...learnedWords};
  final charactersToRemove = <String>{};
  
  for (final item in multiCharItems) {
    // Check if all characters of this item are learned
    bool allCharsLearned = true;
    for (int i = 0; i < item.length; i++) {
      if (!learnedCharacters.contains(item[i])) {
        allCharsLearned = false;
        break;
      }
    }
    
    if (allCharsLearned) {
      print('Found learned word: $item');
      newLearnedWords.add(item);
      
      // Mark individual characters for removal if they're part of this word
      for (int i = 0; i < item.length; i++) {
        charactersToRemove.add(item[i]);
      }
    }
  }
  
  // Remove characters that are part of words
  final newLearnedCharacters = learnedCharacters
      .where((char) => !charactersToRemove.contains(char))
      .toList();
  
  print('\nMigration results:');
  print('New learned characters: ${newLearnedCharacters.length}');
  print('New learned words: ${newLearnedWords.length}');
  print('Characters removed: ${charactersToRemove.length}');
  
  // Save updated data
  await prefs.setStringList('learned_characters', newLearnedCharacters);
  await prefs.setStringList('learned_words', newLearnedWords.toList());
  
  print('\nMigration complete!');
  print('Sample words: ${newLearnedWords.take(10).join(", ")}');
}