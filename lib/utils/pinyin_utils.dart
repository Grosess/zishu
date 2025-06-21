/// Utility functions for pinyin conversion
class PinyinUtils {
  static const Map<String, List<String>> toneMap = {
    'a': ['a', 'ā', 'á', 'ǎ', 'à'],
    'e': ['e', 'ē', 'é', 'ě', 'è'],
    'i': ['i', 'ī', 'í', 'ǐ', 'ì'],
    'o': ['o', 'ō', 'ó', 'ǒ', 'ò'],
    'u': ['u', 'ū', 'ú', 'ǔ', 'ù'],
    'ü': ['ü', 'ǖ', 'ǘ', 'ǚ', 'ǜ'],
    'A': ['A', 'Ā', 'Á', 'Ǎ', 'À'],
    'E': ['E', 'Ē', 'É', 'Ě', 'È'],
    'I': ['I', 'Ī', 'Í', 'Ǐ', 'Ì'],
    'O': ['O', 'Ō', 'Ó', 'Ǒ', 'Ò'],
    'U': ['U', 'Ū', 'Ú', 'Ǔ', 'Ù'],
    'Ü': ['Ü', 'Ǖ', 'Ǘ', 'Ǚ', 'Ǜ'],
  };

  /// Convert pinyin with tone numbers to pinyin with tone marks
  /// e.g., "zhong1 wu3" -> "zhōng wǔ"
  static String convertToneNumbersToMarks(String pinyinWithNumbers) {
    if (pinyinWithNumbers.isEmpty) return pinyinWithNumbers;
    
    // Split by spaces to handle multiple syllables
    final syllables = pinyinWithNumbers.split(' ');
    final List<String> convertedSyllables = [];
    
    for (String syllable in syllables) {
      convertedSyllables.add(_convertSyllable(syllable));
    }
    
    return convertedSyllables.join(' ');
  }
  
  static String _convertSyllable(String syllable) {
    // Check if syllable ends with a tone number
    if (syllable.isEmpty || !RegExp(r'[1-5]$').hasMatch(syllable)) {
      return syllable;
    }
    
    // Extract tone number
    final toneNumber = int.parse(syllable[syllable.length - 1]);
    final pinyinWithoutTone = syllable.substring(0, syllable.length - 1);
    
    // Handle 'v' as 'ü'
    String processed = pinyinWithoutTone.replaceAll('v', 'ü').replaceAll('V', 'Ü');
    
    // Tone 5 (neutral tone) - no mark needed
    if (toneNumber == 5) {
      return processed;
    }
    
    // Find which vowel should receive the tone mark
    // Rules: a/e > o > u/i (rightmost when u and i appear together)
    int vowelIndex = -1;
    String vowelToMark = '';
    
    // Check for 'a' or 'e' first (they always get the tone)
    for (int i = 0; i < processed.length; i++) {
      if (processed[i] == 'a' || processed[i] == 'A' || 
          processed[i] == 'e' || processed[i] == 'E') {
        vowelIndex = i;
        vowelToMark = processed[i];
        break;
      }
    }
    
    // If no 'a' or 'e', check for 'o'
    if (vowelIndex == -1) {
      for (int i = 0; i < processed.length; i++) {
        if (processed[i] == 'o' || processed[i] == 'O') {
          vowelIndex = i;
          vowelToMark = processed[i];
          break;
        }
      }
    }
    
    // If no 'a', 'e', or 'o', find the rightmost 'u' or 'i'
    if (vowelIndex == -1) {
      for (int i = processed.length - 1; i >= 0; i--) {
        if (processed[i] == 'i' || processed[i] == 'I' || 
            processed[i] == 'u' || processed[i] == 'U' ||
            processed[i] == 'ü' || processed[i] == 'Ü') {
          vowelIndex = i;
          vowelToMark = processed[i];
          break;
        }
      }
    }
    
    // Apply tone mark
    if (vowelIndex != -1 && toneMap.containsKey(vowelToMark)) {
      final tonedVowel = toneMap[vowelToMark]![toneNumber];
      return processed.substring(0, vowelIndex) + 
             tonedVowel + 
             processed.substring(vowelIndex + 1);
    }
    
    // If we couldn't apply the tone, return original
    return syllable;
  }
}