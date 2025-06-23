import 'package:flutter/material.dart';
import '../services/character_set_manager.dart';
import '../widgets/character_preview.dart';
import '../main.dart' show DuotoneThemeExtension;
import '../services/character_database.dart';
import '../services/learning_service.dart';

class MarkAsLearnedPage extends StatefulWidget {
  const MarkAsLearnedPage({super.key});

  @override
  State<MarkAsLearnedPage> createState() => _MarkAsLearnedPageState();
}

class _MarkAsLearnedPageState extends State<MarkAsLearnedPage> {
  final CharacterSetManager _characterSetManager = CharacterSetManager();
  final CharacterDatabase _characterDatabase = CharacterDatabase();
  final LearningService _learningService = LearningService();
  
  List<String> _allCharacters = [];
  Map<String, bool> _learnedStatus = {};
  bool _isLoading = true;
  
  // Drag selection state
  Set<String> _draggedCharacters = {};
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  bool _isSelecting = false;
  bool _isScrolling = false;
  double _lastScrollPosition = 0;
  
  // Track if any changes were made
  bool _changesMade = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    // First ensure predefined sets are loaded
    await _characterSetManager.loadPredefinedSets();
    
    // Load all character sets
    final sets = _characterSetManager.getAllSets();
    
    // Filter to built-in sets (predefined sets) and sort with HSK first
    final builtInSets = sets.where((set) => !set.id.startsWith('custom_')).toList();
    builtInSets.sort((a, b) {
      // HSK sets come first
      if (a.id.startsWith('hsk') && !b.id.startsWith('hsk')) return -1;
      if (!a.id.startsWith('hsk') && b.id.startsWith('hsk')) return 1;
      
      // Within HSK, sort by level
      if (a.id.startsWith('hsk') && b.id.startsWith('hsk')) {
        final aLevel = int.tryParse(a.id.replaceAll('hsk', '')) ?? 99;
        final bLevel = int.tryParse(b.id.replaceAll('hsk', '')) ?? 99;
        return aLevel.compareTo(bLevel);
      }
      
      // Other sets sorted alphabetically
      return a.name.compareTo(b.name);
    });
    
    // Collect all unique characters from all sets in order
    final allCharacters = <String>[];
    final seenCharacters = <String>{};
    
    for (final set in builtInSets) {
      // Extract individual characters from words in each set
      for (final item in set.characters) {
        // Split each word/phrase into individual characters
        for (int i = 0; i < item.length; i++) {
          final char = item[i];
          // Skip non-Chinese characters (like commas, spaces, etc.)
          if (_isChineseCharacter(char) && !seenCharacters.contains(char)) {
            allCharacters.add(char);
            seenCharacters.add(char);
          }
        }
      }
    }
    
    // Load learned status for all characters using LearningService
    final learnedList = await _learningService.getLearnedCharacters();
    final learnedCharacters = learnedList.toSet();
    final learnedWords = await _learningService.getLearnedWords();
    
    Map<String, bool> status = {};
    for (final char in allCharacters) {
      // Check if character is learned (single characters only in this page)
      status[char] = learnedCharacters.contains(char);
    }
    
    // Preload character data to ensure consistent rendering
    if (allCharacters.isNotEmpty) {
      await _characterDatabase.initialize();
      await _characterDatabase.loadCharacters(allCharacters);
    }
    
