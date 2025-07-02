import 'character_database.dart';
import 'character_dictionary.dart';
import 'character_info_service.dart';

class CharacterValidator {
  static final CharacterValidator _instance = CharacterValidator._internal();
  factory CharacterValidator() => _instance;
  CharacterValidator._internal();
  
  final CharacterDatabase _database = CharacterDatabase();
  final CharacterDictionary _dictionary = CharacterDictionary();
  final CharacterInfoService _infoService = CharacterInfoService();
  
  /// Validate a single item (character or word)
  Future<ValidationResult> validateItem(String item) async {
    if (item.isEmpty) {
      return ValidationResult(
        isValid: false,
        item: item,
        invalidCharacters: [],
        message: 'Item cannot be empty',
      );
    }
    
    // Get all characters in the item
    final characters = _dictionary.splitIntoCharacters(item);
    final availability = await _database.checkCharactersAvailability(characters);
    
    final invalidCharacters = <String>[];
    for (final entry in availability.entries) {
      if (!entry.value) {
        invalidCharacters.add(entry.key);
      }
    }
    
    if (invalidCharacters.isEmpty) {
      return ValidationResult(
        isValid: true,
        item: item,
        invalidCharacters: [],
      );
    } else {
      // Get detailed info for each invalid character
      final detailedMessages = <String>[];
      for (final char in invalidCharacters) {
        final info = _infoService.getCharacterInfo(char);
        final alternatives = _infoService.getAlternatives(char);
        var message = '$char: $info';
        if (alternatives != null && alternatives.isNotEmpty) {
          message += ' (try: ${alternatives.join(", ")})';
        }
        detailedMessages.add(message);
      }
      
      return ValidationResult(
        isValid: false,
        item: item,
        invalidCharacters: invalidCharacters,
        message: detailedMessages.join('\n'),
        characterDetails: Map.fromIterables(
          invalidCharacters,
          invalidCharacters.map((c) => _infoService.getDetailedExplanation(c)),
        ),
      );
    }
  }
  
  /// Validate a list of items
  Future<List<ValidationResult>> validateItems(List<String> items) async {
    final results = <ValidationResult>[];
    for (final item in items) {
      results.add(await validateItem(item));
    }
    return results;
  }
  
  /// Validate a comma-separated string
  Future<ValidationSummary> validateSetString(String input) async {
    if (input.trim().isEmpty) {
      return ValidationSummary(
        isValid: false,
        validItems: [],
        invalidItems: [],
        message: 'No characters',
      );
    }
    
    // Replace Chinese comma with English comma for consistent parsing
    String processedInput = input.replaceAll('，', ',');
    
    // Remove English letters (a-z, A-Z) and keep only Chinese characters and punctuation
    processedInput = processedInput.replaceAll(RegExp(r'[a-zA-Z]'), '');
    
    // Check if anything remains after filtering
    if (processedInput.trim().isEmpty) {
      return ValidationSummary(
        isValid: false,
        validItems: [],
        invalidItems: [],
        message: 'No Chinese characters found',
      );
    }
    
    List<String> items;
    if (processedInput.contains(',')) {
      // Split by comma for word sets
      items = processedInput.split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      // Split into individual characters
      items = processedInput.split('')
          .where((c) => c.trim().isNotEmpty)
          .toList();
    }
    
    final validItems = <String>[];
    final invalidItems = <String>[];
    final missingCharacters = <String>{};
    
    for (final item in items) {
      final result = await validateItem(item);
      if (result.isValid) {
        validItems.add(item);
      } else {
        invalidItems.add(item);
        missingCharacters.addAll(result.invalidCharacters);
      }
    }
    
    return ValidationSummary(
      isValid: invalidItems.isEmpty,
      validItems: validItems,
      invalidItems: invalidItems,
      missingCharacters: missingCharacters.toList(),
      message: invalidItems.isEmpty 
          ? 'All items are valid' 
          : 'Invalid items: ${invalidItems.join(", ")}\nMissing characters: ${missingCharacters.join(", ")}',
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String item;
  final List<String> invalidCharacters;
  final String? message;
  final Map<String, String>? characterDetails;
  
  ValidationResult({
    required this.isValid,
    required this.item,
    required this.invalidCharacters,
    this.message,
    this.characterDetails,
  });
}

class ValidationSummary {
  final bool isValid;
  final List<String> validItems;
  final List<String> invalidItems;
  final List<String> missingCharacters;
  final String message;
  
  ValidationSummary({
    required this.isValid,
    required this.validItems,
    required this.invalidItems,
    this.missingCharacters = const [],
    required this.message,
  });
}