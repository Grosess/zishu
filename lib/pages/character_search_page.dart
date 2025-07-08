import 'package:flutter/material.dart';
import 'dart:async';
import '../services/cedict_service.dart';
import '../services/character_database.dart';
import '../services/learning_service.dart';
import '../services/character_set_manager.dart';
import '../widgets/character_preview.dart';
import 'writing_practice_page.dart';
import '../main.dart' show DuotoneThemeExtension;
import '../utils/pinyin_utils.dart';
import '../services/haptic_service.dart';

class CharacterSearchPage extends StatefulWidget {
  const CharacterSearchPage({super.key});

  @override
  State<CharacterSearchPage> createState() => _CharacterSearchPageState();
}

class _CharacterSearchPageState extends State<CharacterSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final CedictService _cedictService = CedictService();
  final CharacterDatabase _characterDatabase = CharacterDatabase();
  final LearningService _learningService = LearningService();
  final CharacterSetManager _setManager = CharacterSetManager();
  
  List<CedictEntry> _searchResults = [];
  bool _isSearching = false;
  Map<String, bool> _learnedStatus = {};
  final Map<String, List<String>> _pinyinToCharacters = {};
  bool _isInitialized = false;
  Timer? _debounceTimer;
  bool _showLearnedOnly = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    // Initialize services
    await _cedictService.initialize();
    await _characterDatabase.initialize();
    await _setManager.loadPredefinedSets();
    
    // Build pinyin index
    _buildPinyinIndex();
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  void _buildPinyinIndex() {
    _pinyinToCharacters.clear();
    
    // Get all entries from cedict
    if (_cedictService.isLoaded) {
      // We need to iterate through all entries to build the index
      // Since CedictService doesn't expose the dictionary, we'll search as user types
    }
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    final results = <CedictEntry>[];
    final processedQuery = query.toLowerCase().trim();
    
    // Check if query contains Chinese characters
    bool isChineseQuery = false;
    for (int i = 0; i < query.length; i++) {
      if (_isChineseCharacter(query[i])) {
        isChineseQuery = true;
        break;
      }
    }
    
    if (isChineseQuery) {
      // Direct lookup for Chinese characters
      final entry = _cedictService.lookup(query);
      if (entry != null) {
        results.add(entry);
      }
      
      // Also check individual characters if it's a multi-character query
      if (query.length > 1) {
        for (int i = 0; i < query.length; i++) {
          final char = query[i];
          if (_isChineseCharacter(char)) {
            final charEntry = _cedictService.lookup(char);
            if (charEntry != null && !results.any((e) => e.simplified == char)) {
              results.add(charEntry);
            }
          }
        }
      }
    } else {
      // Search by pinyin or English using the full CEDICT dictionary
      final searchResults = _cedictService.search(processedQuery, maxResults: 100);
      
      // Deduplicate results - keep only unique characters
      final uniqueResults = <CedictEntry>[];
      final seenCharacters = <String>{};
      
      for (final entry in searchResults) {
        if (!seenCharacters.contains(entry.simplified)) {
          uniqueResults.add(entry);
          seenCharacters.add(entry.simplified);
        }
      }
      
      // Get characters from predefined sets for prioritization
      await _setManager.loadPredefinedSets();
      final allSets = _setManager.getAllSets();
      
      // Create a map of character to priority (lower number = higher priority)
      final characterPriority = <String, int>{};
      
      // HSK sets get highest priority
      final hskPriorities = {
        'hsk1': 1,
        'hsk2': 2,
        'hsk3': 3,
        'hsk4': 4,
        'hsk5': 5,
        'hsk6': 6,
      };
      
      // Assign priorities
      for (final set in allSets) {
        final setIdLower = set.id.toLowerCase();
        int priority = 100; // Default priority for non-HSK sets
        
        // Check if it's an HSK set
        for (final hskLevel in hskPriorities.keys) {
          if (setIdLower.contains(hskLevel)) {
            priority = hskPriorities[hskLevel]!;
            break;
          }
        }
        
        // Other common sets get medium priority
        if (setIdLower.contains('radicals')) priority = 20;
        if (setIdLower.contains('numbers')) priority = 25;
        if (setIdLower.contains('colors')) priority = 30;
        if (setIdLower.contains('common')) priority = 35;
        
        // Assign priority to all characters in the set
        for (final char in set.characters) {
          if (!characterPriority.containsKey(char) || characterPriority[char]! > priority) {
            characterPriority[char] = priority;
          }
        }
      }
      
      // Filter out entries with English characters or unknown symbols
      final filteredResults = uniqueResults.where((entry) {
        // Check if the simplified form contains only Chinese characters
        for (int i = 0; i < entry.simplified.length; i++) {
          final char = entry.simplified[i];
          if (!_isChineseCharacter(char)) {
            return false; // Skip entries with non-Chinese characters
          }
        }
        // Also filter out entries with '?' in definition (usually means uncertain)
        if (entry.definition.contains('?')) {
          return false;
        }
        // Filter out entries where pinyin contains uppercase letters (like TA, XX)
        // Normal pinyin should only have lowercase letters with tone marks
        if (entry.pinyin.contains(RegExp(r'[A-Z]{2,}'))) {
          return false;
        }
        // Filter out entries with definitions that are too technical or contain abbreviations
        final defLower = entry.definition.toLowerCase();
        if (defLower.contains('variant of') || 
            defLower.contains('used in') ||
            defLower.contains('abbr.') ||
            defLower.contains('abbreviation') ||
            defLower.contains('surname') ||
            defLower.contains('radical') ||
            defLower.contains('see also')) {
          return false;
        }
        return true;
      }).toList();
      
      // Sort filtered results by priority
      filteredResults.sort((a, b) {
        final aPriority = characterPriority[a.simplified] ?? 999;
        final bPriority = characterPriority[b.simplified] ?? 999;
        
        // First sort by priority
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        
        // Then by character length
        if (a.simplified.length != b.simplified.length) {
          return a.simplified.length.compareTo(b.simplified.length);
        }
        
        // Finally by pinyin
        return a.pinyin.compareTo(b.pinyin);
      });
      
      // Take only the first 50 results after sorting
      results.addAll(filteredResults.take(50));
    }
    
    // Load learned status for results
    final learnedStatus = <String, bool>{};
    final learnedChars = await _learningService.getLearnedCharacters();
    final learnedWords = await _learningService.getLearnedWords();
    
    for (final entry in results) {
      if (entry.simplified.length == 1) {
        learnedStatus[entry.simplified] = learnedChars.contains(entry.simplified);
      } else {
        learnedStatus[entry.simplified] = learnedWords.contains(entry.simplified);
      }
    }
    
    // Filter by learned status if checkbox is checked
    List<CedictEntry> filteredResults = results;
    if (_showLearnedOnly) {
      filteredResults = results.where((entry) => learnedStatus[entry.simplified] ?? false).toList();
    }
    
    setState(() {
      _searchResults = filteredResults;
      _learnedStatus = learnedStatus;
      _isSearching = false;
    });
  }
  
  
  bool _isChineseCharacter(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
           (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) ||
           (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) ||
           (codeUnit >= 0x2A700 && codeUnit <= 0x2B73F) ||
           (codeUnit >= 0x2B740 && codeUnit <= 0x2B81F) ||
           (codeUnit >= 0x2B820 && codeUnit <= 0x2CEAF) ||
           (codeUnit >= 0xF900 && codeUnit <= 0xFAFF) ||
           (codeUnit >= 0x2F800 && codeUnit <= 0x2FA1F);
  }
  
  Future<void> _handleCharacterTap(String character) async {
    final isLearned = _learnedStatus[character] ?? false;
    
    if (isLearned) {
      // Practice mode for learned characters
      await _practiceCharacter(character);
    } else {
      // Learn mode for new characters
      await _learnCharacter(character);
    }
  }
  
  Future<void> _practiceCharacter(String character) async {
    // Preload character data
    await _characterDatabase.loadCharacters([character]);
    
    if (!mounted) return;
    
    // Navigate to practice page in testing mode
    HapticService().lightImpact();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => WritingPracticePage(
          character: character,
          characterSet: 'Search Results',
          allCharacters: [character],
          isWord: character.length > 1,
          mode: PracticeMode.testing,
        ),
      ),
    );
    
    // Refresh learned status if we returned from practice
    if (result != null && mounted) {
      _performSearch(_searchController.text);
    }
  }
  
  Future<void> _learnCharacter(String character) async {
    // Preload character data
    await _characterDatabase.loadCharacters([character]);
    
    if (!mounted) return;
    
    // Navigate to practice page in learning mode
    HapticService().lightImpact();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => WritingPracticePage(
          character: character,
          characterSet: 'Search Results',
          allCharacters: [character],
          isWord: character.length > 1,
          mode: PracticeMode.learning,
        ),
      ),
    );
    
    // Refresh learned status if we returned from practice
    if (result != null && mounted) {
      _performSearch(_searchController.text);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Characters'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by pinyin, Chinese, or English',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onChanged: (value) {
                    // Cancel previous timer
                    _debounceTimer?.cancel();
                    
                    // Show loading immediately if there's text
                    if (value.isNotEmpty) {
                      setState(() {
                        _isSearching = true;
                      });
                    }
                    
                    // Set up new timer
                    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                      _performSearch(value);
                    });
                  },
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _showLearnedOnly,
                      onChanged: (value) {
                        HapticService().selectionClick();
                        setState(() {
                          _showLearnedOnly = value ?? false;
                        });
                        // Re-run search with new filter
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                      activeColor: isDuotone
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                          : Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      'Show learned only',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_isInitialized)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_isSearching)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Searching...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter pinyin to search',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Examples:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Pinyin: "shang" → 上, 伤, 尚\n• Chinese: "上" → above/on\n• English: "water" → 水, 江, 河',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showLearnedOnly ? 'No learned results found' : 'No results found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showLearnedOnly 
                          ? 'Try unchecking "Show learned only" or search for different characters'
                          : 'Try a different pinyin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final entry = _searchResults[index];
                  final isLearned = _learnedStatus[entry.simplified] ?? false;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: entry.simplified.length == 1
                          ? SizedBox(
                              width: 48,
                              height: 48,
                              child: CharacterPreview(
                                character: entry.simplified,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    entry.simplified.length > 4 
                                        ? '${entry.simplified.substring(0, 3)}...' 
                                        : entry.simplified,
                                    style: TextStyle(
                                      fontSize: entry.simplified.length == 2 ? 20 : 
                                               entry.simplified.length == 3 ? 14 : 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              PinyinUtils.convertToneNumbersToMarks(entry.pinyin),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isLearned) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: isDuotone
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.green,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        entry.definition,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      trailing: isLearned
                          ? TextButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Practice'),
                              onPressed: () => _handleCharacterTap(entry.simplified),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : TextButton.icon(
                              icon: const Icon(Icons.school, size: 18),
                              label: const Text('Learn'),
                              onPressed: () => _handleCharacterTap(entry.simplified),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                      onTap: () => _handleCharacterTap(entry.simplified),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}