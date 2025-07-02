import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'writing_practice_page.dart';
import '../services/character_dictionary.dart';
import '../services/learning_service.dart';
import '../services/cedict_service.dart';
import '../utils/pinyin_utils.dart';
import '../main.dart' show DuotoneThemeExtension;

class CharacterListPage extends StatefulWidget {
  final String setName;
  final List<String> characters;
  final bool isWordSet;
  final bool isCustomSet;
  final String? setId;

  const CharacterListPage({
    super.key,
    required this.setName,
    required this.characters,
    this.isWordSet = false,
    this.isCustomSet = false,
    this.setId,
  });

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  late String _currentSetName;
  final LearningService _learningService = LearningService();
  final CharacterDictionary _dictionary = CharacterDictionary();
  final CedictService _cedictService = CedictService();
  List<String> _learnedCharacters = [];
  bool _isSetFullyLearned = false;
  
  // Group management
  int _groupSize = 10; // Will be loaded from settings
  bool _showGroups = false;
  bool _showSuperGroups = false;
  
  // Shuffled characters for randomization
  List<String> _shuffledCharacters = [];
  
  @override
  void initState() {
    super.initState();
    // Production: removed debug print
    _currentSetName = widget.setName;
    _shuffleCharacters();
    _loadGroupSizeFromSettings();
    _loadLearnedStatus();
    _initializeCedict();
  }
  
  void _shuffleCharacters() {
    _shuffledCharacters = List.from(widget.characters);
    _shuffledCharacters.shuffle();
  }
  
