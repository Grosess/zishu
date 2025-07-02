import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/character_set_manager.dart';
import '../services/makemeahanzi_processor.dart';
import '../services/character_validator.dart';
import 'character_list_page.dart';
import 'writing_practice_page.dart';
import 'groups_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/learning_service.dart';
import '../services/folder_service.dart';
import '../models/folder_model.dart';
import '../config/database_config.dart';
import '../services/cedict_service.dart';
import '../services/statistics_service.dart';
import '../main.dart' show DuotoneThemeExtension;
import '../widgets/character_preview.dart';
import '../services/character_database.dart';
import '../services/character_preview_cache.dart';

class SetsPage extends StatefulWidget {
  const SetsPage({super.key});

  @override
  State<SetsPage> createState() => SetsPageState();
}

class SetsPageState extends State<SetsPage> with TickerProviderStateMixin {
  final CharacterSetManager _setManager = CharacterSetManager();
  final MakeMeAHanziProcessor _processor = MakeMeAHanziProcessor();
  final CharacterValidator _validator = CharacterValidator();
  final CharacterDatabase _characterDatabase = CharacterDatabase();
  final LearningService _learningService = LearningService();
  final FolderService _folderService = FolderService();
  final CedictService _cedictService = CedictService();
  final StatisticsService _statsService = StatisticsService();
  final ScrollController _builtInScrollController = ScrollController();
  final ScrollController _customScrollController = ScrollController();
  
  TabController? _tabController;
  List<CharacterSet> _characterSets = [];
  List<CharacterSet> _customSets = [];
  List<SetFolder> _folders = [];
  Map<String, String> _setFolders = {}; // setId -> folderId mapping
  bool _isLoading = true;
  final Map<String, bool> _loadingStates = {};
  Map<String, double> _setProgress = {};
  int _currentTabIndex = 0;
  String? _selectedFolderId;
  bool _controllersInitialized = false;
  final Set<String> _expandedFolderIds = {}; // Track which folders are expanded
  
  // Search and multi-select functionality
  final TextEditingController _searchController = TextEditingController();
  List<CharacterSet> _additionalSets = []; // Additional sets that can be added
  List<CharacterSet> _filteredSets = [];
  final Set<String> _selectedSetIds = {};
  final Set<String> _addedSetIds = {}; // Track which sets have been added to built-in
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with saved tab index
    _initializeWithSavedState();
    _loadCharacterSets();
    _loadAdditionalSets();
    _initializeProcessor();
    _loadFolders();
    _initializeCedict();
    _loadExpandedFolders();
    _initializeCharacterDatabase();
    
    // Check if there's a pending set to show (from recent sets)
    _checkPendingSetToShow();
    
