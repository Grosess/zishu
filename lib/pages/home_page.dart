import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/statistics_service.dart';
import '../services/local_storage_service.dart';
import '../services/character_database.dart';
import '../services/character_dictionary.dart';
import '../services/profile_service.dart';
import '../services/learning_service.dart';
import 'writing_practice_page.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show DuotoneThemeExtension;
import 'help_page.dart';
import 'character_list_page.dart';
import 'groups_page.dart';
import '../services/character_set_manager.dart';
import 'mark_as_learned_page.dart';
import '../services/cedict_service.dart';
import '../widgets/character_preview.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const HomePage({super.key, this.onNavigateToTab});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with RouteAware {
  final StatisticsService _statsService = StatisticsService();
  final LocalStorageService _storageService = LocalStorageService();
  final CharacterDatabase _database = CharacterDatabase();
  final CharacterDictionary _dictionary = CharacterDictionary();
  final ProfileService _profileService = ProfileService();
  final ScrollController _scrollController = ScrollController();
  final LearningService _learningService = LearningService();
  
  late SharedPreferences _prefs;
  
  // Goal data
  int _characterGoal = 100;
  DateTime? _goalDeadline;
  int _currentProgress = 0;
  double _progressPercentage = 0.0;
  int _paceOffset = 0; // Positive = ahead of pace, negative = behind
  
  // Recent sets
  List<Map<String, dynamic>> _recentSets = [];
  
  // All learned items for endless practice
  List<String> _allLearnedItems = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listen to profile changes
    _profileService.addListener(_onProfileChanged);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer to get notified when page becomes visible
    final route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      // This will help us know when we return to this page
    }
  }
  
  @override
  void dispose() {
    _profileService.removeListener(_onProfileChanged);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        // Profile updated
      });
    }
  }

  void refreshData() {
    _loadData();
  }
  
  // Called when page gains focus
  void onPageVisible() {
    // Always refresh data when page becomes visible
    // This ensures progress is up-to-date when returning from practice
    _loadData();
  }
  
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadData() async {
    // Load all data concurrently for better performance
    final futures = <Future>[
      SharedPreferences.getInstance(),
      _database.initialize(),
      _statsService.getLearnedCharacters(),
      _statsService.getLearnedWords(),
    ];
    
    final results = await Future.wait(futures);
    _prefs = results[0] as SharedPreferences;
    final learnedCharacters = results[2] as Set<String>;
    final learnedWords = results[3] as Set<String>;
    
    // Check if this is the first time launching the app
    final isFirstLaunch = _prefs.getBool('has_launched_before') != true;
    if (isFirstLaunch && mounted) {
      // Mark that the app has been launched
      await _prefs.setBool('has_launched_before', true);
      
      // Start tutorial immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTutorial();
        }
      });
    }
    
    // Load goal data
    final loadedGoal = _prefs.getInt('character_goal') ?? 100;
    // Ensure goal doesn't exceed 5 digits
    _characterGoal = loadedGoal > 99999 ? 99999 : loadedGoal;
    
    // Load deadline
    final deadlineString = _prefs.getString('goal_deadline');
    if (deadlineString != null) {
      _goalDeadline = DateTime.parse(deadlineString);
    } else {
      _goalDeadline = DateTime.now().add(const Duration(days: 30));
    }
    
    // Calculate progress
    _currentProgress = learnedCharacters.length + learnedWords.length;
    _progressPercentage = (_currentProgress / _characterGoal).clamp(0.0, 1.0);
    
    // Calculate pace
    _calculatePace();
    
    // Combine all learned items
    _allLearnedItems = [...learnedCharacters, ...learnedWords];
    
    // Load recent practice sets asynchronously
    _loadRecentSets().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _profileService.firstName;
    
    if (hour < 12) {
      return 'Good morning, $name';
    } else if (hour < 17) {
      return 'Good afternoon, $name';
    } else {
      return 'Good evening, $name';
    }
  }
  
  void _calculatePace() {
    if (_goalDeadline == null) return;
    
    final now = DateTime.now();
    // Get the start date (stored or 30 days before deadline)
    final startDateString = _prefs.getString('goal_start_date');
    final startDate = startDateString != null 
        ? DateTime.parse(startDateString)
        : _goalDeadline!.subtract(const Duration(days: 30));
    
    // Save start date if not stored
    if (startDateString == null) {
      _prefs.setString('goal_start_date', startDate.toIso8601String());
    }
    
    final totalDays = _goalDeadline!.difference(startDate).inDays;
    final daysElapsed = now.difference(startDate).inDays;
    
    if (daysElapsed <= 0 || totalDays <= 0) {
      _paceOffset = 0;
      return;
    }
    
    // Calculate expected progress
    final progressRate = daysElapsed / totalDays;
    final expectedProgress = (_characterGoal * progressRate).round();
    
    // Calculate pace offset
    _paceOffset = _currentProgress - expectedProgress;
  }

  Future<void> _loadRecentSets() async {
    // Load character sets from JSON
    try {
      final String jsonString = await rootBundle.loadString('assets/character_sets.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> setsData = jsonData['sets'];
      
      // Get practice history to determine recent sets
      final practiceHistory = _prefs.getStringList('recent_practice_sets') ?? [];
      
      _recentSets = [];
      
      // Create a map of available sets
      final Map<String, Map<String, dynamic>> availableSets = {};
      for (final setData in setsData) {
        final isWordSet = setData['isWordSet'] ?? false;
        List<String> characters;
        
        // Handle characters - could be a String or List
        if (setData['characters'] is String) {
          if (isWordSet) {
            final items = (setData['characters'] as String).split(',');
            characters = [];
            for (final item in items) {
              characters.add(item.trim());
            }
          } else {
            characters = (setData['characters'] as String).split('');
          }
        } else if (setData['characters'] is List) {
          characters = List<String>.from(setData['characters']);
        } else {
          characters = [];
        }
        
        availableSets[setData['name']] = {
          'name': setData['name'],
          'type': isWordSet ? 'word' : 'character',
          'count': characters.length,
          'items': characters,
        };
      }
      
      // Add recent sets
      for (final setName in practiceHistory.take(5)) {
        if (availableSets.containsKey(setName)) {
          _recentSets.add(availableSets[setName]!);
        }
      }
      
      // If less than 5 recent sets, add some default ones
      if (_recentSets.length < 5) {
        final defaultSets = ['Common Radicals', 'Basic Characters', 'HSK 1'];
        for (final setName in defaultSets) {
          if (_recentSets.length >= 5) break;
          if (availableSets.containsKey(setName) && 
              !_recentSets.any((s) => s['name'] == setName)) {
            _recentSets.add(availableSets[setName]!);
          }
        }
      }
    } catch (e) {
      // Error logging handled by Flutter framework
    }
  }

  void _startEndlessPractice() async {
    // Show loading indicator while refreshing
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
    
    // Force refresh ALL learned items from database
    final learnedCharacters = await _statsService.getLearnedCharacters();
    final learnedWords = await _statsService.getLearnedWords();
    _allLearnedItems = [...learnedCharacters, ...learnedWords];
    
    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }
    
    if (!mounted) return;
    
    if (_allLearnedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No characters learned yet. Practice some sets first!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    
    // Don't pass items, let EndlessPracticePage fetch fresh data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EndlessPracticePage(
          items: [], // Empty list to force fresh data fetch
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    ).then((_) async {
      // Refresh data when returning from endless practice
      await _loadData();
      // Force UI update
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Color palette for recent sets
  static const List<Color> _setColors = [
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
  ];
  
  Color _getColorForSet(int index) {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // In duotone mode, use variations of the foreground color
      final foregroundColor = duotoneTheme!.duotoneColor2!;
      final hslColor = HSLColor.fromColor(foregroundColor);
      
      // Create different lightness levels for variety
      final lightnessLevels = [0.3, 0.4, 0.5, 0.6, 0.7];
      final adjustedLightness = lightnessLevels[index % lightnessLevels.length];
      
      return hslColor.withLightness(adjustedLightness.clamp(0.0, 1.0)).toColor();
    } else {
      return _setColors[index % _setColors.length];
    }
  }
  
  LinearGradient? _buildCardGradient() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      final foregroundColor = duotoneTheme!.duotoneColor2!;
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          foregroundColor.withOpacity(0.05),
          foregroundColor.withOpacity(0.02),
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
          Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ],
      );
    }
  }
  
  Color? _getCardBackgroundColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // Use the background color from duotone theme
      return duotoneTheme!.duotoneColor1;
    } else {
      return null; // Use default from theme
    }
  }
  
  Color _getCardBorderColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      return duotoneTheme!.duotoneColor2!.withOpacity(0.3);
    } else {
      return Theme.of(context).colorScheme.primary.withOpacity(0.2);
    }
  }
  
  double _getGoalFontSize(int goal) {
    // Base font size is 56
    // Reduce size based on number of digits
    if (goal < 100) {
      return 50; // 1-2 digits
    } else if (goal < 1000) {
      return 44; // 3 digits
    } else if (goal < 10000) {
      return 38; // 4 digits
    } else {
      return 34; // 5 digits (max)
    }
  }

  void _practiceSet(Map<String, dynamic> set) async {
    // Update recent practice sets
    final practiceHistory = _prefs.getStringList('recent_practice_sets') ?? [];
    practiceHistory.remove(set['name']); // Remove if exists
    practiceHistory.insert(0, set['name']); // Add to front
    await _prefs.setStringList('recent_practice_sets', practiceHistory.take(10).toList());
    
    // Create a complete CharacterSet object like in sets page
    final characterSet = CharacterSet(
      id: set['name'].toString().toLowerCase().replaceAll(' ', '_'),
      name: set['name'],
      characters: List<String>.from(set['items']),
      description: '',
      isWordSet: set['type'] == 'word',
    );
    
    // Show the synopsis dialog directly (same as sets page)
    _showSetSynopsis(characterSet);
  }
  
  Future<void> _showSetSynopsis(CharacterSet set) async {
    // Don't validate all items - just show the dialog immediately
    // Make sure to preserve the original order
    final validItems = List<String>.from(set.characters);
    final invalidItems = <dynamic>[];
    
    // Get progress for this set
    double progress = 0.0;
    if (set.characters.isNotEmpty) {
      final learnedItems = await _learningService.getLearnedCharactersForSet(set.characters);
      progress = learnedItems.length / set.characters.length;
    }
    
    // Show synopsis dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set.name),
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
                      'Progress: ${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: progress >= 1.0 
                            ? Theme.of(context).extension<DuotoneThemeExtension>()?.duotoneColor2 ?? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: progress >= 1.0 ? FontWeight.bold : null,
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
                              ).then((_) => _loadData());
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
                    if (validItems.isNotEmpty && progress < 1.0)
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
                            ).then((_) => _loadData());
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
                                isCustomSet: false,
                                setId: set.id,
                              ),
                            ),
                          ).then((_) => _loadData());
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
                              ).then((_) => _loadData());
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
    );
  }
  
  /*
  // This method is no longer used - we navigate to the sets page instead
  void _showSetSynopsis_REMOVED(Map<String, dynamic> set) {
    final validItems = List<String>.from(set['items']);
    final isWordSet = set['type'] == 'word';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set['name']),
                const SizedBox(height: 4),
                Text(
                  '${validItems.length} ${isWordSet ? 'words' : 'characters'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
                // Sample characters
                Text(
                  isWordSet ? 'Words:' : 'Characters:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: _learningService.getLearnedCharactersForSet(validItems),
                  builder: (context, snapshot) {
                    final learnedCharacters = snapshot.data ?? [];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: validItems.take(10).map((item) {
                        final isLearned = learnedCharacters.contains(item);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isLearned 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLearned
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isLearned
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : null,
                                ),
                              ),
                              if (isLearned) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                if (validItems.length > 10) ...[
                  const SizedBox(height: 8),
                  Text(
                    '... and ${validItems.length - 10} more',
                    style: Theme.of(context).textTheme.bodySmall,
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
                  children: [
                    // View All button
                    if (validItems.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterListPage(
                                setName: set['name'],
                                characters: validItems,
                                isWordSet: isWordSet,
                                isCustomSet: false,
                                setId: set['id'] ?? set['name'],
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.view_list, size: 18),
                        label: const Text('View All'),
                      ),
                    const Spacer(),
                    // Learn button
                    if (validItems.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () async {
                          // Filter to only unlearned items
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
                                characterSet: set['name'],
                                allCharacters: unlearnedItems,
                                isWord: isWordSet,
                                mode: PracticeMode.learning,
                                onComplete: (success) async {
                                  if (success) {
                                    if (isWordSet && unlearnedItems.first.length > 1) {
                                      await _learningService.markWordAsLearned(unlearnedItems.first);
                                    } else {
                                      await _learningService.markCharacterAsLearned(unlearnedItems.first);
                                    }
                                  }
                                },
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.school, size: 18),
                        label: const Text('Learn'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Bottom row
                Row(
                  children: [
                    const Spacer(),
                    // Practice button
                    if (validItems.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WritingPracticePage(
                                character: validItems[0],
                                characterSet: set['name'],
                                allCharacters: validItems,
                                isWord: isWordSet,
                                mode: PracticeMode.testing,
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Practice'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */

  Future<void> _launchFeedbackForm() async {
    final Uri url = Uri.parse('https://forms.gle/5R1saZ3v3ia1R1uN7');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open feedback form'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    final goalText = '${months[_goalDeadline!.month - 1]} ${_goalDeadline!.day}';
    
    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Greeting section without duplicate profile picture
          if (_profileService.firstName.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  'Keep up the great work!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Goal visualization section with glassmorphic effect
          GestureDetector(
            onTap: () {
              // Navigate to progress tab
              widget.onNavigateToTab?.call(2);
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _buildCardGradient(),
                color: _getCardBackgroundColor(),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _getCardBorderColor(),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Goal text on the left with animated gradient
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                              ? [
                                  Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!, // Green for rice paper goal
                                  Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!,
                                ]
                              : [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                          ).createShader(bounds),
                          child: Text(
                            _characterGoal.toString(),
                            style: TextStyle(
                              fontSize: _getGoalFontSize(_characterGoal),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'characters by',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goalText,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Futuristic circular progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 170,
                        width: 170,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(170, 170),
                              painter: CleanProgressPainter(
                                progress: _progressPercentage,
                                primaryColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                    ? (_paceOffset >= 0 ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! : Colors.orange) // Use duotone foreground
                                    : (_paceOffset >= 0 ? Theme.of(context).colorScheme.primary : Colors.orange),
                                backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                    ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.2) // Use duotone foreground with opacity
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(_progressPercentage * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                        ? (_paceOffset >= 0 ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! : Colors.orange) // Use duotone foreground
                                        : (_paceOffset >= 0 ? Theme.of(context).colorScheme.primary : Colors.orange),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'there',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (_paceOffset != 0) ...[                                  
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (_paceOffset > 0 
                                        ? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true 
                                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! 
                                            : Theme.of(context).colorScheme.primary) 
                                        : Colors.red).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: (_paceOffset > 0 
                                          ? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true 
                                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! 
                                              : Theme.of(context).colorScheme.primary) 
                                          : Colors.red).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${_paceOffset.abs()} ${_paceOffset > 0 ? "ahead" : "behind"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _paceOffset > 0 
                                          ? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true 
                                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! 
                                              : Theme.of(context).colorScheme.primary) 
                                          : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Endless practice mode with animated gradient - only show if there are learned items
          if (_allLearnedItems.isNotEmpty)
            InkWell(
              onTap: _startEndlessPractice,
            borderRadius: BorderRadius.circular(20),
            splashColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
            highlightColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.05)
                : Colors.white.withOpacity(0.05),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                    ? [
                        Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!,
                        Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.8),
                      ]
                    : [
                        const Color(0xFF6A5ACD),
                        const Color(0xFF4169E1),
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF6A5ACD).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.all_inclusive,
                      size: 36,
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
                        : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Endless Practice',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
                              : Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Practice all ${_allLearnedItems.length} learned items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
                      : Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent sets section
          const Text(
            'Recent Sets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Recent sets list
          if (_recentSets.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No recent practice sets.\nStart practicing from the Sets tab!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            ..._recentSets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
              final setColor = isDuotone ? Theme.of(context).colorScheme.surface : _getColorForSet(index);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _practiceSet(set),
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
                  highlightColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.05)
                      : Colors.white.withOpacity(0.05),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: setColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDuotone 
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1) // Light black for rice paper
                              : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              set['count'].toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDuotone ? Theme.of(context).colorScheme.onSurface : Colors.white,
                                shadows: isDuotone ? [] : [
                                  Shadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                set['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDuotone ? Theme.of(context).colorScheme.onSurface : Colors.white,
                                ),
                              ),
                              Text(
                                '${set['type'] == 'word' ? 'Words' : 'Characters'} set',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDuotone ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isDuotone ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            ],
          ),
        ),
        // Feedback widget - positioned at bottom right corner
        Positioned(
          bottom: 16,
          right: 16,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(28),
                color: Colors.transparent,
                child: InkWell(
                  onTap: _launchFeedbackForm,
                  borderRadius: BorderRadius.circular(28),
                  splashColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  highlightColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? [
                              Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!,
                              Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.8),
                            ]
                          : [
                              const Color(0xFFFF6B6B), // Bright red-orange for other themes
                              const Color(0xFFFFE66D), // Bright yellow for other themes
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? [] // No shadow for duotone theme
                        : [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
                            : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Give Feedback',
                          style: TextStyle(
                            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
                              : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  
  void _startTutorial() async {
    // Navigate to writing practice with 一 character
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WritingPracticePage(
          character: '一',
          characterSet: 'Tutorial',
          allCharacters: const ['一'],
          isWord: false,
          mode: PracticeMode.learning,
          onComplete: (success) {
            // Tutorial completed
          },
        ),
      ),
    );
    
    // After completing the tutorial, show the welcome dialog
    if (mounted) {
      _showWelcomeDialog();
    }
  }
  
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Great job!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You just learned your first character "一" (one)!\nWould you like to learn more about using Zishu?',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Show second notification about marking learned characters
                        _showMarkAsLearnedNotification();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: const Text(
                        "I got it",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpPage(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: const Text(
                        'Learn more',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMarkAsLearnedNotification() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Already know some Chinese?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can mark characters you already know as learned, so you can focus on practicing new ones!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: const Text(
                        "I'm good",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to Mark as Learned page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MarkAsLearnedPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Mark learned',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}

// Circular progress painter
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius - 4, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Clean progress painter with single ring
class CleanProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  CleanProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Draw single background track
    final trackPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius - 10, trackPaint);
    
    // Subtle glow layer
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
    
    // Progress arc - simple solid color
    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Futuristic progress painter with gradient and glow effects
class FuturisticProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  FuturisticProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Draw background track
    final trackPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Multiple tracks for depth
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, radius - 10 - (i * 4), trackPaint);
    }
    
    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius - 10);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: [
        secondaryColor.withOpacity(0.3),
        primaryColor,
        primaryColor.withOpacity(0.8),
        secondaryColor,
      ],
      stops: const [0.0, 0.4, 0.8, 1.0],
    );
    
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
    
    // Add glowing endpoints
    if (progress > 0.01) {
      final endAngle = -math.pi / 2 + (2 * math.pi * progress);
      final endPoint = Offset(
        center.dx + (radius - 10) * math.cos(endAngle),
        center.dy + (radius - 10) * math.sin(endAngle),
      );
      
      // Glow effect
      for (int i = 3; i >= 1; i--) {
        final glowPaint = Paint()
          ..color = primaryColor.withOpacity(0.3 / i)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(endPoint, 3.0 * i, glowPaint);
      }
      
      // Core dot
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(endPoint, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Endless practice page with active recall
class EndlessPracticePage extends StatefulWidget {
  final List<String> items;
  final Function(int)? onNavigateToTab;

  const EndlessPracticePage({
    super.key,
    required this.items,
    this.onNavigateToTab,
  });

  @override
  State<EndlessPracticePage> createState() => _EndlessPracticePageState();
}

class _EndlessPracticePageState extends State<EndlessPracticePage> {
  final CharacterDictionary _dictionary = CharacterDictionary();
  final StatisticsService _statsService = StatisticsService();
  final LearningService _learningService = LearningService();
  
  List<String> _practiceQueue = [];
  final List<String> _reviewQueue = [];
  final Map<String, int> _incorrectCounts = {};
  final Map<String, bool> _itemResults = {}; // Track results for each item
  final List<String> _incorrectItems = [];
  final Set<String> _recentlyReviewed = {}; // Track recently reviewed items
  
  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalAttempts = 0;
  DateTime? _sessionStartTime;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _initializeQueue();
  }

  void _initializeQueue() async {
    // Always get fresh data from database
    await _refreshLearnedItems();
    
    // Initialize _currentIndex to 0 only on first load
    if (_currentIndex == 0 && _practiceQueue.isNotEmpty) {
      // Start from beginning
      setState(() {
        _practiceQueue.shuffle();
      });
    }
    
    // If still empty after refresh, show error message
    if (_practiceQueue.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No learned items found. Please learn some characters first!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<void> _refreshLearnedItems() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Clear cache to get fresh data
      _learningService.clearCache();
      _statsService.clearCache();
      
      // Get ALL learned items from database
      final learnedCharacters = await _statsService.getLearnedCharacters();
      final learnedWords = await _statsService.getLearnedWords();
      final allLearned = [...learnedCharacters, ...learnedWords];
      
      // Debug: Learned characters: ${learnedCharacters.length}
      // Debug: Learned words: ${learnedWords.length}
      // Debug: Check if 一切 is in learned words
      
      // Filter valid items
      final validItems = allLearned.where((item) {
        if (item.isEmpty) return false;
        if (item.length == 1) return true;
        return _dictionary.isMultiCharacterItem(item);
      }).toList();
      
      // Always rebuild the entire queue with fresh data
      setState(() {
        _practiceQueue = List.from(validItems)..shuffle();
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _handlePracticeComplete(bool success) {
    // Calculate actual queue position (for looping)
    final queueIndex = _currentIndex % _practiceQueue.length;
    final currentItem = _practiceQueue[queueIndex];
    _totalAttempts++;
    
    // Track results
    _itemResults[currentItem] = success;
    
    if (success) {
      _correctCount++;
      // Remove from incorrect count if it was there
      _incorrectCounts.remove(currentItem);
      _incorrectItems.remove(currentItem);
      _recentlyReviewed.remove(currentItem);
    } else {
      // Add to review queue for active recall
      _incorrectCounts[currentItem] = (_incorrectCounts[currentItem] ?? 0) + 1;
      if (!_incorrectItems.contains(currentItem)) {
        _incorrectItems.add(currentItem);
      }
      
      // Only add back to queue if not recently reviewed (prevent infinite loops)
      if (!_recentlyReviewed.contains(currentItem)) {
        _recentlyReviewed.add(currentItem);
        
        // Add back to queue after 6-9 items for better spaced repetition
        final reviewPosition = _currentIndex + 6 + (DateTime.now().millisecondsSinceEpoch % 4);
        
        if (reviewPosition < _practiceQueue.length) {
          // Insert at the calculated position
          _practiceQueue.insert(reviewPosition, currentItem);
        } else {
          // Add to review queue to be inserted later
          if (!_reviewQueue.contains(currentItem)) {
            _reviewQueue.add(currentItem);
          }
        }
      }
    }
    
    // Move to next item
    setState(() {
      _currentIndex++;
      
      // Check if we need to loop or add review items
      if (_currentIndex >= _practiceQueue.length) {
        if (_reviewQueue.isNotEmpty) {
          // Add review items and continue
          _practiceQueue.addAll(_reviewQueue);
          _reviewQueue.clear();
        } else {
          // We've completed the queue, refresh to include newly learned items
          _refreshLearnedItems().then((_) {
            if (mounted) {
              setState(() {
                // Shuffle the refreshed queue
                _practiceQueue.shuffle();
                // Clear recently reviewed set for next round
                _recentlyReviewed.clear();
              });
            }
          });
        }
      }
    });
  }

  void _showStatsAndExit() {
    final totalItems = _itemResults.length;
    final correctCount = _itemResults.values.where((v) => v).length;
    final incorrectCount = _itemResults.values.where((v) => !v).length;
    final percentage = totalItems > 0 ? (correctCount / totalItems * 100).round() : 0;
    final sessionDuration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!) 
        : Duration.zero;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              percentage >= 80 ? Icons.star : Icons.check_circle,
              color: percentage >= 80 ? Colors.amber : Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('Session Summary'),
          ],
        ),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: percentage >= 80 
                              ? Colors.green 
                              : percentage >= 60 
                                  ? Colors.orange 
                                  : Colors.red,
                        ),
                      ),
                      Text(
                        'Accuracy',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Statistics
                _buildStatRow(Icons.check_circle, 'Correct', '$correctCount', Colors.green),
                _buildStatRow(Icons.cancel, 'Incorrect', '$incorrectCount', Colors.red),
                _buildStatRow(Icons.format_list_numbered, 'Total Items', '$totalItems', Theme.of(context).colorScheme.primary),
                _buildStatRow(Icons.repeat, 'Total Attempts', '$_totalAttempts', Theme.of(context).colorScheme.secondary),
                _buildStatRow(Icons.timer, 'Time', _formatDuration(sessionDuration), Theme.of(context).colorScheme.secondary),
                
                if (_incorrectItems.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Items to Review (${_incorrectItems.length}):',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _incorrectItems.take(10).map((item) => Chip(
                      label: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: Colors.red.withOpacity(0.1),
                    )).toList(),
                  ),
                  if (_incorrectItems.length > 10)
                    Text(
                      '... and ${_incorrectItems.length - 10} more',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (_incorrectItems.isNotEmpty) ...[ 
            TextButton.icon(
              onPressed: () => _practiceIncorrect(),
              icon: const Icon(Icons.refresh),
              label: const Text('Practice Incorrect'),
            ),
            TextButton.icon(
              onPressed: () => _createCustomSetFromIncorrect(),
              icon: const Icon(Icons.add_box),
              label: const Text('Create Set'),
            ),
          ],
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
  
  void _practiceIncorrect() {
    Navigator.of(context).pop();
    setState(() {
      // Create new queue with only incorrect items
      _practiceQueue = List.from(_incorrectItems)..shuffle();
      // Keep _currentIndex to preserve continuous count
      _incorrectItems.clear();
      _itemResults.clear();
      _correctCount = 0;
      _totalAttempts = 0;
      _sessionStartTime = DateTime.now();
    });
  }
  
  Future<void> _createCustomSetFromIncorrect() async {
    // Close the summary dialog
    Navigator.of(context).pop();
    
    // Show dialog to get set name
    final TextEditingController nameController = TextEditingController();
    nameController.text = 'Review Set';
    
    final setName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Practice Set'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Set Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    if (setName == null || !mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Generate unique set ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final setId = 'custom_$timestamp';
    
    // Determine if this should be a word set
    final isWordSet = _incorrectItems.any((item) => item.length > 1);
    
    // Save custom set
    final customSets = prefs.getStringList('custom_sets') ?? [];
    final setData = {
      'id': setId,
      'name': setName,
      'characters': _incorrectItems,
      'isWordSet': isWordSet,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    customSets.add(jsonEncode(setData));
    await prefs.setStringList('custom_sets', customSets);
    
    if (mounted) {
      // Show animated overlay
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => _AnimatedSetCreation(
          setName: setName,
          onComplete: () {
            overlayEntry.remove();
            // Navigate to home and then to sets tab with custom sets selected
            Navigator.of(context).pop(); // Close endless practice
            // Use post frame callback to ensure navigation completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onNavigateToTab?.call(1); // Navigate to sets tab
            });
          },
        ),
      );
      overlay.insert(overlayEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while refreshing
    if (_isRefreshing && _practiceQueue.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Handle empty queue
    if (_practiceQueue.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid characters found for practice'),
          ),
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Handle empty queue
    if (_practiceQueue.isEmpty) {
      // Try to refresh once more
      _refreshLearnedItems().then((_) {
        if (_practiceQueue.isEmpty && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No learned items found for practice'),
            ),
          );
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate actual queue position (for looping)
    final queueIndex = _currentIndex % _practiceQueue.length;
    final currentItem = _practiceQueue[queueIndex];
    final isWord = _dictionary.isMultiCharacterItem(currentItem);
    
    // Debug: Current item: "$currentItem", Length: ${currentItem.length}, Is word: $isWord
    
    // Use a unique key to force rebuild when character changes
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Show stats before exiting
          _showStatsAndExit();
        }
      },
      child: Scaffold(
        body: WritingPracticePage(
          key: ValueKey('${currentItem}_$_currentIndex'), // Unique key for each character
          character: currentItem,
          characterSet: 'Endless Practice',
          allCharacters: null, // Don't preload in endless mode to avoid loading words as single characters
          isWord: isWord,
          mode: PracticeMode.testing,
          onComplete: (success) {
            _handlePracticeComplete(success);
          },
          endlessPracticeCount: _currentIndex + 1, // Pass the actual count
        ),
      ),
    );
  }
}

// Animation widget for set creation
class _AnimatedSetCreation extends StatefulWidget {
  final String setName;
  final VoidCallback onComplete;
  
  const _AnimatedSetCreation({
    required this.setName,
    required this.onComplete,
  });
  
  @override
  State<_AnimatedSetCreation> createState() => _AnimatedSetCreationState();
}

class _AnimatedSetCreationState extends State<_AnimatedSetCreation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
    
    _controller.forward();
    
    // Auto complete after animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Set Created!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.setName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
}