    setState(() {
      _allCharacters = allCharacters;
      _learnedStatus = status;
      _isLoading = false;
    });
  }
  
  // Helper method to check if a character is Chinese
  bool _isChineseCharacter(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnitAt(0);
    // Common Chinese character Unicode ranges
    return (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) || // CJK Unified Ideographs
           (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) || // CJK Extension A
           (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) || // CJK Extension B
           (codeUnit >= 0x2A700 && codeUnit <= 0x2B73F) || // CJK Extension C
           (codeUnit >= 0x2B740 && codeUnit <= 0x2B81F) || // CJK Extension D
           (codeUnit >= 0x2B820 && codeUnit <= 0x2CEAF) || // CJK Extension E
           (codeUnit >= 0xF900 && codeUnit <= 0xFAFF) || // CJK Compatibility Ideographs
           (codeUnit >= 0x2F800 && codeUnit <= 0x2FA1F); // CJK Compatibility Supplement
  }
  
  Future<void> _toggleLearned(String item) async {
    final isLearned = _learnedStatus[item] ?? false;
    
    // Always mark as single character since we only show single characters
    if (isLearned) {
      await _learningService.removeLearnedCharacter(item);
    } else {
      await _learningService.markCharacterAsLearned(item);
    }
    
    setState(() {
      _learnedStatus[item] = !isLearned;
      _changesMade = true;
    });
  }
  
  void _startDragSelection(String item) {
    // Don't start drag if we're scrolling
    if (_isScrolling) return;
    
    setState(() {
      _isDragging = true;
      _draggedCharacters = {item};
      _isSelecting = !(_learnedStatus[item] ?? false);
    });
  }
  
  void _updateDragSelection(String item) {
    if (_isDragging && !_draggedCharacters.contains(item)) {
      setState(() {
        _draggedCharacters.add(item);
      });
    }
  }
  
  void _endDragSelection() async {
    if (_isDragging) {
      // Apply the learned status to all dragged items
      for (final item in _draggedCharacters) {
        if ((_learnedStatus[item] ?? false) != _isSelecting) {
          await _toggleLearned(item);
        }
      }
      
      setState(() {
        _isDragging = false;
        _draggedCharacters.clear();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mark as Learned'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        if (_changesMade) {
          // Return true to indicate changes were made
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context, false);
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mark as Learned'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_changesMade) {
                Navigator.pop(context, true);
              } else {
                Navigator.pop(context, false);
              }
            },
          ),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _isScrolling = true;
              _lastScrollPosition = _scrollController.position.pixels;
            } else if (notification is ScrollEndNotification) {
              // Delay to ensure scroll has truly ended
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && (_scrollController.position.pixels - _lastScrollPosition).abs() < 1) {
                  setState(() {
                    _isScrolling = false;
                  });
                }
              });
            } else if (notification is ScrollUpdateNotification) {
              _lastScrollPosition = _scrollController.position.pixels;
            }
            return false;
          },
          child: Listener(
            onPointerUp: (_) => _endDragSelection(),
            onPointerMove: (event) {
              if (_isDragging && !_isScrolling) {
                // Check if we need to auto-scroll
                final scrollPosition = _scrollController.position;
                final localPosition = event.localPosition;
                
                if (localPosition.dy < 100 && scrollPosition.pixels > 0) {
                  // Scroll up
                  _scrollController.animateTo(
                    scrollPosition.pixels - 20,
                    duration: const Duration(milliseconds: 50),
                    curve: Curves.linear,
                  );
                } else if (localPosition.dy > MediaQuery.of(context).size.height - 200) {
                  // Scroll down
                  _scrollController.animateTo(
                    scrollPosition.pixels + 20,
                    duration: const Duration(milliseconds: 50),
                    curve: Curves.linear,
                  );
                }
              }
            },
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_allCharacters.length} items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150, // Max width for each item
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _allCharacters.length,
                      itemBuilder: (context, index) {
                        final item = _allCharacters[index];
                        return _buildCharacterTile(item, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCharacterTile(String item, int index) {
    final isLearned = _learnedStatus[item] ?? false;
    final isBeingDragged = _draggedCharacters.contains(item);
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    
    // Determine the effective state during drag
    final effectiveState = _isDragging && isBeingDragged ? _isSelecting : isLearned;
    
    return GestureDetector(
      onTapDown: (_) {
        if (!_isScrolling) {
          _startDragSelection(item);
        }
      },
      onTapUp: (_) async {
        if (!_isScrolling && _draggedCharacters.length == 1) {
          // Single tap - toggle on release
          await _toggleLearned(item);
        }
        _endDragSelection();
      },
      onTapCancel: () => _endDragSelection(),
      child: MouseRegion(
        onEnter: (_) {
          if (_isDragging) {
            _updateDragSelection(item);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: effectiveState
              ? (isDuotone 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2))
              : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: effectiveState
                ? (isDuotone 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.green)
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: effectiveState ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Character/Word display
              Center(
                child: item.length == 1 
                  ? SizedBox(
                      width: 60,
                      height: 60,
                      child: CharacterPreview(
                        character: item,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: item.length == 2 ? 28 : 20,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
              ),
              
              // Checkmark overlay
              if (effectiveState)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDuotone 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isDuotone
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}