    // Initialize search functionality
    _searchController.addListener(_onSearchChanged);
  }
  
  Future<void> _initializeWithSavedState() async {
    // Load saved tab index
    final prefs = await SharedPreferences.getInstance();
    
    // Check if this is the first time opening sets page
    final hasOpenedSetsPage = prefs.getBool('has_opened_sets_page') ?? false;
    int initialIndex;
    
    if (!hasOpenedSetsPage) {
      // First time - default to Built-in tab (index 0)
      initialIndex = 0;
      // Mark that we've opened the sets page
      await prefs.setBool('has_opened_sets_page', true);
    } else {
      // Not first time - use saved index or default to 0
      initialIndex = prefs.getInt('sets_tab_index') ?? 0;
    }
    
    // Initialize controllers with determined index
    if (mounted) {
      setState(() {
        _currentTabIndex = initialIndex;
        _tabController = TabController(
          length: 2, 
          vsync: this, 
          initialIndex: initialIndex
        );
        _controllersInitialized = true;
        
        // Add listener for tab changes
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging && _currentTabIndex != _tabController!.index) {
            setState(() {
              _currentTabIndex = _tabController!.index;
            });
            _saveTabIndex(_tabController!.index);
          }
        });
      });
    }
  }
  
  Future<void> _saveTabIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sets_tab_index', index);
  }
  
  Future<void> _checkPendingSetToShow() async {
    // Wait for everything to load
    int waitTime = 0;
    while (_isLoading && waitTime < 3000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitTime += 100;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final pendingSetJson = prefs.getString('pending_set_to_show');
    
    if (pendingSetJson != null && mounted) {
      // Clear the pending set
      await prefs.remove('pending_set_to_show');
      
      try {
        final setData = jsonDecode(pendingSetJson);
        
        // Find the matching set in our loaded sets
        CharacterSet? targetSet;
        
        // Search in character sets
        for (final set in _characterSets) {
          if (set.name == setData['name']) {
            targetSet = set;
            break;
          }
        }
        
        // If not found, search in custom sets
        if (targetSet == null) {
          for (final set in _customSets) {
            if (set.name == setData['name']) {
              targetSet = set;
              // Switch to custom tab
              if (_tabController != null) {
                _tabController!.animateTo(1);
              }
              break;
            }
          }
        }
        
        // If we found the set, show its synopsis
        if (targetSet != null) {
          // Ensure progress is loaded
          if (!_setProgress.containsKey(targetSet.id)) {
            await _loadSetProgress();
          }
          
          // Wait a bit for the UI to settle
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            _showSetSynopsis(targetSet);
          }
        }
      } catch (e) {
        // Error handling
      }
    }
  }
  
  Future<void> _initializeCharacterDatabase() async {
    try {
      await _characterDatabase.initialize();
      // Preload characters for set icons
      _preloadSetIconCharacters();
    } catch (e) {
      // Database initialization failed, will fall back to text rendering
    }
  }
  
  Future<void> _preloadSetIconCharacters() async {
    // Collect all unique icon characters from sets
    final iconCharacters = <String>{};
    
    for (final set in _characterSets) {
      final mainChar = set.icon ?? (set.characters.isNotEmpty ? set.characters.first : null);
      if (mainChar != null) {
        // Extract first character for multi-character strings
        final firstChar = mainChar.isNotEmpty ? mainChar[0] : null;
        if (firstChar != null) {
          iconCharacters.add(firstChar);
        }
      }
    }
    
    for (final set in _customSets) {
      final mainChar = set.icon ?? (set.characters.isNotEmpty ? set.characters.first : null);
      if (mainChar != null) {
        // Extract first character for multi-character strings
        final firstChar = mainChar.isNotEmpty ? mainChar[0] : null;
        if (firstChar != null) {
          iconCharacters.add(firstChar);
        }
      }
    }
    
    // Use the preview cache to preload characters
    final cache = CharacterPreviewCache();
    await cache.preloadCharacters(iconCharacters.toList());
  }
  
  Future<void> _loadExpandedFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final expandedFolders = prefs.getStringList('expanded_folders') ?? [];
    setState(() {
      _expandedFolderIds.addAll(expandedFolders);
    });
  }
  
  Future<void> _saveExpandedFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('expanded_folders', _expandedFolderIds.toList());
  }
  
  Future<void> _initializeCedict() async {
    // Production: removed debug print
    try {
      await _cedictService.initialize();
      // Production: removed debug print
    } catch (e) {
      // Production: removed debug print
    }
  }
  
  Future<void> _loadFolders() async {
    final folders = await _folderService.getFolders();
    final setFolders = <String, String>{};
    
    // Build setId -> folderId mapping
    for (final folder in folders) {
      for (final setId in folder.setIds) {
        setFolders[setId] = folder.id;
      }
    }
    
    setState(() {
      _folders = folders;
      _setFolders = setFolders;
    });
  }
  
  Future<void> _loadSetProgress() async {
    final progress = <String, double>{};
    
    // Load progress in parallel for better performance
    final futures = <Future<void>>[];
    
    // Load progress for built-in sets
    for (final set in _characterSets) {
      futures.add(
        _learningService.getSetProgress(set.characters).then((value) {
          progress[set.id] = value;
        })
      );
    }
    
    // Load progress for custom sets
    for (final set in _customSets) {
      futures.add(
        _learningService.getSetProgress(set.characters).then((value) {
          progress[set.id] = value;
        })
      );
    }
    
    // Wait for all progress loads to complete
    await Future.wait(futures);
    
    // Only update state if progress actually changed
    if (!_isProgressEqual(progress, _setProgress)) {
      setState(() {
        _setProgress = progress;
      });
    }
  }
  
  bool _isProgressEqual(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _builtInScrollController.dispose();
    _customScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void scrollToTop() {
    // Scroll the current tab to top
    if (_currentTabIndex == 0 && _builtInScrollController.hasClients) {
      _builtInScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else if (_currentTabIndex == 1 && _customScrollController.hasClients) {
      _customScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSets = List.from(_additionalSets);
      } else {
        _filteredSets = _additionalSets.where((set) {
          return set.name.toLowerCase().contains(query) ||
                 (set.description?.toLowerCase().contains(query) ?? false) ||
                 set.characters.any((char) => char.toLowerCase().contains(query));
        }).toList();
      }
    });
  }
  
  void _updateAddedSets() {
    _addedSetIds.clear();
    // Check which additional sets are already in built-in sets
    for (final additionalSet in _additionalSets) {
      // Check if any built-in set has the same ID
      for (final builtInSet in _characterSets) {
        if (builtInSet.id == additionalSet.id) {
          _addedSetIds.add(additionalSet.id);
          _selectedSetIds.add(additionalSet.id); // Also mark as selected
          break;
        }
      }
    }
  }
  
  bool _setsHaveSameCharacters(CharacterSet set1, CharacterSet set2) {
    if (set1.characters.length != set2.characters.length) return false;
    final chars1 = Set<String>.from(set1.characters);
    final chars2 = Set<String>.from(set2.characters);
    return chars1.difference(chars2).isEmpty;
  }
  
  void _toggleSetSelection(String setId) async {
    setState(() {
      if (_selectedSetIds.contains(setId)) {
        _selectedSetIds.remove(setId);
        // If this set was already added, remove it from built-in sets
        if (_addedSetIds.contains(setId)) {
          _characterSets.removeWhere((s) => s.id == setId);
          _addedSetIds.remove(setId);
        }
      } else {
        _selectedSetIds.add(setId);
        // If not already added, add it to built-in sets immediately
        if (!_addedSetIds.contains(setId)) {
          final setToAdd = _additionalSets.firstWhere((s) => s.id == setId);
          _characterSets.add(setToAdd);
          _addedSetIds.add(setId);
        }
      }
    });
    
    // Save the changes
    await _saveBuiltInSetsToStorage();
    await _loadSetProgress();
    _preloadSetIconCharacters();
  }
  
  Future<void> _addSelectedSets() async {
    final selectedSets = _additionalSets.where((set) => 
      _selectedSetIds.contains(set.id) && !_addedSetIds.contains(set.id)
    ).toList();
    
    if (selectedSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new sets to add'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Add each selected set to built-in sets
    for (final set in selectedSets) {
      _characterSets.add(set);
      _addedSetIds.add(set.id);
    }
    
    // Save updated built-in sets
    await _saveBuiltInSetsToStorage();
    
    // Close search mode
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${selectedSets.length} sets'),
        backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
            : Theme.of(context).colorScheme.primary,
      ),
    );
    
    // Reload progress and preload icons
    await _loadSetProgress();
    _preloadSetIconCharacters();
  }

  Future<void> _initializeProcessor() async {
    // Initialize with the correct database based on configuration
    await _processor.initialize(DatabaseConfig.databasePath);
  }

  Future<void> _loadCharacterSets() async {
    // Production: removed debug print
    try {
      // Only load predefined sets if they haven't been loaded yet
      if (_characterSets.isEmpty) {
        // Production: removed debug print
        // Load predefined sets from JSON
        final String jsonString = await rootBundle.loadString('assets/character_sets.json');
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        final List<dynamic> setsData = jsonData['sets'];
        // Production: removed debug print
        
        final sets = <CharacterSet>[];
        
        // Only load predefined sets from JSON (not custom ones)
        int processedCount = 0;
        int addedCount = 0;
        
        for (final setData in setsData) {
          processedCount++;
          // Production: removed debug print
          
          if (setData['isCustom'] != true) {
            // Production: removed debug print
            try {
              final isWordSet = setData['isWordSet'] ?? false;
              // Production: removed debug print
              
              // Keep the original items with definitions
              List<String> characters;
              if (isWordSet) {
                // For word sets, split by comma and trim
                final items = (setData['characters'] as String).split(',');
                characters = [];
                for (final item in items) {
                  characters.add(item.trim());
                }
              } else {
                // For character sets, split into individual characters
                characters = (setData['characters'] as String).split('');
              }
              // Production: removed debug print
              
              final set = CharacterSet(
                id: setData['id'],
                name: setData['name'],
                characters: characters,
                description: setData['description'],
                isWordSet: isWordSet,
                icon: setData['icon'],
              );
              // Production: removed debug print
              
              sets.add(set);
              addedCount++;
              // Successfully added set
            } catch (e) {
              // Production: removed debug print
              // Production: removed debug print
              // Production: removed debug print
            }
          } else {
            // Production: removed debug print
          }
        }
        
        // Production: removed debug print
        
        // Production: removed debug print
        setState(() {
          _characterSets = sets;
          _filteredSets = List.from(sets); // Initialize filtered sets
          _updateAddedSets(); // Track which sets are already added
        });
      }
      
      // Always reload custom sets from SharedPreferences
      final customSets = <CharacterSet>[];
      await _loadCustomSets(customSets);
      
      setState(() {
        _customSets = customSets;
        _isLoading = false;
      });
      
      // Load progress after sets are loaded
      await _loadSetProgress();
      
      // Preload icon characters after sets are loaded
      _preloadSetIconCharacters();
    } catch (e, stackTrace) {
      // Production: removed debug print
      // Production: removed debug print
      // Only use default sets if we haven't loaded any
      if (_characterSets.isEmpty) {
        setState(() {
          _characterSets = _setManager.getAllSets();
          _filteredSets = List.from(_characterSets);
          _isLoading = false;
          _updateAddedSets();
        });
      }
      
      // Load progress even for default sets
      await _loadSetProgress();
      
      // Try to preload even with default sets
      _preloadSetIconCharacters();
    }
  }
  
  Future<void> _loadAdditionalSets() async {
    try {
      // Load additional sets from a separate JSON file
      final String jsonString = await rootBundle.loadString('assets/additional_sets.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> setsData = jsonData['sets'] ?? [];
      
      final additionalSets = <CharacterSet>[];
      
      for (final setData in setsData) {
        try {
          final isWordSet = setData['isWordSet'] ?? false;
          
          List<String> characters;
          if (isWordSet) {
            characters = (setData['characters'] as String).split(',').map((s) => s.trim()).toList();
          } else {
            characters = (setData['characters'] as String).split('');
          }
          
          final set = CharacterSet(
            id: setData['id'],
            name: setData['name'],
            characters: characters,
            description: setData['description'],
            isWordSet: isWordSet,
            icon: setData['icon'],
          );
          
          additionalSets.add(set);
        } catch (e) {
          // Skip invalid sets
        }
      }
      
      setState(() {
        _additionalSets = additionalSets;
        _filteredSets = List.from(additionalSets);
      });
      
      // Load previously added sets
      await _loadAddedBuiltInSets();
      
      // Update which sets are already added
      _updateAddedSets();
    } catch (e) {
      // If loading fails, use empty list
      setState(() {
        _additionalSets = [];
        _filteredSets = [];
      });
    }
  }
  
  Future<void> _saveBuiltInSetsToStorage() async {
    // Save the current state of built-in sets to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final addedSetIds = <String>[];
    
    // Find which additional sets have been added to built-in
    for (final set in _characterSets) {
      // Check if this set originally came from additional sets
      if (_additionalSets.any((s) => s.id == set.id)) {
        addedSetIds.add(set.id);
      }
    }
    
    await prefs.setStringList('added_builtin_sets', addedSetIds);
  }
  
  Future<void> _loadAddedBuiltInSets() async {
    // Load previously added sets on app start
    final prefs = await SharedPreferences.getInstance();
    final addedSetIds = prefs.getStringList('added_builtin_sets') ?? [];
    
    // Add the sets from additional sets that were previously added
    for (final setId in addedSetIds) {
      final additionalSet = _additionalSets.firstWhere(
        (s) => s.id == setId,
        orElse: () => CharacterSet(id: '', name: '', characters: []),
      );
      
      if (additionalSet.id.isNotEmpty && !_characterSets.any((s) => s.id == additionalSet.id)) {
        _characterSets.add(additionalSet);
      }
    }
  }
  
  Future<void> _loadCustomSets(List<CharacterSet> customSets) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCustomSets = prefs.getStringList('custom_sets') ?? [];
    
    for (final setJson in savedCustomSets) {
      try {
        final setData = jsonDecode(setJson);
        
        // Handle characters - could be String or List
        List<String> characters;
        if (setData['characters'] is String) {
          final isWordSet = setData['isWordSet'] ?? false;
          if (isWordSet) {
            characters = setData['characters'].split(',').map((s) => s.trim()).toList();
          } else {
            characters = setData['characters'].split('').toList();
          }
        } else if (setData['characters'] is List) {
          characters = List<String>.from(setData['characters'] ?? []);
        } else {
          characters = [];
        }
        
        if (characters.isNotEmpty) {
          customSets.add(CharacterSet(
            id: setData['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: setData['name'] ?? 'Custom Set',
            characters: characters,
            description: setData['description'] ?? 'Created from incorrect answers',
            isWordSet: setData['isWordSet'] ?? false,
            color: setData['color'] != null ? int.tryParse(setData['color'].toString()) : null,
          ));
        }
      } catch (e) {
        // Production: removed debug print
      }
    }
  }
  
  Future<void> refreshCustomSets() async {
    final customSets = <CharacterSet>[];
    await _loadCustomSets(customSets);
    
    setState(() {
      _customSets = customSets;
    });
    
    // Switch to custom tab to show the new set
    if (_tabController != null) {
      _tabController!.animateTo(1);
    }
    
    // Reload progress and preload icons
    await _loadSetProgress();
    _preloadSetIconCharacters();
  }
  
  Future<void> _saveCustomSetsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final customSetJsonList = _customSets.map((set) => jsonEncode(set.toJson())).toList();
    await prefs.setStringList('custom_sets', customSetJsonList);
  }

  Future<void> _loadCharacterSet(CharacterSet set) async {
    setState(() {
      _loadingStates[set.id] = true;
    });
    
    try {
      // Validate all items in the set
      final validationResults = await _validator.validateItems(set.characters);
      final invalidItems = validationResults.where((r) => !r.isValid).toList();
      
      if (invalidItems.isNotEmpty) {
        // Show warning but allow continuing with valid items
        final validItems = validationResults
            .where((r) => r.isValid)
            .map((r) => r.item)
            .toList();
        
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Some items unavailable'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${invalidItems.length} items have missing character data:'),
                  const SizedBox(height: 8),
                  Text(
                    invalidItems.map((r) => r.item).join(', '),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text('Continue with ${validItems.length} valid items?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          
          if (proceed == true && validItems.isNotEmpty) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterListPage(
                  setName: set.name,
                  characters: validItems,
                  isWordSet: set.isWordSet,
                  isCustomSet: _customSets.contains(set),
                  setId: set.id,
                ),
              ),
            );
            // Reload progress after returning
            await _loadSetProgress();
          }
        }
      } else {
        // All items are valid
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterListPage(
                setName: set.name,
                characters: set.characters,
                isWordSet: set.isWordSet,
                isCustomSet: _customSets.contains(set),
                setId: set.id,
              ),
            ),
          );
          // Reload progress after returning
          await _loadSetProgress();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading character set: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[set.id] = false;
        });
      }
    }
  }
  
  Future<void> _showSetSynopsis(CharacterSet set) async {
    // Production: removed debug print
    // Don't validate all items - just show the dialog immediately
    // Make sure to preserve the original order
    final validItems = List<String>.from(set.characters);
    final invalidItems = <dynamic>[];
    
    // Show synopsis dialog with fade and slide-up animation
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => AlertDialog(
        title: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(set.name),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showMarkAllAsLearnedDialog(set);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.more_vert,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${set.characters.length} ${set.isWordSet ? 'words' : 'characters'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            // Close button positioned at top right of dialog content
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (set.description != null && set.description!.isNotEmpty) ...[
                  Text(
                    set.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 24),
                ],
                
                // Progress indicator
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Progress: ${((_setProgress[set.id] ?? 0.0) * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: (_setProgress[set.id] ?? 0.0) >= 1.0 
                            ? Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: (_setProgress[set.id] ?? 0.0) >= 1.0 ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Sample characters
                Text(
                  set.isWordSet ? 'Words:' : 'Characters:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: _learningService.getLearnedCharactersForSet(set.characters),
                  builder: (context, snapshot) {
                    final learnedCharacters = snapshot.data ?? [];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: set.characters.take(10).map((item) {
                        final isLearned = learnedCharacters.contains(item);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WritingPracticePage(
                                    character: item,
                                    characterSet: set.name,
                                    allCharacters: [item],
                                    isWord: set.isWordSet,
                                    mode: isLearned ? PracticeMode.testing : PracticeMode.learning,
                                    onComplete: (success) async {
                                      if (!isLearned && success) {
                                        await _learningService.markCharacterAsLearned(item);
                                      }
                                    },
                                  ),
                                ),
                              ).then((_) => _loadSetProgress());
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                    ? (isLearned 
                                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                                        : Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor1 ?? Theme.of(context).colorScheme.surfaceContainer)
                                    : (isLearned 
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                      ? (isLearned 
                                          ? Theme.of(context).colorScheme.secondary
                                          : Theme.of(context).colorScheme.secondary.withOpacity(0.3))
                                      : (isLearned 
                                          ? Colors.blue.withOpacity(0.5)
                                          : Colors.grey.withOpacity(0.3)),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: item.length >= 4 ? 14 : (item.length >= 3 ? 16 : 20),
                                  color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                      ? (isLearned 
                                          ? Theme.of(context).colorScheme.secondary
                                          : Theme.of(context).colorScheme.onSurface)
                                      : (isLearned 
                                          ? Colors.blue
                                          : Theme.of(context).colorScheme.onSurface),
                                  fontWeight: isLearned ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                if (set.characters.length > 10) ...[
                  const SizedBox(height: 8),
                  Text(
                    '... and ${set.characters.length - 10} more',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                
                if (false) ...[ // Disabled validation check for performance
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${invalidItems.length} items unavailable in database',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side - Show Groups (aligned left)
                    if (validItems.length > 10)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupsPage(
                                setName: set.name,
                                characters: validItems,
                                isWordSet: set.isWordSet,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.apps, size: 18),
                        label: const Text('Show Groups', 
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const Spacer(), // Space between left and right
                    
                    // Right side - Learn button
                    if (validItems.isNotEmpty && (_setProgress[set.id] ?? 0.0) < 1.0)
                      SizedBox(
                        width: 115,
                        child: FilledButton.icon(
                          onPressed: () async {
                            // Filter to only unlearned items using the proper logic
                            final unlearnedItems = await _learningService.getUnlearnedItems(validItems);
                            
                            if (unlearnedItems.isEmpty) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All items in this set have been learned!'),
                                ),
                              );
                              return;
                            }
                            
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WritingPracticePage(
                                  character: unlearnedItems.first,
                                  characterSet: set.name,
                                  allCharacters: unlearnedItems,
                                  isWord: set.isWordSet,
                                  mode: PracticeMode.learning,
                                  onComplete: (success) async {
                                    if (success) {
                                      if (set.isWordSet && unlearnedItems.first.length > 1) {
                                        await _learningService.markWordAsLearned(unlearnedItems.first);
                                      } else {
                                        await _learningService.markCharacterAsLearned(unlearnedItems.first);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ).then((_) => _loadSetProgress());
                          },
                          icon: const Icon(Icons.school, size: 18),
                          label: const Text('Learn',
                            style: TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                ? Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Bottom row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - View All (aligned left)
                    if (validItems.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterListPage(
                                setName: set.name,
                                characters: validItems,
                                isWordSet: set.isWordSet,
                                isCustomSet: _customSets.contains(set),
                                setId: set.id,
                              ),
                            ),
                          ).then((_) => _loadSetProgress());
                        },
                        icon: const Icon(Icons.view_list, size: 18),
                        label: const Text('View All',
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const Spacer(), // Space between left and right
                  
                  // Right side - Practice button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Practice - always available
                      if (validItems.isNotEmpty)
                        SizedBox(
                          width: 125,
                          child: FilledButton.icon(
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
                              _statsService.clearCache();
                              
                              // Get ALL fresh learned items from this set
                              final learnedCharacters = await _statsService.getLearnedCharacters();
                              final learnedWords = await _statsService.getLearnedWords();
                              final allLearned = {...learnedCharacters, ...learnedWords};
                              
                              // Filter this set's items against fresh learned data
                              final learnedItems = set.characters.where((item) => allLearned.contains(item)).toList();
                              learnedItems.shuffle(); // Randomize order
                              
                              // Close loading dialog
                              Navigator.pop(context);
                              
                              if (learnedItems.isEmpty) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No learned items in this set yet. Use "Learn" first!'),
                                  ),
                                );
                                return;
                              }
                              
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WritingPracticePage(
                                    character: learnedItems.first,
                                    characterSet: set.name,
                                    allCharacters: learnedItems,
                                    isWord: set.isWordSet,
                                    mode: PracticeMode.testing,
                                  ),
                                ),
                              ).then((_) => _loadSetProgress());
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Practice',
                              style: TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                  ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withOpacity(0.8)
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      
                    ],
                  ),
                ],
              ),
            ],
          ),
          ),
        ],
      ),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Use different curves for forward and reverse animations
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic.flipped, // Faster reverse
        );
        
        // Slide up animation
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.1), // Start slightly below
          end: Offset.zero,
        ).animate(curvedAnimation);
        
        // Fade animation with faster reverse
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn, // Faster fade out
        );
        
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_controllersInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Check if we have enough space for horizontal layout
                    final hasSpace = constraints.maxWidth > 400;
                    
                    if (hasSpace) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Character Sets',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildTabButton('Built-in', 0),
                              const SizedBox(width: 8),
                              _buildTabButton('Custom', 1),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Stack vertically on narrow screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Character Sets',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildTabButton('Built-in', 0),
                              const SizedBox(width: 8),
                              _buildTabButton('Custom', 1),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                // Built-in sets tab
                _isSearchMode ? _buildSearchableSets() : _buildSetsGrid(_characterSets, isCustomTab: false),
                // Custom sets tab
                _customSets.isEmpty && _folders.isEmpty
                    ? _buildEmptyCustomSets()
                    : _buildSetsGrid(_customSets, isCustomTab: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: _currentTabIndex == 1 
            ? _buildFloatingActionButton()
            : _currentTabIndex == 0
                ? FloatingActionButton(
                    key: ValueKey(_isSearchMode ? 'close' : 'search'),
                    onPressed: () {
                      setState(() {
                        _isSearchMode = !_isSearchMode;
                        if (!_isSearchMode) {
                          _searchController.clear();
                        }
                      });
                    },
                    backgroundColor: _isSearchMode 
                        ? Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                            : Theme.of(context).colorScheme.secondaryContainer
                        : null,
                    child: Icon(_isSearchMode ? Icons.close : Icons.search),
                  )
                : null,
      ),
    );
  }
  
  Widget? _buildFloatingActionButton() {
    if (_selectedFolderId != null) {
      // Inside a folder - only show create set button
      return FloatingActionButton.extended(
        key: const ValueKey('fab-extended'),
        onPressed: _showAddSetDialog,
        label: const Text('Create Set'),
        icon: const Icon(Icons.add),
      );
    }
    
    // At root level - show speed dial with both options
    return FloatingActionButton(
      key: const ValueKey('fab-normal'),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (bottomSheetContext) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: const Text('Create Folder'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showCreateFolderDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Create Set'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showAddSetDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
  
  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
          _tabController!.animateTo(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableSets() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search additional sets to add...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Sets grid with checkboxes
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 2;
              
              if (width > 600) crossAxisCount = 3;
              if (width > 900) crossAxisCount = 4;
              if (width > 1200) crossAxisCount = 5;
              
              final cardWidth = (width - 32 - (crossAxisCount - 1) * 16) / crossAxisCount;
              if (cardWidth > 200) {
                crossAxisCount = ((width - 32) / (200 + 16)).floor();
              }
              
              return CustomScrollView(
                controller: _builtInScrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final set = _filteredSets[index];
                          final isSelected = _selectedSetIds.contains(set.id);
                          final isAdded = _addedSetIds.contains(set.id);
                          
                          return Stack(
                            children: [
                              _CharacterSetSquareCard(
                                set: set,
                                isLoading: false,
                                isCustom: false,
                                progress: _setProgress[set.id] ?? 0.0,
                                onTap: () => _toggleSetSelection(set.id),
                                onLongPress: null,
                                onMenuTap: null,
                              ),
                              // Checkbox overlay
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _toggleSetSelection(set.id),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: isSelected 
                                          ? Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                                              : Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                    ),
                                    child: isSelected 
                                        ? Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        childCount: _filteredSets.length,
                      ),
                    ),
                  ),
                  // "More coming soon" message
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Center(
                        child: Text(
                          'More coming soon...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSetsGrid(List<CharacterSet> sets, {bool isCustomTab = false}) {
    // Production: removed debug print
    if (!isCustomTab) {
      // Built-in sets - show as normal grid
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive grid columns based on screen width
          // Target card size: 150-200 logical pixels
          final width = constraints.maxWidth;
          int crossAxisCount = 2; // Default for phones
          
          if (width > 600) {
            // Tablet in portrait or phone in landscape
            crossAxisCount = 3;
          }
          if (width > 900) {
            // Tablet in landscape
            crossAxisCount = 4;
          }
          if (width > 1200) {
            // Large tablet or desktop
            crossAxisCount = 5;
          }
          
          // Calculate actual card size to ensure cards don't get too large
          final cardWidth = (width - 32 - (crossAxisCount - 1) * 16) / crossAxisCount;
          final maxCardSize = 200.0; // Maximum card size
          
          // If cards would be too large, increase column count
          if (cardWidth > maxCardSize) {
            crossAxisCount = ((width - 32) / (maxCardSize + 16)).floor();
          }
          
          return GridView.builder(
            controller: _builtInScrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              final isLoading = _loadingStates[set.id] ?? false;
              
              // Add staggered animation delay based on index
              final animationDelay = index * 50; // 50ms between each card
              
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + animationDelay),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _CharacterSetSquareCard(
                  set: set,
                  isLoading: isLoading,
                  isCustom: false,
                  progress: _setProgress[set.id] ?? 0.0,
                  onTap: isLoading ? null : () => _showSetSynopsis(set),
                  onLongPress: null,
                  onMenuTap: () => _showSetMenu(set),
                ),
              );
            },
          );
        },
      );
    }
    
    // Custom sets tab - show folders and unfiled sets
    if (_selectedFolderId != null) {
      // Inside a folder - show back button and sets in this folder
      final folder = _folders.firstWhere((f) => f.id == _selectedFolderId);
      final folderSets = sets.where((s) => folder.setIds.contains(s.id)).toList();
      
      return Column(
        children: [
          // Folder header with back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedFolderId = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  folder.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showFolderMenu(folder),
                ),
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.2)
                : null,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Same responsive logic for folder view
                final width = constraints.maxWidth;
                int crossAxisCount = 2;
                
                if (width > 600) crossAxisCount = 3;
                if (width > 900) crossAxisCount = 4;
                if (width > 1200) crossAxisCount = 5;
                
                final cardWidth = (width - 32 - (crossAxisCount - 1) * 16) / crossAxisCount;
                if (cardWidth > 200) {
                  crossAxisCount = ((width - 32) / 216).floor();
                }
                
                return GridView.builder(
                  controller: _customScrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: folderSets.length,
                  itemBuilder: (context, index) {
                final set = folderSets[index];
                final isLoading = _loadingStates[set.id] ?? false;
                
                return _CharacterSetSquareCard(
                  set: set,
                  isLoading: isLoading,
                  isCustom: true,
                  progress: _setProgress[set.id] ?? 0.0,
                  onTap: isLoading ? null : () => _showSetSynopsis(set),
                  onLongPress: () => _showDeleteDialog(set),
                  onMenuTap: () => _showSetMenu(set),
                );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
    
    // Root level - show folders and unfiled sets
    final unfiledSets = sets.where((s) => !_setFolders.containsKey(s.id)).toList();
    
    // Build a list of items to display (folders with their expanded contents, then unfiled sets)
    final List<dynamic> displayItems = [];
    
    for (final folder in _folders) {
      displayItems.add(folder);
      
      // If folder is expanded, add its sets
      if (_expandedFolderIds.contains(folder.id)) {
        final folderSets = sets.where((s) => folder.setIds.contains(s.id)).toList();
        displayItems.addAll(folderSets);
      }
    }
    
    // Add unfiled sets at the end
    displayItems.addAll(unfiledSets);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Same responsive logic
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        
        if (width > 600) crossAxisCount = 3;
        if (width > 900) crossAxisCount = 4;
        if (width > 1200) crossAxisCount = 5;
        
        final cardWidth = (width - 32 - (crossAxisCount - 1) * 16) / crossAxisCount;
        if (cardWidth > 200) {
          crossAxisCount = ((width - 32) / 216).floor();
        }
        
        return GridView.builder(
          controller: _customScrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        
        if (item is SetFolder) {
          // Show folder card
          final setCount = item.setIds.length;
          
          return _FolderCard(
            folder: item,
            setCount: setCount,
            isExpanded: _expandedFolderIds.contains(item.id),
            onTap: () {
              setState(() {
                _selectedFolderId = item.id;
              });
            },
            onLongPress: () => _showDeleteFolderDialog(item),
            onExpandToggle: () {
              setState(() {
                if (_expandedFolderIds.contains(item.id)) {
                  _expandedFolderIds.remove(item.id);
                } else {
                  _expandedFolderIds.add(item.id);
                }
              });
              _saveExpandedFolders();
            },
          );
        } else if (item is CharacterSet) {
          // Show character set card
          final isLoading = _loadingStates[item.id] ?? false;
          
          // Check if this set belongs to an expanded folder
          final isInExpandedFolder = _setFolders.containsKey(item.id) && 
              _expandedFolderIds.contains(_setFolders[item.id]);
          
          return Container(
            // Add a subtle left border for sets in expanded folders
            decoration: isInExpandedFolder ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
            ) : null,
            child: _CharacterSetSquareCard(
              set: item,
              isLoading: isLoading,
              isCustom: true,
              progress: _setProgress[item.id] ?? 0.0,
              onTap: isLoading ? null : () => _showSetSynopsis(item),
              onLongPress: () => _showDeleteDialog(item),
              onMenuTap: () => _showSetMenu(item),
            ),
          );
        }
        
        return const SizedBox.shrink();
          },
        );
      },
    );
  }

  
  Future<void> _showSetMenu(CharacterSet set) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mark all as learned option (available for all sets)
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Mark All as Learned'),
            onTap: () {
              Navigator.pop(context);
              _showMarkAllAsLearnedDialog(set);
            },
          ),
          // Show remove option for built-in sets that were added from additional sets
          if (!_customSets.contains(set) && _additionalSets.any((s) => s.id == set.id)) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.orange),
              title: const Text('Remove from Built-in', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _removeFromBuiltIn(set);
              },
            ),
          ],
          if (_customSets.contains(set)) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameSetDialog(set);
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Change Color'),
              onTap: () {
                Navigator.pop(context);
                _showColorPickerDialog(set);
              },
            ),
            if (_folders.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Move to Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveToFolderDialog(set);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(set);
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _showMarkAllAsLearnedDialog(CharacterSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Learned'),
        content: Text(
          'Do you really want to mark all ${set.characters.length} ${set.isWordSet ? "words" : "characters"} in "${set.name}" as learned?\n\nYou will not be able to undo this action.',
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
        // Mark all items in the set as learned
        for (final item in set.characters) {
          if (set.isWordSet && item.length > 1) {
            await _learningService.markWordAsLearned(item);
          } else {
            await _learningService.markCharacterAsLearned(item);
          }
        }
        
        // Clear caches to ensure fresh data
        _learningService.clearCache();
        _statsService.clearCache();
        
        // Reload progress
        await _loadSetProgress();
        
        // Close progress dialog
        Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Marked all items in "${set.name}" as learned'),
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
  
  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter folder name',
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
              if (controller.text.isNotEmpty) {
                await _folderService.createFolder(controller.text);
                await _loadFolders();
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showFolderMenu(SetFolder folder) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Folder'),
            onTap: () {
              Navigator.pop(context);
              _showRenameFolderDialog(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteFolderDialog(folder);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showRenameFolderDialog(SetFolder folder) async {
    final controller = TextEditingController(text: folder.name);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
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
              if (controller.text.isNotEmpty && controller.text != folder.name) {
                final updatedFolder = SetFolder(
                  id: folder.id,
                  name: controller.text,
                  setIds: folder.setIds,
                  createdAt: folder.createdAt,
                );
                await _folderService.updateFolder(updatedFolder);
                await _loadFolders();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showDeleteFolderDialog(SetFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"? Sets will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _folderService.deleteFolder(folder.id);
      if (_selectedFolderId == folder.id) {
        setState(() {
          _selectedFolderId = null;
        });
      }
      await _loadFolders();
    }
  }
  
  Future<void> _showRenameSetDialog(CharacterSet set) async {
    final controller = TextEditingController(text: set.name);
    
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
              if (controller.text.isNotEmpty && controller.text != set.name) {
                // Update custom set name in storage
                final prefs = await SharedPreferences.getInstance();
                final customSets = prefs.getStringList('custom_sets') ?? [];
                
                for (int i = 0; i < customSets.length; i++) {
                  try {
                    final setData = jsonDecode(customSets[i]);
                    if (setData['id'] == set.id) {
                      setData['name'] = controller.text;
                      customSets[i] = jsonEncode(setData);
                      break;
                    }
                  } catch (e) {
                    // Production: removed debug print
                  }
                }
                
                await prefs.setStringList('custom_sets', customSets);
                Navigator.pop(context);
                
                // Update the set in memory instead of reloading
                setState(() {
                  final index = _customSets.indexWhere((s) => s.id == set.id);
                  if (index != -1) {
                    _customSets[index] = CharacterSet(
                      id: set.id,
                      name: controller.text,
                      characters: set.characters,
                      description: set.description,
                      isWordSet: set.isWordSet,
                      color: set.color,
                    );
                  }
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showColorPickerDialog(CharacterSet set) async {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return InkWell(
                onTap: () async {
                  // Update custom set color in storage
                  final prefs = await SharedPreferences.getInstance();
                  final customSets = prefs.getStringList('custom_sets') ?? [];
                  
                  for (int i = 0; i < customSets.length; i++) {
                    try {
                      final setData = jsonDecode(customSets[i]);
                      if (setData['id'] == set.id) {
                        setData['color'] = color.value.toString();
                        customSets[i] = jsonEncode(setData);
                        break;
                      }
                    } catch (e) {
                      // Production: removed debug print
                    }
                  }
                  
                  await prefs.setStringList('custom_sets', customSets);
                  Navigator.pop(context);
                  
                  // Update the set in memory instead of reloading
                  setState(() {
                    final index = _customSets.indexWhere((s) => s.id == set.id);
                    if (index != -1) {
                      _customSets[index] = CharacterSet(
                        id: set.id,
                        name: set.name,
                        characters: set.characters,
                        description: set.description,
                        isWordSet: set.isWordSet,
                        color: color.value,
                      );
                    }
                  });
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showMoveToFolderDialog(CharacterSet set) async {
    final currentFolderId = _setFolders[set.id];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('No Folder'),
              value: null,
              groupValue: currentFolderId,
              onChanged: (value) async {
                await _folderService.moveSetToFolder(set.id, null);
                await _loadFolders();
                Navigator.pop(context);
              },
            ),
            ..._folders.map((folder) => RadioListTile<String?>(
              title: Text(folder.name),
              value: folder.id,
              groupValue: currentFolderId,
              onChanged: (value) async {
                await _folderService.moveSetToFolder(set.id, value);
                await _loadFolders();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCustomSets() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Custom Sets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own practice sets with specific characters or words',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddSetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Set'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSetDialog() async {
    final controller = TextEditingController();
    final nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Set'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Set Name',
                    hintText: 'e.g., My Practice Set',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Characters/Words',
                    hintText: 'e.g., 我，你，他 or 你好世界',
                    helperText: 'Use commas for words.',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && nameController.text.isNotEmpty) {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Validate the input
                final validation = await _validator.validateSetString(controller.text);
                
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                
                if (validation.isValid) {
                  final newSet = await _setManager.createSetFromString(
                    controller.text,
                    nameController.text,
                  );
                  
                  if (mounted) {
                    setState(() {
                      _customSets.add(newSet);
                    });
                  }
                  
                  // Save to SharedPreferences
                  await _saveCustomSetsToStorage();
                  
                  // If we're in a folder, add the set to it
                  if (_selectedFolderId != null) {
                    await _folderService.moveSetToFolder(newSet.id, _selectedFolderId);
                    await _loadFolders();
                  }
                  
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                  }
                } else {
                  // Show validation error
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Some Characters Unavailable'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The following characters are not in the MakeMeAHanzi database:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ...validation.missingCharacters.map((char) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        char,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<ValidationResult>(
                                        future: _validator.validateItem(char),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data!.characterDetails != null) {
                                            final details = snapshot.data!.characterDetails![char] ?? '';
                                            return Text(
                                              details,
                                              style: const TextStyle(fontSize: 12),
                                            );
                                          }
                                          return const Text(
                                            'Character not in database',
                                            style: TextStyle(fontSize: 12),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                              if (validation.validItems.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Valid items that can be used:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: validation.validItems.map((item) => Chip(
                                    label: Text(item),
                                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        actions: [
                          if (validation.validItems.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                // Create set with only valid items
                                final newSet = await _setManager.createSetFromString(
                                  validation.validItems.join(','),
                                  nameController.text,
                                );
                                if (mounted) {
                                  setState(() {
                                    _customSets.add(newSet);
                                  });
                                }
                                
                                // Save to SharedPreferences
                                await _saveCustomSetsToStorage();
                                
                                // If we're in a folder, add the set to it
                                if (_selectedFolderId != null) {
                                  await _folderService.moveSetToFolder(newSet.id, _selectedFolderId);
                                  await _loadFolders();
                                }
                                
                                if (mounted) {
                                  Navigator.pop(context); // Close original dialog
                                }
                              },
                              child: const Text('Use Valid Items Only'),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeFromBuiltIn(CharacterSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Built-in'),
        content: Text('Remove "${set.name}" from built-in sets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _characterSets.removeWhere((s) => s.id == set.id);
        _addedSetIds.remove(set.id);
        _selectedSetIds.remove(set.id);
      });
      
      await _saveBuiltInSetsToStorage();
      await _loadSetProgress();
      _preloadSetIconCharacters();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${set.name}" from built-in sets'),
        ),
      );
    }
  }
  
  Future<void> _showDeleteDialog(CharacterSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Set'),
        content: Text('Are you sure you want to delete "${set.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _deleteCustomSet(set);
    }
  }
  
  Future<void> _deleteCustomSet(CharacterSet set) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCustomSets = prefs.getStringList('custom_sets') ?? [];
    
    // Remove the set with matching ID
    savedCustomSets.removeWhere((setJson) {
      try {
        final setData = jsonDecode(setJson);
        return setData['id'] == set.id;
      } catch (e) {
        return false;
      }
    });
    
    await prefs.setStringList('custom_sets', savedCustomSets);
    
    setState(() {
      _customSets.remove(set);
      
      // Find corresponding built-in set and update tracking
      for (final builtInSet in _characterSets) {
        if (_setsHaveSameCharacters(builtInSet, set)) {
          _addedSetIds.remove(builtInSet.id);
          _selectedSetIds.remove(builtInSet.id);
          break;
        }
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${set.name}"'),
        ),
      );
    }
  }
  
  Future<void> _showImportDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Characters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how to import characters:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Import from text option
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showTextImportDialog();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Import from Text',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Paste Chinese text to create a set',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Import from file option
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File import coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.file_copy,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Import from File',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Import from CSV or text files',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showTextImportDialog() async {
    final controller = TextEditingController();
    final nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Text'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Set Name',
                  hintText: 'e.g. My Vocabulary',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Chinese Text',
                  hintText: 'Paste or type Chinese text here...',
                  helperText: 'All Chinese characters will be extracted',
                  border: const OutlineInputBorder(),
                  counterText: '${controller.text.length} characters',
                ),
                onChanged: (text) {
                  setState(() {}); // Update character count
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && nameController.text.isNotEmpty) {
                // Extract Chinese characters using regex
                final chineseChars = RegExp(r'[\u4e00-\u9fa5]+')
                    .allMatches(controller.text)
                    .map((m) => m.group(0)!)
                    .join();
                
                if (chineseChars.isNotEmpty) {
                  // Create the set using existing method
                  Navigator.pop(context);
                  
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  // Validate and create set
                  final validation = await _validator.validateSetString(chineseChars);
                  
                  if (!mounted) return;
                  Navigator.pop(context); // Close loading
                  
                  if (validation.isValid) {
                    final newSet = await _setManager.createSetFromString(
                      chineseChars,
                      nameController.text,
                    );
                    
                    if (mounted) {
                      setState(() {
                        _customSets.add(newSet);
                      });
                    }
                    
                    await _saveCustomSetsToStorage();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Created set "${nameController.text}" with ${newSet.characters.length} characters'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Show validation errors (using existing validation dialog logic)
                    _showValidationErrorDialog(validation, nameController.text, chineseChars);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No Chinese characters found in the text'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showValidationErrorDialog(ValidationSummary validation, String setName, String characters) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Some Characters Unavailable'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following characters are not in the MakeMeAHanzi database:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...validation.missingCharacters.map((char) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    char,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
              if (validation.validItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Valid characters that can be imported:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: validation.validItems.map((item) => Chip(
                    label: Text(item),
                    backgroundColor: Colors.green.withOpacity(0.2),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (validation.validItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final newSet = await _setManager.createSetFromString(
                  validation.validItems.join(''),
                  setName,
                );
                
                if (mounted) {
                  setState(() {
                    _customSets.add(newSet);
                  });
                }
                
                await _saveCustomSetsToStorage();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created set "$setName" with ${newSet.characters.length} characters'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Import Valid Characters'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final SetFolder folder;
  final int setCount;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onExpandToggle;

  const _FolderCard({
    required this.folder,
    required this.setCount,
    required this.isExpanded,
    this.onTap,
    this.onLongPress,
    this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
            ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1)
            : null,
        highlightColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
            ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.05)
            : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Icon(
                              isExpanded ? Icons.folder_open : Icons.folder,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        // Expand/Collapse button
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onExpandToggle,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            folder.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$setCount ${setCount == 1 ? 'set' : 'sets'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
}

class _CharacterSetSquareCard extends StatelessWidget {
  final CharacterSet set;
  final bool isLoading;
  final bool isCustom;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuTap;

  const _CharacterSetSquareCard({
    required this.set,
    this.isLoading = false,
    this.isCustom = false,
    this.progress = 0.0,
    this.onTap,
    this.onLongPress,
    this.onMenuTap,
  });
  
  // Color palette for character sets
  static const List<Color> _colorPalette = [
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
    Color(0xFF1ABC9C), // Turquoise
    Color(0xFFE67E22), // Dark Orange
    Color(0xFF16A085), // Dark Turquoise
    Color(0xFF8E44AD), // Dark Purple
    Color(0xFF27AE60), // Dark Green
  ];
  
  Color _getColorForSet() {
    // Use custom color if available
    if (set.color != null) {
      return Color(set.color!);
    }
    
    // Specific colors for HSK sets to ensure uniqueness
    switch (set.id) {
      case 'hsk1':
        return const Color(0xFFE74C3C); // Red
      case 'hsk2':
        return const Color(0xFF3498DB); // Blue
      case 'hsk3':
        return const Color(0xFF2ECC71); // Green
      case 'hsk4':
        return const Color(0xFFF39C12); // Orange
      case 'hsk5':
        return const Color(0xFF9B59B6); // Purple
      case 'hsk6':
        return const Color(0xFF1ABC9C); // Turquoise
      default:
        // For other sets, use hash-based selection
        final hash = set.id.hashCode.abs();
        return _colorPalette[hash % _colorPalette.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the main character to display - use icon if available
    final mainCharacter = set.icon ?? (set.characters.isNotEmpty ? set.characters.first : '?');
    // For multi-character items, extract the first character for SVG rendering
    final firstChar = mainCharacter.isNotEmpty ? mainCharacter[0] : '?';
    final setColor = _getColorForSet();
    
    // Duotone theme adjustments
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDuotone = duotoneExt?.isDuotoneTheme == true;
    
    // Use theme-aware colors
    final backgroundColor = isDuotone 
        ? duotoneExt?.duotoneColor1 ?? Theme.of(context).colorScheme.surfaceContainer
        : setColor;  // Always use set color for non-duotone themes
    
    final characterColor = isDuotone 
        ? duotoneExt?.duotoneColor2 ?? Theme.of(context).colorScheme.primary
        : Colors.white.withValues(alpha: 0.9);
    
    final textColor = isDuotone 
        ? duotoneExt?.duotoneColor2 ?? Theme.of(context).colorScheme.onSurface
        : Colors.white;
    
    final subtextColor = isDuotone 
        ? (duotoneExt?.duotoneColor2 ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.7) 
        : Colors.white.withValues(alpha: 0.7);
    
    return Card(
      elevation: 3,
      color: backgroundColor,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
            ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1)
            : null,
        highlightColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
            ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.05)
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate sizes based on container size
                  final containerSize = constraints.maxWidth;
                  final padding = containerSize * 0.08; // Dynamic padding
                  
                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Fixed size character container - no background
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Container(
                              width: containerSize * 0.6,
                              height: containerSize * 0.6,
                              alignment: Alignment.center,
                              child: CharacterPreview(
                                character: firstChar,
                                color: characterColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Fixed space for text
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  set.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${set.characters.length} ${set.isWordSet ? 'words' : 'characters'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: subtextColor,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 3,
                                width: containerSize * 0.6,
                                decoration: BoxDecoration(
                                  color: subtextColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? 
                                    Theme.of(context).colorScheme.primary
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Loading indicator
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              // Custom indicator removed - custom sets are now distinguished by inverted colors
              // Learned indicator
              if (progress >= 1.0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? 
                             Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor1 ?? 
                             Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              // Menu button for custom sets
              if (isCustom && onMenuTap != null)
                Positioned(
                  top: 8,
                  right: progress >= 1.0 ? 36 : 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onMenuTap,
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? (Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.2)
                          : null,
                      highlightColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.1)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: isDuotone ? Theme.of(context).colorScheme.onSurface : Colors.white,
                        ),
                      ),
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