  Future<void> _loadGroupSizeFromSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt('daily_learn_goal') ?? 10;
    setState(() {
      _groupSize = dailyGoal;
    });
  }
  
  Future<void> _initializeCedict() async {
    // Production: removed debug print
    try {
      await _cedictService.initialize();
      // Production: removed debug print
      
      // Test lookup of our problem characters
      // Production: removed debug print
      final testChars = ['客', '气', '不', '一', '七', '为什么', '得'];
      for (final char in testChars) {
        final entry = _cedictService.lookup(char);
        if (entry != null) {
          // Production: removed debug print
        } else {
          // Production: removed debug print
        }
      }
      
      
      // Update UI if still mounted
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Production: removed debug print
    }
  }
  
  Future<void> _loadLearnedStatus() async {
    // Production: removed debug print
    // Extract terms from characters for checking learned status
    final terms = widget.characters.map((item) => _extractTerm(item)).toList();
    // Production: removed debug print
    final learned = await _learningService.getLearnedCharactersForSet(terms);
    // Production: removed debug print
    final isFullyLearned = await _learningService.isSetFullyLearned(terms);
    // Production: removed debug print
    
    if (mounted) {
      setState(() {
        _learnedCharacters = learned;
        _isSetFullyLearned = isFullyLearned;
      });
    }
  }
  
  // Calculate number of groups
  int get _groupCount => (_shuffledCharacters.length / _groupSize).ceil();
  
  // Calculate super group size based on total characters
  int get _dynamicSuperGroupSize {
    final totalChars = _shuffledCharacters.length;
    if (totalChars >= 1000) return 100; // 10 groups of 10
    if (totalChars >= 800) return 80;   // 8 groups of 10
    if (totalChars >= 600) return 60;   // 6 groups of 10
    if (totalChars >= 400) return 40;   // 4 groups of 10
    return 0; // No super groups for sets < 400
  }
  
  // Check if we should show super groups
  bool get _shouldShowSuperGroups => _shuffledCharacters.length >= 400;
  
  // Calculate number of super groups
  int get _superGroupCount {
    if (!_shouldShowSuperGroups) return 0;
    return (_groupCount * _groupSize / _dynamicSuperGroupSize).ceil();
  }
  
  // Get groups for a specific super group
  List<int> _getSuperGroupIndices(int superGroupIndex) {
    final groupsPerSuperGroup = _dynamicSuperGroupSize ~/ _groupSize;
    final start = superGroupIndex * groupsPerSuperGroup;
    final end = math.min(start + groupsPerSuperGroup, _groupCount);
    return List.generate(end - start, (i) => start + i);
  }
  
  // Get characters for a specific group
  List<String> _getGroupCharacters(int groupIndex) {
    final start = groupIndex * _groupSize;
    final end = (start + _groupSize).clamp(0, _shuffledCharacters.length);
    return _shuffledCharacters.sublist(start, end);
  }
  
  // Get currently displayed characters in normal order
  List<String> get _displayedCharacters {
    // Show all characters (shuffled)
    return _shuffledCharacters;
  }
  
  // Check if we should show characters
  bool get _shouldShowCharacters {
    // Show characters only if:
    // 1. No groups exist (small sets)
    // 2. Groups are hidden and no supergroups
    // 3. Supergroups exist but are hidden
    if (_shuffledCharacters.length <= _groupSize) return true;
    if (_shouldShowSuperGroups) {
      return !_showSuperGroups;
    } else {
      return !_showGroups;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_currentSetName),
            const SizedBox(width: 8),
            InkWell(
              onTap: _showSetMenu,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.more_vert,
                  size: 20,
                ),
              ),
            ),
            const Spacer(),
            if (widget.isCustomSet)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: _showRenameDialog,
                tooltip: 'Rename',
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: CustomScrollView(
        slivers: [
          // Small spacing before characters
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          // Header with toggle button
          if (_shuffledCharacters.length > _groupSize)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_shouldShowSuperGroups) {
                          // Toggle supergroups
                          _showSuperGroups = !_showSuperGroups;
                        } else {
                          // Toggle regular groups
                          _showGroups = !_showGroups;
                        }
                      });
                    },
                    icon: Icon(
                      (_shouldShowSuperGroups ? _showSuperGroups : _showGroups) 
                        ? Icons.expand_less 
                        : Icons.expand_more
                    ),
                    label: Text(
                      _shouldShowSuperGroups 
                        ? (_showSuperGroups ? 'Hide Supergroups' : 'Show Supergroups')
                        : (_showGroups ? 'Hide Groups' : 'Show Groups'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          
          // Super groups section for large sets
          if (_shouldShowSuperGroups && _showSuperGroups)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // One supergroup per line
                  childAspectRatio: 6.0, // Wide aspect ratio for full width
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final groupIndices = _getSuperGroupIndices(index);
                    
                    // Count learned in this super group
                    int totalLearned = 0;
                    int totalChars = 0;
                    for (final groupIdx in groupIndices) {
                      final groupChars = _getGroupCharacters(groupIdx);
                      totalChars += groupChars.length;
                      totalLearned += groupChars.where((item) {
                        final term = _extractTerm(item);
                        return _learnedCharacters.contains(term) || _learnedCharacters.contains(item);
                      }).length;
                    }
                    
                    return _buildGroupCard(
                      label: 'Supergroup ${index + 1}',
                      subtitle: '', // No longer needed, count is inline
                      isSelected: false,
                      learnedCount: totalLearned,
                      totalCount: totalChars, // Show total characters in supergroup
                      onTap: () {
                        // Get characters for this supergroup
                        final groupIndices = _getSuperGroupIndices(index);
                        final supergroupChars = <String>[];
                        for (final groupIdx in groupIndices) {
                          supergroupChars.addAll(_getGroupCharacters(groupIdx));
                        }
                        
                        // Navigate to new page with supergroup's characters
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterListPage(
                              setName: widget.setName.length > 10 
                                  ? '${widget.setName.substring(0, 10)}... SG${index + 1}'
                                  : '${widget.setName} SG${index + 1}',
                              characters: supergroupChars,
                              isWordSet: widget.isWordSet,
                              isCustomSet: false,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _superGroupCount,
                ),
              ),
            ),
          
          // Regular groups section - show when groups are toggled on and no supergroups exist
          if (_showGroups && !_shouldShowSuperGroups && _shuffledCharacters.length > _groupSize)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // One group per line
                  childAspectRatio: 6.0, // Wide aspect ratio for full width
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _groupCount) return const SizedBox();
                      
                      final groupIndex = index;
                      final groupChars = _getGroupCharacters(groupIndex);
                      
                      // Count learned in this group
                      final learnedCount = groupChars.where((item) {
                        final term = _extractTerm(item);
                        return _learnedCharacters.contains(term) || _learnedCharacters.contains(item);
                      }).length;
                      
                      return _buildGroupCard(
                        label: 'Group ${groupIndex + 1}',
                        subtitle: '', // No longer needed, count is inline
                        isSelected: false,
                        learnedCount: learnedCount,
                        totalCount: groupChars.length,
                        onTap: () {
                          // Navigate to new page with just this group's characters
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterListPage(
                                setName: widget.setName.contains('SG') 
                                    ? '${widget.setName} G${groupIndex + 1}'.length > 25
                                        ? 'SG${widget.setName.split('SG').last.split(' ').first} G${groupIndex + 1}'
                                        : '${widget.setName} G${groupIndex + 1}'
                                    : widget.setName.length > 15
                                        ? '${widget.setName.substring(0, 15)}... G${groupIndex + 1}'
                                        : '${widget.setName} G${groupIndex + 1}',
                                characters: groupChars,
                                isWordSet: widget.isWordSet,
                                isCustomSet: false,
                              ),
                            ),
                          );
                        },
                      );
                  },
                  childCount: _groupCount,
                ),
              ),
            ),
          
          // Only show spacing, divider, and characters if we should show characters
          if (_shouldShowCharacters) ...[  
            // Spacing after groups
            if (_showGroups && _shuffledCharacters.length > _groupSize)
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            
            // Divider
            if (_showGroups && _shuffledCharacters.length > _groupSize)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
            
            // Small spacing before characters
            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),
          ],
          
          // Characters grid - only show if we should show characters
          if (_shouldShowCharacters)
            SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _displayedCharacters[index];
                  // Extract the term (before parentheses if any)
                  final term = _extractTerm(item);
                  // Check if the term is learned, not the full item with definition
                  final isLearned = _learnedCharacters.contains(term) || _learnedCharacters.contains(item);
                  
                  if (widget.isWordSet) {
                    final existingDef = _extractExistingDefinition(item);
                    
                    return Card(
                      elevation: 2,
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? (isLearned 
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! 
                              : Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!)
                          : (isLearned 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.3) 
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                  : Theme.of(context).colorScheme.surface),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Word/character tapped
                            _showCharacterInfo(term, item, isWord: true, isLearned: isLearned);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildWordDisplay(term, existingDef, isLearned),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Card(
                      elevation: 2,
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? (isLearned 
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! 
                              : Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!)
                          : (isLearned 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.3) 
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                  : Theme.of(context).colorScheme.surface),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Production: removed debug print
                            _showCharacterInfo(term, item, isWord: false, isLearned: isLearned);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildCharacterDisplay(term, isLearned),
                          ),
                        ),
                      ),
                    );
                  }
                },
                childCount: _displayedCharacters.length,
              ),
            ),
          ),
          
          // Bottom buttons - only show when characters are visible
          if (_shouldShowCharacters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSetFullyLearned ? null : () async {
                        // Production: removed debug print
                        // Production: removed debug print
                        // Production: removed debug print
                        
                        // Reload learned status to ensure it's up to date
                        await _loadLearnedStatus();
                        
                        // Get unlearned characters from displayed set - extract terms first
                        // Get unlearned items using the learning service's proper logic
                        final displayedTerms = _displayedCharacters.map((item) => _extractTerm(item)).toList();
                        final unlearnedChars = await _learningService.getUnlearnedItems(displayedTerms);
                        
                        // Production: removed debug print
                        
                        if (unlearnedChars.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('All items in this set have been learned!'),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        // Start learning mode with first unlearned character
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WritingPracticePage(
                              character: unlearnedChars.first,
                              characterSet: _currentSetName,
                              allCharacters: unlearnedChars,
                              isWord: widget.isWordSet,
                              mode: PracticeMode.learning,
                              onComplete: (success) async {
                                // This callback is called when user completes a character in Endless Practice mode
                                // For regular learning mode, characters are marked as learned inside WritingPracticePage
                                // Production: removed debug print
                              },
                            ),
                          ),
                        );
                        
                        // Clear cache and reload learned status to update the UI
                        _learningService.clearCache();
                        await _loadLearnedStatus();
                        
                        // Force a rebuild to update colors
                        if (mounted) {
                          setState(() {});
                        }
                        
                        // Debug: Print what was actually learned
                        final debugLearned = await _learningService.getLearnedWords();
                        // Production: removed debug print
                        
                        // Check if set is now fully learned
                        if (await _learningService.isSetFullyLearned(widget.characters) && widget.setId != null) {
                          await _learningService.markSetAsLearned(widget.setId!, widget.characters);
                        }
                      },
                      icon: Icon(_isSetFullyLearned ? Icons.check_circle : Icons.school),
                      label: Text(
                        _isSetFullyLearned ? 'Set Learned!' : 'Learning Mode'
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isSetFullyLearned ? Colors.green : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        
                        // Clear cache to get fresh data
                        _learningService.clearCache();
                        
                        // Get fresh learned status
                        await _loadLearnedStatus();
                        
                        // Filter only learned characters from displayed set for testing mode
                        final learnedTerms = _displayedCharacters
                            .where((item) {
                              final term = _extractTerm(item);
                              return _learnedCharacters.contains(term) || _learnedCharacters.contains(item);
                            })
                            .map((item) => _extractTerm(item))
                            .toList();
                        
                        // Close loading
                        if (mounted) Navigator.pop(context);
                        
                        if (learnedTerms.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No learned items in this set yet. Use Learning Mode first!'),
                            ),
                          );
                          return;
                        }
                        
                        learnedTerms.shuffle(); // Randomize the order
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WritingPracticePage(
                              character: learnedTerms.first,
                              characterSet: _currentSetName,
                              allCharacters: learnedTerms,
                              isWord: widget.isWordSet,
                              mode: PracticeMode.testing,
                            ),
                          ),
                        ).then((_) async {
                          // Reload learned status when returning from testing
                          await _loadLearnedStatus();
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Practice All'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    
    return scaffold;
  }
  
  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _currentSetName);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Set'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Set Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != _currentSetName) {
                await _updateSetName(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showSetMenu() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Mark All as Learned'),
            onTap: () {
              Navigator.pop(context);
              _showMarkAllAsLearnedDialog();
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showMarkAllAsLearnedDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Learned'),
        content: Text(
          'Do you really want to mark all ${widget.characters.length} ${widget.isWordSet ? "words" : "characters"} in "$_currentSetName" as learned?\n\nYou will not be able to undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Mark All as Learned'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        // Mark all items as learned
        for (final item in widget.characters) {
          final term = _extractTerm(item);
          if (widget.isWordSet && term.length > 1) {
            await _learningService.markWordAsLearned(term);
          } else {
            await _learningService.markCharacterAsLearned(term);
          }
        }
        
        // Reload learned status
        await _loadLearnedStatus();
        
        // Close progress dialog
        Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Marked all items in "$_currentSetName" as learned'),
            ),
          );
        }
      } catch (e) {
        // Close progress dialog on error
        Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to mark items as learned'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _updateSetName(String newName) async {
    if (widget.setId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final customSets = prefs.getStringList('custom_sets') ?? [];
    
    // Find and update the set
    for (int i = 0; i < customSets.length; i++) {
      try {
        final setData = jsonDecode(customSets[i]);
        if (setData['id'] == widget.setId) {
          setData['name'] = newName;
          customSets[i] = jsonEncode(setData);
          break;
        }
      } catch (e) {
        // Production: removed debug print
      }
    }
    
    await prefs.setStringList('custom_sets', customSets);
    
    setState(() {
      _currentSetName = newName;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set renamed to "$newName"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _showCharacterInfo(String term, String originalItem, {required bool isWord, required bool isLearned}) {
    // Production: removed debug print
    String? pronunciation;
    String? definition;
    String displayTerm = term;
    
    // First check if there's an existing definition in the original item
    final existingDef = _extractExistingDefinition(originalItem);
    if (existingDef != null) {
      // Production: removed debug print
      definition = existingDef;
    }
    
    // Try to get pronunciation and definition from dictionary or CEDICT
    // First try character dictionary (for both single and multi-character)
    if (term.length == 1) {
      // Single character - try character dictionary first
      final charInfo = _dictionary.getCharacterInfo(term);
      if (charInfo != null) {
        // Production: removed debug print
        pronunciation = PinyinUtils.convertToneNumbersToMarks(charInfo.pinyin);
        definition = charInfo.definition;
      }
    } else {
      // Multi-character - try word dictionary first
      final wordInfo = _dictionary.getWordInfo(term);
      if (wordInfo != null) {
        // Production: removed debug print
        pronunciation = PinyinUtils.convertToneNumbersToMarks(wordInfo.pinyin);
        definition ??= wordInfo.definition;
      }
    }
    
    // Always try CEDICT for any missing info (both single and multi-character)
    // Check if CEDICT service is loaded (it's a singleton, so check directly)
    if (_cedictService.isLoaded && (pronunciation == null || definition == null)) {
      // Trying CEDICT lookup
      final cedictEntry = _cedictService.lookup(term);
      if (cedictEntry != null) {
        // Production: removed debug print
        pronunciation ??= PinyinUtils.convertToneNumbersToMarks(cedictEntry.pinyin);
        definition ??= cedictEntry.definition;
      } else {
        // Production: removed debug print
        // If multi-character term has no CEDICT entry, build pinyin from individual characters
        if (term.length > 1 && pronunciation == null) {
          pronunciation = _buildPinyinFromCharacters(term);
        }
      }
    } else if (!_cedictService.isLoaded && (pronunciation == null || definition == null)) {
      // Production: removed debug print
    }
    
    // If single character has no info, try to use the full phrase info
    if (term.length == 1 && (pronunciation == null || definition == null) && originalItem != term) {
      // Production: removed debug print
      // originalItem might be a phrase containing this character
      if (_cedictService.isLoaded) {
        final phraseEntry = _cedictService.lookup(originalItem);
        if (phraseEntry != null) {
          // Production: removed debug print
          pronunciation = PinyinUtils.convertToneNumbersToMarks(phraseEntry.pinyin);
          definition = phraseEntry.definition;
          displayTerm = originalItem; // Show the full phrase
        }
      }
    }
    
    // For multi-character terms, we'll only show the full phrase definition
    // No need to break down individual characters
    Map<String, List<String>>? characterBreakdown;
    
    // Production: removed debug print
    
    if (pronunciation == null && definition == null) {
      // If no info available, go directly to practice
      // Production: removed debug print
      _navigateToPractice(term, isWord: isWord, isLearned: isLearned);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          displayTerm,
          style: const TextStyle(fontSize: 48),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pronunciation
            if (pronunciation != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    PinyinUtils.convertToneNumbersToMarks(pronunciation),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (definition != null) const SizedBox(height: 16),
            ],
            // Definition
            if (definition != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.book,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      definition,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
            if (isLearned) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle, 
                      size: 16, 
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                          : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Learned',
                      style: TextStyle(
                        color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                            : Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!isLearned) ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToPractice(term, isWord: isWord, isLearned: false);
              },
              icon: const Icon(Icons.school),
              label: const Text('Learn'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToPractice(term, isWord: isWord, isLearned: true);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Practice'),
            ),
          ],
        ],
      ),
    );
  }
  
  void _navigateToPractice(String term, {required bool isWord, required bool isLearned}) {
    // Production: removed debug print
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WritingPracticePage(
          character: term,
          characterSet: _currentSetName,
          allCharacters: [term], // Pass only the selected character
          isWord: isWord,
          mode: isLearned ? PracticeMode.testing : PracticeMode.learning,
          onComplete: (success) async {
            if (!isLearned && success) {
              await _learningService.markCharacterAsLearned(term);
              await _loadLearnedStatus();
            }
          },
        ),
      ),
    ).then((_) async {
      // Add a small delay to ensure saves are complete
      await Future.delayed(const Duration(milliseconds: 200));
      await _loadLearnedStatus();
      // Force a rebuild to update the UI
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  /// Extract the character/word from item that may contain definition in parentheses
  String _extractTerm(String item) {
    final parenIndex = item.indexOf('(');
    if (parenIndex > 0) {
      return item.substring(0, parenIndex).trim();
    }
    return item.trim();
  }
  
  /// Extract existing definition from item if it has one
  String? _extractExistingDefinition(String item) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(item);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
  
  /// Truncate definition for grid view to avoid overflow
  String _truncateDefinition(String? definition) {
    if (definition == null || definition.isEmpty) return '';
    
    // For grid view, limit to reasonable length to avoid overflow
    const maxLength = 15;
    if (definition.length <= maxLength) return definition;
    
    // Try to cut at a semicolon
    final semicolonIndex = definition.indexOf(';');
    if (semicolonIndex > 0 && semicolonIndex <= maxLength) {
      return definition.substring(0, semicolonIndex);
    }
    
    // Try to cut at a comma
    final commaIndex = definition.indexOf(',');
    if (commaIndex > 0 && commaIndex <= maxLength) {
      return definition.substring(0, commaIndex);
    }
    
    // Try to cut at a space
    final spaceCutoff = definition.substring(0, maxLength).lastIndexOf(' ');
    if (spaceCutoff > 8) {
      return definition.substring(0, spaceCutoff) + '...';
    }
    
    return definition.substring(0, maxLength - 3) + '...';
  }
  
  /// Build the display widget for a single character
  Widget _buildCharacterDisplay(String character, bool isLearned) {
    // Try to get definition and pinyin
    String? definition;
    String? pinyin;
    
    if (_cedictService.isLoaded) {
      final entry = _cedictService.lookup(character);
      if (entry != null) {
        definition = entry.definition;
        pinyin = PinyinUtils.convertToneNumbersToMarks(entry.pinyin);
      } else {
        // Production: removed debug print
        // For multi-character strings labeled as single character, try building pinyin
        if (character.length > 1) {
          pinyin = _buildPinyinFromCharacters(character);
        }
      }
    } else {
      // Production: removed debug print
    }
    
    if (definition == null || pinyin == null) {
      final charInfo = _dictionary.getCharacterInfo(character);
      if (charInfo != null) {
        definition ??= charInfo.definition;
        pinyin ??= PinyinUtils.convertToneNumbersToMarks(charInfo.pinyin);
        if (character == '七') {
          // Production: removed debug print
        }
      }
    }
    
    if (character == '七') {
      // Production: removed debug print
    }
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            character,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? (isLearned 
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1! 
                      : Theme.of(context).colorScheme.primary)
                  : Colors.white,
            ),
          ),
          if (pinyin != null) ...[
            const SizedBox(height: 2),
            Text(
              pinyin,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                    ? (isLearned 
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.7) 
                        : Theme.of(context).colorScheme.primary.withOpacity(0.7))
                    : Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (definition != null) ...[
            const SizedBox(height: 2),
            Text(
              _truncateDefinition(definition),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                    ? (isLearned 
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.6) 
                        : Theme.of(context).colorScheme.primary.withOpacity(0.6))
                    : Colors.white60,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGroupCard({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required int learnedCount,
    required int totalCount,
  }) {
    final progress = totalCount > 0 ? learnedCount / totalCount : 0.0;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            gradient: totalCount > 0 ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [progress, progress],
              colors: [
                isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
              ],
            ) : null,
            color: totalCount == 0 ? (isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Group label with count inline
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (totalCount > 0) // Only show count if totalCount > 0
                      Text(
                        '($totalCount items)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Progress text on the right (only if totalCount > 0)
              if (totalCount > 0)
                Text(
                  '$learnedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build pinyin from individual characters when phrase has no pinyin
  String? _buildPinyinFromCharacters(String term) {
    if (!_cedictService.isLoaded) return null;
    
    List<String> pinyinParts = [];
    
    for (int i = 0; i < term.length; i++) {
      final char = term[i];
      
      // Try CEDICT first
      final cedictEntry = _cedictService.lookup(char);
      if (cedictEntry != null) {
        pinyinParts.add(PinyinUtils.convertToneNumbersToMarks(cedictEntry.pinyin));
        continue;
      }
      
      // Try character dictionary
      final charInfo = _dictionary.getCharacterInfo(char);
      if (charInfo != null) {
        pinyinParts.add(PinyinUtils.convertToneNumbersToMarks(charInfo.pinyin));
        continue;
      }
      
      // If no pinyin found for this character, return null
      return null;
    }
    
    // Join all pinyin parts with spaces
    return pinyinParts.join(' ');
  }
  
  /// Build the display widget for a word/term
  Widget _buildWordDisplay(String term, String? existingDef, bool isLearned) {
    // Try to get definition for any term (single or multi-character)
    String? definition;
    String? pinyin;
    
    if (existingDef != null) {
      // Use existing definition from character_sets.json
      definition = existingDef;
    } else if (_cedictService.isLoaded) {
      // Look up in CEDICT
      final entry = _cedictService.lookup(term);
      if (entry != null) {
        definition = entry.definition;
        pinyin = PinyinUtils.convertToneNumbersToMarks(entry.pinyin);
      } else if (term.length > 1) {
        // If multi-character term has no CEDICT entry, build pinyin from individual characters
        pinyin = _buildPinyinFromCharacters(term);
      }
    }
    
    // If still no definition, try character dictionary for single characters
    if (definition == null && term.length == 1) {
      final charInfo = _dictionary.getCharacterInfo(term);
      if (charInfo != null) {
        definition = charInfo.definition;
        pinyin ??= PinyinUtils.convertToneNumbersToMarks(charInfo.pinyin);
      }
    }
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            term,
            style: TextStyle(
              fontSize: term.length > 2 ? 24 : 32,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? (isLearned 
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1! 
                      : Theme.of(context).colorScheme.primary)
                  : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (definition != null || pinyin != null) ...[
            const SizedBox(height: 4),
            Column(
              children: [
                if (pinyin != null)
                  Text(
                    pinyin,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? (isLearned 
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.7) 
                              : Theme.of(context).colorScheme.primary.withOpacity(0.7))
                          : Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (definition != null)
                  Text(
                    _truncateDefinition(definition),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? (isLearned 
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.6) 
                              : Theme.of(context).colorScheme.primary.withOpacity(0.6))
                          : Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}