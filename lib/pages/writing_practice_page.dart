import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import '../services/streak_service.dart';
import '../services/character_stroke_service.dart';
import '../services/character_database.dart';
import '../services/character_dictionary.dart';
import '../services/character_info_service.dart';
import '../services/cedict_service.dart';
import '../widgets/smooth_stroke_hint.dart';
import '../services/stroke_combination_rules.dart';
import '../services/statistics_service.dart';
import '../services/learning_service.dart';
import '../utils/pinyin_utils.dart';
import '../main.dart' show DuotoneThemeExtension, refreshSetsProgress;
import 'settings_page.dart';
import '../services/image_cache_service.dart';
import '../services/radical_service.dart';
import '../services/decomposition_service.dart';
import '../widgets/radical_analysis_widget.dart';
import '../widgets/simple_radical_display.dart';
import '../services/haptic_service.dart';

enum PracticeMode { learning, testing }

class WritingPracticePage extends StatefulWidget {
  final String character;
  final String characterSet;
  final List<String>? allCharacters;
  final bool isWord;
  final PracticeMode mode;
  final Function(bool)? onComplete;
  final int? endlessPracticeCount;

  const WritingPracticePage({
    super.key,
    required this.character,
    required this.characterSet,
    this.allCharacters,
    this.isWord = false,
    this.mode = PracticeMode.learning,
    this.onComplete,
    this.endlessPracticeCount,
  });

  @override
  State<WritingPracticePage> createState() => _WritingPracticePageState();
}

class _WritingPracticePageState extends State<WritingPracticePage> 
    with TickerProviderStateMixin {
  // Services
  final LocalStorageService _storageService = LocalStorageService();
  final CharacterStrokeService _strokeService = CharacterStrokeService();
  final CharacterDatabase _database = CharacterDatabase();
  final CharacterDictionary _dictionary = CharacterDictionary();
  final CharacterInfoService _infoService = CharacterInfoService();
  final StatisticsService _statsService = StatisticsService();
  final LearningService _learningService = LearningService();
  final CedictService _cedictService = CedictService();
  final RadicalService _radicalService = RadicalService();
  
  // Character data
  CharacterStroke? _characterStroke;
  CharacterRadicalAnalysis? _radicalAnalysis;
  
  // User input tracking
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _currentStroke = [];
  List<int> _currentStrokeTimestamps = []; // Track timestamp for each point
  Timer? _updateTimer;
  List<Offset> _pendingPoints = [];
  static const _updateInterval = Duration(milliseconds: 8); // 120 FPS for smoother strokes
  
  // Stroke validation
  final List<int> _completedStrokeIndices = [];
  final List<int> _wrongAttempts = [];
  
  // UI state
  bool _showGuide = true;
  bool _showGrid = true;
  int _currentCharacterIndex = 0;
  bool _showSuccess = false;
  bool _showHintPath = false;
  bool _showFullCharacter = false;
  bool _usedHint = false;
  int _missedStrokes = 0;
  final Set<int> _missedStrokeIndices = {}; // Track which strokes have been missed
  bool _showManualGrading = false;
  bool _autoGradedAsCorrect = false;
  Timer? _autoProceedTimer;
  double _timerProgress = 1.0;
  Timer? _progressTimer;
  bool _isLoadingCharacter = true;
  
  // Learning mode stages
  int _learningStage = 0; // 0: with hints, 1: outline only, 2: no help
  
  // Testing mode state
  bool _testingCharacterRevealed = false;
  final List<String> _completedTestCharacters = [];
  
  // Word handling
  List<String> _wordCharacters = [];
  int _currentWordCharacterIndex = 0;
  final Map<int, bool> _wordCharacterResults = {}; // Track if each character was correct
  
  // Canvas key
  final GlobalKey _canvasKey = GlobalKey();
  
  // Continuous practice counter
  int _practiceCount = 0;
  
  // Time tracking
  DateTime? _practiceStartTime;
  
  // Stroke customization
  double _strokeWidth = 8.0;
  Color? _strokeColor;  // For drawing strokes
  Color? _hintColor;    // For hints
  StrokeType _strokeType = StrokeType.classic;
  
  // Session statistics
  final List<String> _incorrectItems = [];
  final Map<String, bool> _itemResults = {}; // Track results for each item
  int _totalItemsStudied = 0;
  int _correctItems = 0;
  DateTime? _sessionStartTime;
  
  // Stroke bounce animation
  AnimationController? _bounceController;
  Animation<double>? _bounceAnimation;
  int? _bouncingStrokeIndex;
  double _strokeDeviation = 0.0;
  
  // Classic stroke animation
  AnimationController? _classicStrokeController;
  Animation<double>? _classicStrokeAnimation;
  
  // Settings
  bool _showRadicalAnalysis = false;
  
  String get currentWord {
    if (widget.isWord && widget.allCharacters != null) {
      return widget.allCharacters![_currentCharacterIndex];
    } else if (widget.isWord) {
      return widget.character;
    }
    return '';
  }
  
  String get currentCharacter {
    if (widget.isWord) {
      if (_wordCharacters.isNotEmpty && _currentWordCharacterIndex < _wordCharacters.length) {
        return _wordCharacters[_currentWordCharacterIndex];
      }
      return '';
    } else if (widget.allCharacters != null) {
      return widget.allCharacters![_currentCharacterIndex];
    } else {
      return widget.character;
    }
  }

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    // Load settings immediately with default values
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _showGrid = prefs.getBool('show_grid') ?? true;
        _showGuide = prefs.getBool('show_guide') ?? true;
        _strokeWidth = prefs.getDouble('stroke_width') ?? 8.0;
        final strokeColorString = prefs.getString('stroke_color') ?? 'primary';
        final themeMode = prefs.getString('theme_mode') ?? 'system';
        // Force ink color for rice paper theme
        _strokeColor = (themeMode == 'duotone') 
            ? null // Use theme foreground color in duotone mode
            : _getColorFromString(strokeColorString);
        final hintColorString = prefs.getString('hint_color') ?? prefs.getString('stroke_color') ?? 'primary';
        _hintColor = (themeMode == 'duotone')
            ? null // Use theme foreground color in duotone mode
            : _getColorFromString(hintColorString);
        final strokeTypeString = prefs.getString('stroke_type') ?? 'classic';
        _strokeType = StrokeType.values.firstWhere(
          (type) => type.name == strokeTypeString,
          orElse: () => StrokeType.classic,
        );
        // Show radical analysis in learning mode if enabled (default true)
        final savedSetting = prefs.getBool('show_radical_analysis') ?? true;
        _showRadicalAnalysis = widget.mode == PracticeMode.learning && savedSetting;
        
        // Initialize classic stroke animation if needed
        if (_strokeType == StrokeType.classic) {
          _initializeClassicStrokeAnimation();
        }
      });
    });
    _initializeData();
    _initializeRadicalService();
  }
  
  void _initializeClassicStrokeAnimation() {
    _classicStrokeController?.dispose();
    _classicStrokeController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60fps refresh rate
      vsync: this,
    );
    _classicStrokeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_classicStrokeController!);
    _classicStrokeController!.repeat(); // Continuously repaint
  }
  
  @override
  void didUpdateWidget(WritingPracticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If character changed, reload data
    if (oldWidget.character != widget.character) {
      _initializeData();
    }
  }
  
  @override
  void dispose() {
    _autoProceedTimer?.cancel();
    _progressTimer?.cancel();
    _bounceController?.dispose();
    _updateTimer?.cancel();
    _classicStrokeController?.dispose();
    
    // In learning mode, save progress for completed characters when backing out
    if (widget.mode == PracticeMode.learning && widget.allCharacters != null) {
      // Mark all characters that were completed with all 3 stages as learned
      _saveLearnedCharactersOnExit();
    }
    
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showGrid = prefs.getBool('show_grid') ?? true;
      _showGuide = prefs.getBool('show_guide') ?? true;
      _strokeWidth = prefs.getDouble('stroke_width') ?? 8.0;
      final strokeColorString = prefs.getString('stroke_color') ?? 'primary';
      final themeMode = prefs.getString('theme_mode') ?? 'system';
      // Force ink color for rice paper theme
      _strokeColor = (themeMode == 'duotone') 
          ? null // Use theme foreground color in duotone mode
          : _getColorFromString(strokeColorString);
      final hintColorString = prefs.getString('hint_color') ?? prefs.getString('stroke_color') ?? 'primary';
      _hintColor = (themeMode == 'duotone')
          ? null // Use theme foreground color in duotone mode
          : _getColorFromString(hintColorString);
      final strokeTypeString = prefs.getString('stroke_type') ?? 'classic';
      _strokeType = StrokeType.values.firstWhere(
        (type) => type.name == strokeTypeString,
        orElse: () => StrokeType.classic,
      );
      // Load the setting but always show in learning mode
      final savedSetting = prefs.getBool('show_radical_analysis') ?? true;
      _showRadicalAnalysis = widget.mode == PracticeMode.learning && savedSetting;
    });
    
    // Reload radical analysis if needed
    if (_showRadicalAnalysis && _radicalService.isInitialized) {
      _radicalAnalysis = _radicalService.getRadicalAnalysis(currentCharacter);
    } else {
      _radicalAnalysis = null;
    }
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'ink':
        // Return black for light mode, white for dark mode
        return Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black87;
      case 'primary':
        return Theme.of(context).colorScheme.primary;
      case 'red':
        final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
        if (duotoneTheme?.isDuotoneTheme == true) {
          return duotoneTheme!.duotoneColor2!;
        }
        return Colors.red;
      case 'green':
        final duotoneTheme2 = Theme.of(context).extension<DuotoneThemeExtension>();
        if (duotoneTheme2?.isDuotoneTheme == true) {
          return duotoneTheme2!.duotoneColor2!;
        }
        return Colors.green;
      case 'blue':
        final duotoneTheme3 = Theme.of(context).extension<DuotoneThemeExtension>();
        if (duotoneTheme3?.isDuotoneTheme == true) {
          return duotoneTheme3!.duotoneColor2!;
        }
        return Colors.blue;
      case 'purple':
        final duotoneTheme4 = Theme.of(context).extension<DuotoneThemeExtension>();
        if (duotoneTheme4?.isDuotoneTheme == true) {
          return duotoneTheme4!.duotoneColor2!;
        }
        return Colors.purple;
      case 'orange':
        final duotoneTheme5 = Theme.of(context).extension<DuotoneThemeExtension>();
        if (duotoneTheme5?.isDuotoneTheme == true) {
          return duotoneTheme5!.duotoneColor2!;
        }
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
  
  Color _getWritingBoxBackgroundColor(BuildContext context) {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // For duotone theme, use the same background color
      return duotoneTheme!.duotoneColor1!;
    } else if (Theme.of(context).brightness == Brightness.dark) {
      return const Color(0xFF1E1E1E); // Dark background for dark mode
    } else {
      return Colors.white; // White background for light mode
    }
  }
  
  Color _getButtonBackgroundColor(bool isCorrect) {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // For duotone theme, use the duotone foreground color
      return duotoneTheme!.duotoneColor2!;
    } else {
      // In non-duotone mode, use vibrant colors for better visibility
      if (isDarkMode) {
        // Use brighter colors in dark mode
        return isCorrect ? Colors.green.shade400 : Colors.red.shade400;
      } else {
        // Use standard colors in light mode
        return isCorrect ? Colors.green : Colors.red;
      }
    }
  }
  
  Color _getButtonForegroundColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // For duotone theme, use the main background color for text on accent buttons
      return duotoneTheme!.duotoneColor1!;
    } else {
      return Colors.white;
    }
  }
  
  Color _getButtonBorderColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // For duotone theme, use the duotone foreground color for borders
      return duotoneTheme!.duotoneColor2!;
    } else {
      return Colors.white;
    }
  }
  
  Color _getSuccessColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // For duotone theme, use a darker shade of the foreground color
      final foregroundColor = duotoneTheme!.duotoneColor2!;
      final hslColor = HSLColor.fromColor(foregroundColor);
      return hslColor.withLightness((hslColor.lightness * 0.3).clamp(0.0, 1.0)).toColor();
    } else {
      return Colors.green;
    }
  }
  
  Color _getCharacterGuideColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (duotoneTheme?.isDuotoneTheme == true) {
      // For duotone theme, use a light opacity version of the foreground color
      return duotoneTheme!.duotoneColor2!.withValues(alpha: 0.2);
    } else if (Theme.of(context).brightness == Brightness.dark) {
      return Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    } else {
      // For non-duotone mode, use theme surface color
      return Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
  }
  
  Future<void> _initializeRadicalService() async {
    if (!_radicalService.isInitialized) {
      await _radicalService.initialize();
    }
  }

  Future<void> _initializeData() async {
    // Don't clear stroke data - we need fallback placeholders
    // if (DatabaseConfig.USE_FULL_DATABASE) {
    //   _strokeService.clearData();
    // }
    
    // Initialize database
    await _database.initialize();
    
    // Update recent practice sets
    final prefs = await SharedPreferences.getInstance();
    final practiceHistory = prefs.getStringList('recent_practice_sets') ?? [];
    if (widget.characterSet != 'Endless Practice') {
      practiceHistory.remove(widget.characterSet); // Remove if exists
      practiceHistory.insert(0, widget.characterSet); // Add to front
      await prefs.setStringList('recent_practice_sets', practiceHistory.take(10).toList());
    }
    
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    
    // Debug: Initial load - Character: "${widget.character}", isWord: ${widget.isWord}
    
    if (widget.isWord) {
      // Handle word mode - split into characters if multi-character
      if (_dictionary.isMultiCharacterItem(widget.character)) {
        // This is a multi-character word
        final word = widget.character;
        _wordCharacters = _dictionary.splitIntoCharacters(word);
        
        // Debug: Multi-character word split into: $_wordCharacters
        // Load all characters in the word
        await _database.loadCharacters(_wordCharacters);
      } else {
        // This is from a word set but it's a single character
        _wordCharacters = [widget.character];
        // Debug: Single character from word set: $_wordCharacters
        await _database.loadCharacters([widget.character]);
      }
    } else {
      // Load all characters for this practice session
      final charactersToLoad = widget.allCharacters ?? [widget.character];
      // Debug: Loading characters for practice: ${charactersToLoad.length} items
      await _database.loadCharacters(charactersToLoad);
    }
    
    // Production: removed debug print
    
    // Load CEDICT if not already loaded
    if (!_cedictService.isLoaded) {
      _cedictService.initialize().then((_) {
        if (mounted) {
          setState(() {}); // Refresh to show definitions
        }
      });
    }
    
    // Now load character data for the current character
    _loadCharacterData();
  }

  void _loadCharacterData() async {
    try {
      setState(() {
        _isLoadingCharacter = true;
      });
      
      // First, try to get the character from the stroke service
      _characterStroke = _strokeService.getCharacterStroke(currentCharacter);
      
      // If not found, try to load it from database
      if (_characterStroke == null) {
        await _database.loadCharacters([currentCharacter]);
        _characterStroke = _strokeService.getCharacterStroke(currentCharacter);
        
        if (_characterStroke == null && mounted) {
          // Show error dialog if character cannot be loaded
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Character Not Available'),
              content: Text('The character "$currentCharacter" is not available in the database.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Go back from practice page
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading character: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    // Load radical analysis if enabled and in learning mode
    if (_showRadicalAnalysis && widget.mode == PracticeMode.learning && _radicalService.isInitialized) {
      // Production: removed debug print
      // Production: removed debug print
      // Production: removed debug print
      // Production: removed debug print
      _radicalAnalysis = _radicalService.getRadicalAnalysis(currentCharacter);
      // Production: removed debug print
      if (_radicalAnalysis != null) {
        // Production: removed debug print
      }
    } else {
      _radicalAnalysis = null;
    }
    
    setState(() {
      _isLoadingCharacter = false;
      
      // CRITICAL: Clear all state variables first
      _completedStrokeIndices.clear();
      _userStrokes.clear();
      _currentStroke.clear();
      _currentStrokeTimestamps.clear();
      _wrongAttempts.clear();
      _missedStrokeIndices.clear();
      
      // Reset UI state
      _testingCharacterRevealed = false;
      // For learning mode with multi-character words, preserve the learning stage
      if (widget.mode == PracticeMode.learning && widget.isWord && _wordCharacters.length > 1) {
        // Don't reset learning stage when cycling through characters
      } else if (!widget.isWord || widget.mode != PracticeMode.learning) {
        // Reset for single characters or testing mode
        _learningStage = 0;
      }
      _showHintPath = false;
      _showFullCharacter = false;
      _usedHint = false;
      _missedStrokes = 0;
      _practiceStartTime = DateTime.now();
      _showManualGrading = false;
      
      _showSuccess = false;
      _autoGradedAsCorrect = false;
      _strokeDeviation = 0.0;
      
      // Cancel timers
      _autoProceedTimer?.cancel();
      _progressTimer?.cancel();
      _timerProgress = 1.0;
      
      if (_characterStroke != null) {
        _wrongAttempts.addAll(List.filled(_characterStroke!.strokes.length, 0));
      } else {
        // If character not found, show error and skip
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMissingCharacterDialog();
        });
      }
    });
  }
  
  void _showMissingCharacterDialog() {
    final explanation = _infoService.getDetailedExplanation(currentCharacter);
    final alternatives = _infoService.getAlternatives(currentCharacter);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Character Unavailable'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      currentCharacter,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MakeMeAHanzi database covers approximately 9,500 common Chinese characters. Some rare, dialectal, or variant characters may not be included.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          if (alternatives != null && alternatives.isNotEmpty)
            TextButton(
              onPressed: () {
                if (mounted) {
              Navigator.pop(context);
            }
                if (mounted) {
              Navigator.pop(context);
            }
                // Show dialog to practice alternatives
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Practice Alternatives'),
                    content: Text('Would you like to create a practice set with: ${alternatives.join(", ")}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No'),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (mounted) {
              Navigator.pop(context);
            }
                          // Navigate to custom set creation with alternatives
                          // This would need to be implemented
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('See Alternatives'),
            ),
          TextButton(
            onPressed: () {
              if (mounted) {
              Navigator.pop(context);
            }
              // Try to move to next character
              if (widget.isWord && _wordCharacters.length > 1) {
                if (_currentWordCharacterIndex < _wordCharacters.length - 1) {
                  setState(() {
                    _currentWordCharacterIndex++;
                  });
                  // Load the next character
                  _database.loadCharacters([_wordCharacters[_currentWordCharacterIndex]]).then((_) {
                    if (mounted) {
                      _loadCharacterData();
                    }
                  });
                } else {
                  if (mounted) {
              Navigator.pop(context);
            } // Exit practice
                }
              } else if (widget.allCharacters != null &&
                  _currentCharacterIndex < widget.allCharacters!.length - 1) {
                setState(() {
                  _currentCharacterIndex++;
                  if (widget.isWord) {
                    final nextItem = widget.allCharacters![_currentCharacterIndex];
                    if (_dictionary.isMultiCharacterItem(nextItem)) {
                      _wordCharacters = _dictionary.splitIntoCharacters(nextItem);
                    } else {
                      _wordCharacters = [nextItem];
                    }
                  }
                  _loadCharacterData();
                });
              } else {
                if (mounted) {
              Navigator.pop(context);
            } // Exit practice
              }
            },
            child: const Text('Skip Character'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: widget.characterSet == 'Tutorial' ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.mode == PracticeMode.learning && _learningStage > 0) {
              // In learning mode, go back to previous stage
              setState(() {
                _learningStage--;
                _completedStrokeIndices.clear();
                _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
                _userStrokes.clear();
              });
            } else {
              // Check if this is individual character practice
              final isIndividualPractice = widget.allCharacters != null && widget.allCharacters!.length == 1;
              
              // Show summary if in testing mode and not endless practice or individual practice
              if (widget.mode == PracticeMode.testing && 
                  widget.characterSet != 'Endless Practice' && 
                  !isIndividualPractice &&
                  _totalItemsStudied > 0) {
                _showCompletionDialog();
              } else {
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
              // Reload settings when returning
              _loadSettings();
            },
            tooltip: 'Practice Settings',
          ),
        ],
      ),
      body: Container(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate max width to prevent overflow on wide screens
            final maxWidth = math.min(constraints.maxWidth, 600.0);
            
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                  // Character info section
                  if (widget.isWord && _wordCharacters.length > 1) ...[
                    // For multi-character words, show pronunciation above progress boxes
                    _buildWordPronunciation(),
                    // Progress boxes
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildWordProgressBoxes(),
                    ),
                  ] else ...[
                    // For single characters, show pronunciation and definition
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildCharacterInfoSection(),
                    ),
                  ],
                  
                  // Drawing area (square) with all buttons right below
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: widget.characterSet == 'Tutorial' ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.0, // Force square
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1! // Use background color
                      : null,
                    border: Border.all(
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use foreground color for border
                        : Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          key: _canvasKey,
                          color: _getWritingBoxBackgroundColor(context),
                          child: Stack(
                            children: [
                        
                        // Grid
                        if (_showGrid)
                          CustomPaint(
                            size: Size.infinite,
                            painter: GridPainter(
                              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                ? Theme.of(context).extension<DuotoneThemeExtension>()!.gridColor
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        
                        // Loading indicator
                        if (_isLoadingCharacter)
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        
                        // Error message if character couldn't be loaded
                        if (!_isLoadingCharacter && _characterStroke == null)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load character: $currentCharacter',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _loadCharacterData();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        
                        // Character guide based on learning stage
                        if (_characterStroke != null && (
                          _showFullCharacter || // Manual show all
                          (widget.mode == PracticeMode.learning && (_learningStage == 0 || _learningStage == 1)) // Stage 0 and 1: show filled character
                        ))
                          CustomPaint(
                            size: Size.infinite,
                            painter: CharacterGuidePainter(
                              characterStroke: _characterStroke!,
                              canvasSize: constraints.biggest,
                              color: _getCharacterGuideColor(),
                            ),
                          ),
                        
                        // Completed strokes
                        if (_characterStroke != null && _completedStrokeIndices.isNotEmpty)
                          AnimatedBuilder(
                            animation: _bounceAnimation ?? const AlwaysStoppedAnimation(1.0),
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size.infinite,
                                painter: CompletedStrokesPainter(
                                  characterStroke: _characterStroke!,
                                  completedIndices: _completedStrokeIndices,
                                  canvasSize: constraints.biggest,
                                  context: context,
                                  showSuccess: _showSuccess,
                                  isCorrect: _autoGradedAsCorrect,
                                  bouncingStrokeIndex: _bouncingStrokeIndex,
                                  bounceProgress: _bounceAnimation?.value ?? 0.0,
                                  strokeDeviation: _strokeDeviation,
                                ),
                              );
                            },
                          ),
                        
                        // Animated stroke hints - rendered on top of completed strokes
                        FutureBuilder<bool>(
                          future: SharedPreferences.getInstance().then(
                            (prefs) => prefs.getBool('show_stroke_animation') ?? true
                          ),
                          builder: (context, snapshot) {
                            final showAnimation = snapshot.data ?? true;
                            // Show animated hints in learning stage 0 or when hint is requested after 2 wrong attempts
                            if (_characterStroke != null && showAnimation &&
                                _completedStrokeIndices.length < _characterStroke!.strokes.length &&
                                ((widget.mode == PracticeMode.learning && _learningStage == 0 && !_showFullCharacter) ||
                                 _showHintPath)) {
                              return Positioned.fill(
                                child: SmoothStrokeHint(
                                  characterStroke: _characterStroke!,
                                  strokeIndex: _getNextStrokeIndex(),
                                  canvasSize: constraints.biggest,
                                  color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                    ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.8) // Use foreground color for hint
                                    : (_hintColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.8),
                                ),
                              );
                            } else if (_characterStroke != null && !showAnimation && _showHintPath &&
                                       _completedStrokeIndices.length < _characterStroke!.strokes.length) {
                              // Show static hint if animation is disabled
                              return Positioned.fill(
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: HintPainter(
                                    characterStroke: _characterStroke!,
                                    strokeIndex: _getNextStrokeIndex(),
                                    canvasSize: constraints.biggest,
                                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use foreground color for hint
                                      : (_hintColor ?? Theme.of(context).colorScheme.primary),
                                    strokeWidth: _strokeWidth * 2,
                                    showDirectionArrows: false,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        // Drawing surface
                        GestureDetector(
                          onTapUp: (details) {
                            // If showing manual grading, proceed with the auto-graded result
                            if (_showManualGrading) {
                              _proceedWithGrade(_autoGradedAsCorrect);
                            }
                          },
                          onPanStart: (details) {
                            final currentChar = widget.isWord ? _wordCharacters[_currentWordCharacterIndex] : widget.character;
                            
                            // Don't start drawing if manual grading is showing
                            if (_showManualGrading) {
                              return;
                            }
                            
                            // Initialize stroke
                            _currentStroke = [details.localPosition];
                            _currentStrokeTimestamps = [DateTime.now().millisecondsSinceEpoch];
                            _pendingPoints.clear();
                            
                            // Start update timer for smooth rendering
                            _updateTimer?.cancel();
                            _updateTimer = Timer.periodic(_updateInterval, (_) {
                              if (_pendingPoints.isNotEmpty) {
                                setState(() {
                                  _currentStroke.addAll(_pendingPoints);
                                  // Add current timestamp for each pending point
                                  final currentTime = DateTime.now().millisecondsSinceEpoch;
                                  for (int i = 0; i < _pendingPoints.length; i++) {
                                    _currentStrokeTimestamps.add(currentTime);
                                  }
                                  _pendingPoints.clear();
                                });
                              }
                            });
                            
                            // Start classic stroke animation if needed
                            if (_strokeType == StrokeType.classic && _classicStrokeController == null) {
                              _initializeClassicStrokeAnimation();
                            }
                            
                            setState(() {});
                          },
                          onPanUpdate: (details) {
                            if (!_showManualGrading) {
                              // Add to pending points with higher density for smoother curves
                              final lastPoint = _currentStroke.isNotEmpty ? _currentStroke.last : 
                                               (_pendingPoints.isNotEmpty ? _pendingPoints.last : null);
                              
                              // Only add if point is far enough from last point to avoid duplicate points
                              if (lastPoint == null || (details.localPosition - lastPoint).distance > 1.0) {
                                _pendingPoints.add(details.localPosition);
                              }
                            }
                          },
                          onPanEnd: (details) {
                            final currentChar = widget.isWord ? _wordCharacters[_currentWordCharacterIndex] : widget.character;
                            
                            if (!_showManualGrading) {
                              // Cancel timer and flush pending points
                              _updateTimer?.cancel();
                              
                              // Force final update to show complete stroke
                              setState(() {
                                if (_pendingPoints.isNotEmpty) {
                                  _currentStroke.addAll(_pendingPoints);
                                  _pendingPoints.clear();
                                }
                              });
                              
                              _handleStrokeEnd();
                            } else {
                            }
                          },
                          child: _strokeType == StrokeType.classic && _classicStrokeAnimation != null
                            ? AnimatedBuilder(
                                animation: _classicStrokeAnimation!,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size.infinite,
                                    painter: CurrentStrokePainter(
                                      currentStroke: _currentStroke,
                                      strokeTimestamps: _currentStrokeTimestamps,
                                      strokeColor: _strokeColor ?? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                                        : Theme.of(context).colorScheme.primary),
                                      strokeWidth: _strokeWidth,
                                      strokeType: _strokeType,
                                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                                      isDuotone: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme ?? false,
                                      accentColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              )
                            : CustomPaint(
                                size: Size.infinite,
                                painter: CurrentStrokePainter(
                                  currentStroke: _currentStroke,
                                  strokeTimestamps: _currentStrokeTimestamps,
                                  strokeColor: _strokeColor ?? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                    ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                                    : Theme.of(context).colorScheme.primary),
                                  strokeWidth: _strokeWidth,
                                  strokeType: _strokeType,
                                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                                  isDuotone: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme ?? false,
                                  accentColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                        ),
                        
                        // Success/error icon overlay for duotone mode
                        if (_showSuccess && Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: AnimatedScale(
                              scale: _showSuccess ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.elasticOut,
                              child: AnimatedOpacity(
                                opacity: _showSuccess ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _autoGradedAsCorrect ? Icons.check : Icons.close,
                                    size: 32,
                                    color: Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Practice counter for single card practice
                        if (_practiceCount > 0 && widget.allCharacters != null && widget.allCharacters!.length == 1)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withValues(alpha: 0.95)
                                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                      ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                                      : Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_practiceCount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                                        : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  ),
                ),
                
                // Practice control buttons (erase, show next, show all) - directly under character box
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Erase button with scale animation
                AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: (_completedStrokeIndices.isEmpty && !_showSuccess) ? 0.9 : 1.0,
                  child: TextButton.icon(
                    onPressed: (_completedStrokeIndices.isEmpty && !_showSuccess) ? null : () {
                      HapticService().lightImpact();
                      setState(() {
                        _completedStrokeIndices.clear();
                        _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
                        _userStrokes.clear();
                        _showHintPath = false;
                        _showFullCharacter = false;
                        _showSuccess = false;
                        _showManualGrading = false;
                        _autoGradedAsCorrect = false;
                        _usedHint = false;
                        _missedStrokes = 0;
                        _missedStrokeIndices.clear();
                        _currentStroke.clear();
                        _currentStrokeTimestamps.clear();
                        _autoProceedTimer?.cancel();
                        _progressTimer?.cancel();
                        _timerProgress = 1.0;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Erase'),
                  ),
                ),
                // Show next step button
                TextButton.icon(
                  onPressed: _characterStroke == null || 
                      _completedStrokeIndices.length == _characterStroke!.strokes.length ? null : () {
                    HapticService().lightImpact();
                    setState(() {
                      _showHintPath = true;
                      _usedHint = true;
                    });
                  },
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Next Step'),
                ),
                // Show whole character button
                TextButton.icon(
                  onPressed: _characterStroke == null ? null : () {
                    HapticService().lightImpact();
                    setState(() {
                      _showFullCharacter = !_showFullCharacter;
                      if (_showFullCharacter) _usedHint = true;
                    });
                  },
                  icon: Icon(_showFullCharacter ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showFullCharacter ? 'Hide' : 'Show All'),
                ),
              ],
            ),
                ),
                
                // Manual grading section - always present but visibility controlled
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedOpacity(
              opacity: _showManualGrading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: _showManualGrading ? 1.0 : 0.8,
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showManualGrading ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: _showManualGrading ? () {
                          HapticService().lightImpact();
                          _proceedWithGrade(false);
                        } : null,
                        icon: const Icon(Icons.close),
                        label: const Text('Incorrect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getButtonBackgroundColor(false),
                          foregroundColor: _getButtonForegroundColor(),
                          minimumSize: const Size(140, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: !_autoGradedAsCorrect ? BorderSide(color: _getButtonBorderColor(), width: 3) : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: _showManualGrading ? 1.0 : 0.8,
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showManualGrading ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: _showManualGrading ? () {
                          HapticService().lightImpact();
                          _proceedWithGrade(true);
                        } : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Correct'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getButtonBackgroundColor(true),
                          foregroundColor: _getButtonForegroundColor(),
                          minimumSize: const Size(140, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: _autoGradedAsCorrect ? BorderSide(color: _getButtonBorderColor(), width: 3) : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                ),
              ],
            ),
          ),
          
          // Radical analysis (only in learning mode) - moved to bottom
          if (widget.mode == PracticeMode.learning && 
              _radicalAnalysis != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SimpleRadicalDisplay(
                analysis: _radicalAnalysis!,
              ),
            ),
          
          // Small bottom spacing
          const SizedBox(height: 8),
          ],
        ),
              ),
            );
          },
        ),
      ),
    );
    
    // Wrap with PopScope to handle mid-practice exits
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Don't allow back during tutorial
          if (widget.characterSet == 'Tutorial') {
            return;
          }
          // Show summary if in testing mode and not endless practice
          if (widget.mode == PracticeMode.testing && 
              widget.characterSet != 'Endless Practice' && 
              _totalItemsStudied > 0) {
            _showCompletionDialog();
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: scaffold,
    );
  }

  void _handleStrokeEnd() {
    
    if (_currentStroke.isEmpty || _characterStroke == null) {
      return;
    }
    
    final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    
    final canvasSize = box.size;
    
    final nextIndex = _getNextStrokeIndex();
    
    if (widget.isWord) {
    }
    
    // FIXED: Use same character lookup logic as gesture detection
    final currentCharacter = widget.isWord ? _wordCharacters[_currentWordCharacterIndex] : widget.character;
    
    
    if (nextIndex >= _characterStroke!.strokes.length) {
      setState(() {
        _currentStroke.clear();
        _currentStrokeTimestamps.clear();
        _currentStrokeTimestamps.clear();
      });
      return;
    }
    
    // TEMPORARILY DISABLED: Combined stroke detection
    // TODO: Re-enable when working properly
    /*
    // First check if this might be a combined stroke
    final remainingStrokes = <int>[];
    for (int i = 0; i < _characterStroke!.strokes.length; i++) {
      if (!_completedStrokeIndices.contains(i)) {
        remainingStrokes.add(i);
      }
    }
    
    final combinedMatch = StrokeCombinationRules.checkCombinedStroke(
      currentCharacter,
      _currentStroke,
      remainingStrokes,
      _characterStroke!.medians,
      canvasSize,
    );
    
    if (combinedMatch != null) {
      // Production: removed debug print
      // User drew a valid combined stroke
      setState(() {
        _completedStrokeIndices.addAll(combinedMatch.matchedStrokes);
        _userStrokes.add(List.from(_currentStroke));
        
        if (_completedStrokeIndices.length == _characterStroke!.strokes.length) {
          _onCharacterComplete();
        }
        _currentStroke.clear();
        _currentStrokeTimestamps.clear();
      });
      return;
    }
    */
    
    // Validate single stroke
    bool isCorrect;
    
    // Special handling for problematic characters
    if (currentCharacter == '一' || (currentCharacter == '二' || currentCharacter == '三')) {
      // For horizontal stroke characters, use lenient validation
      final tolerance = 0.60;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    } else if (currentCharacter == '中' && nextIndex == _characterStroke!.strokes.length - 1) {
      // Last stroke of 中 is the long vertical - use extremely simple validation
      isCorrect = _validateZhongLastStroke(_currentStroke, canvasSize);
    } else if (currentCharacter == '中') {
      // Other strokes of 中 - extremely lenient
      final tolerance = 0.55;  // Strict tolerance for both modes
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    } else if (currentCharacter == '女' && nextIndex == 1) {
      // For 女 stroke 1 (second stroke - diagonal pie stroke), use very lenient validation
      final tolerance = 0.65;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: true, // Treat as multi-directional for the slight curve
      );
    } else if (currentCharacter == '我' && (nextIndex == 1 || nextIndex == 4)) {
      // For 我, strokes 1 and 4 - use high tolerance
      final tolerance = 0.45;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    } else if (currentCharacter == '马' || currentCharacter == '七') {
      // For multi-directional characters like 马 and 七, use more lenient tolerance
      final tolerance = 0.45;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: true,
      );
    } else if (currentCharacter == '门' && nextIndex == 2) {
      // Special case for 门 - the right vertical stroke (index 2) is very difficult
      final tolerance = 0.60;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    } else if ((currentCharacter == '事' || currentCharacter == '中' || currentCharacter == '十' || 
                currentCharacter == '丰' || currentCharacter == '串' || currentCharacter == '午' || 
                currentCharacter == '年' || currentCharacter == '半' || currentCharacter == '门') && 
                _isLongVerticalStroke(nextIndex)) {
      // Characters with prominent vertical strokes need extreme tolerance
      final tolerance = 0.50;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    } else if (_isHorizontalStroke(nextIndex)) {
      // Horizontal strokes need lenient validation
      final tolerance = 0.55;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    } else if (_isDiagonalStroke(nextIndex)) {
      // Diagonal strokes (pie strokes) need more lenient validation
      final tolerance = 0.60;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: true, // Treat as multi-directional for potential slight curves
      );
    } else if (_isMultiDirectionalStroke(nextIndex)) {
      // Multi-directional strokes need special handling
      final tolerance = 0.45;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: true,
      );
    } else {
      // All other strokes - use high default tolerance
      final tolerance = 0.45;
      isCorrect = StrokeValidator.validateStroke(
        _currentStroke,
        _characterStroke!.medians[nextIndex],
        canvasSize,
        tolerance: tolerance,
        isMultiDirectional: false,
      );
    }
    
    final currentCharacterName = widget.isWord ? _wordCharacters[_currentWordCharacterIndex] : widget.character;
    
    setState(() {
      if (isCorrect) {
        HapticService().ultraLight(); // Ultra light haptic for correct stroke
        // Calculate deviation for animation
        _strokeDeviation = _calculateStrokeDeviation(_currentStroke, _characterStroke!.medians[nextIndex], canvasSize);
        
        _completedStrokeIndices.add(nextIndex);
        _userStrokes.add(List.from(_currentStroke));
        _showHintPath = false; // Hide hint after successful stroke
        
        
        // Trigger bounce animation
        _startBounceAnimation(nextIndex);
        
        if (_completedStrokeIndices.length == _characterStroke!.strokes.length) {
          _onCharacterComplete();
        }
      } else {
        _wrongAttempts[nextIndex]++;
        
        // Track if this is the first time missing this stroke
        if (_wrongAttempts[nextIndex] == 1) {
          _missedStrokeIndices.add(nextIndex);
          _missedStrokes = _missedStrokeIndices.length;
          
          // Check if we've missed 2 different strokes - mark for failure but continue
          if (_missedStrokeIndices.length >= 2) {
            // Don't stop here - let user complete the character
          }
        }
        
        // Check if it's a direction error
        final isDirectionError = _checkDirectionError(_currentStroke, nextIndex);
        
        // Show hint automatically after 3 wrong attempts on the same stroke
        if (_wrongAttempts[nextIndex] >= 3) {
          _showHintPath = true;
        }
        
        // Removed snackbar notification to prevent render overflow
      }
      
      _currentStroke.clear();
      _currentStrokeTimestamps.clear();
    });
    
    // Force UI update after a frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
      }
    });
  }
  
  int _getNextStrokeIndex() {
    for (int i = 0; i < (_characterStroke?.strokes.length ?? 0); i++) {
      if (!_completedStrokeIndices.contains(i)) return i;
    }
    return _characterStroke?.strokes.length ?? 0;
  }
  
  bool _shouldShowHint() {
    final nextIndex = _getNextStrokeIndex();
    return nextIndex < _wrongAttempts.length && _wrongAttempts[nextIndex] >= 3;
  }
  
  bool _shouldShowOutline() {
    if (widget.mode == PracticeMode.testing) {
      return false; // Never show outline in testing mode
    }
    if (widget.mode == PracticeMode.learning) {
      return _learningStage <= 1 && _showGuide; // Show in stages 0 and 1
    }
    return _showGuide;
  }
  
  Color _getProgressColor() {
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    
    if (_completedStrokeIndices.length == _characterStroke?.strokes.length) {
      if (duotoneTheme?.isDuotoneTheme == true) {
        // For duotone, use a darker variant of the foreground color
        final foregroundColor = duotoneTheme!.duotoneColor2!;
        final hslColor = HSLColor.fromColor(foregroundColor);
        return hslColor.withLightness((hslColor.lightness * 0.7).clamp(0.0, 1.0)).toColor();
      }
      return Theme.of(context).colorScheme.primary;
    } else if (_completedStrokeIndices.isNotEmpty) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.outline;
  }
  
  void _onCharacterComplete() {
    HapticService().mediumImpact(); // Medium haptic for character completion
    // Check if this is individual character practice of an already learned character
    final isIndividualPractice = widget.allCharacters != null && widget.allCharacters!.length == 1;
    final isLearnedCharacter = widget.mode == PracticeMode.testing && isIndividualPractice;
    
    // In learning mode, just proceed without grading
    if (widget.mode == PracticeMode.learning) {
      // Don't show success color, just proceed immediately
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _proceedWithGrade(true); // Always treat as correct in learning mode
        }
      });
      return;
    }
    
    // For individual practice of learned characters, just reset for continuous practice
    if (isLearnedCharacter) {
      // Determine if the character was completed correctly
      final wasCorrect = !_usedHint && _missedStrokeIndices.length < 2;
      
      setState(() {
        _showSuccess = true;
        _autoGradedAsCorrect = wasCorrect;
      });
      
      // Reset after a short delay to allow user to see the completed character
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          // For multi-character words, check if we need to move to next character
          if (widget.isWord && _wordCharacters.length > 1) {
            // Always move to next character, cycling through (1→2→1→2 pattern)
            final nextCharacterIndex = (_currentWordCharacterIndex + 1) % _wordCharacters.length;
            
            // Track the result for this character
            _wordCharacterResults[_currentWordCharacterIndex] = wasCorrect;
            
            // Increment practice count each time we complete any character
            _practiceCount++;
            
            setState(() {
              _currentWordCharacterIndex = nextCharacterIndex;
              // Clear results if we're starting a new cycle
              if (nextCharacterIndex == 0) {
                _wordCharacterResults.clear();
              }
              _completedStrokeIndices.clear();
              _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
              _userStrokes.clear();
              _showHintPath = false;
              _showFullCharacter = false;
              _usedHint = false;
              _missedStrokes = 0;
              _missedStrokeIndices.clear();
              _showSuccess = false;
              _showManualGrading = false;
              _testingCharacterRevealed = false;
              _strokeDeviation = 0.0;
              _autoGradedAsCorrect = false;
              _loadCharacterData();
            });
          } else {
            // Single character, just reset
            _practiceCount++;
            setState(() {
              _completedStrokeIndices.clear();
              _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
              _userStrokes.clear();
              _showHintPath = false;
              _showFullCharacter = false;
              _usedHint = false;
              _missedStrokes = 0;
              _missedStrokeIndices.clear();
              _showSuccess = false;
              _showManualGrading = false;
              _testingCharacterRevealed = false;
              _strokeDeviation = 0.0;
              _autoGradedAsCorrect = false;
            });
          }
        }
      });
      return;
    }
    
    // Don't save practice data here - wait for manual grading
    
    // Determine auto-grading - fail if missed 2 different strokes
    _autoGradedAsCorrect = !_usedHint && _missedStrokeIndices.length < 2;
    
    // Don't call completion callback here for endless practice
    // It will be called in _proceedWithGrade
    
    // In testing mode, reveal the character
    if (widget.mode == PracticeMode.testing) {
      setState(() {
        _testingCharacterRevealed = true;
        _completedTestCharacters.add(currentCharacter);
      });
    }
    
    // Show success animation and manual grading (testing mode only)
    setState(() {
      _showSuccess = true;
      _showManualGrading = true;
    });
    
    // Force a rebuild to ensure buttons are shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Ensure manual grading is visible
          _showManualGrading = true;
        });
      }
    });
    
    // No automatic progression - user must tap or choose correct/incorrect
  }
  
  Future<void> _saveLearnedCharactersOnExit() async {
    if (widget.allCharacters == null || widget.mode != PracticeMode.learning) return;
    
    // Production: removed debug print
    // Production: removed debug print
    // Production: removed debug print
    
    // Only need to save the current item if we completed stage 2
    // Previous items were already saved when we moved to the next character
    if (_currentCharacterIndex < widget.allCharacters!.length && 
        _learningStage == 2 && 
        _completedStrokeIndices.length == (_characterStroke?.strokes.length ?? 0)) {
      
      final currentItem = widget.allCharacters![_currentCharacterIndex];
      
      // Production: removed debug print
      
      // Check if this is the last stage of learning mode
      if (currentItem.length > 1) {
        final wasLearned = await _learningService.isWordLearned(currentItem);
        // Production: removed debug print
        await _learningService.markWordAsLearned(currentItem);
        final isNowLearned = await _learningService.isWordLearned(currentItem);
        // Production: removed debug print
      } else {
        final wasLearned = await _learningService.isCharacterLearned(currentItem);
        // Production: removed debug print
        await _learningService.markCharacterAsLearned(currentItem);
        final isNowLearned = await _learningService.isCharacterLearned(currentItem);
        // Production: removed debug print
      }
    } else {
      // Production: removed debug print
    }
  }
  
  void _proceedWithGrade(bool wasCorrect) {
    // Skip statistics for learning mode
    if (widget.mode != PracticeMode.learning) {
      // Save practice data only after manual grading
      _savePracticeData(wasCorrect);
      
      // Track session statistics
      final currentItem = widget.isWord ? currentWord : currentCharacter;
      if (!_itemResults.containsKey(currentItem)) {
        _totalItemsStudied++;
      }
      _itemResults[currentItem] = wasCorrect;
      if (wasCorrect) {
        _correctItems++;
        _incorrectItems.remove(currentItem);
      } else {
        if (!_incorrectItems.contains(currentItem)) {
          _incorrectItems.add(currentItem);
        }
      }
      
      // Update statistics based on final grade
      if (!wasCorrect) {
        _usedHint = true; // Mark as incorrect for stats
      }
    }
    
    // Don't immediately hide the success state - keep it visible
    setState(() {
      _showManualGrading = false;
    });
    
    Future.delayed(const Duration(milliseconds: 300), () async {
      // In learning mode, check if we should advance to next stage or next character
      if (widget.mode == PracticeMode.learning && _learningStage < 2) {
        
        // For multi-character words, follow 1-2-1-2-1-2 pattern
        if (widget.isWord && _wordCharacters.length > 1) {
          // Follow 1-2-1-2-1-2 pattern for 2-character words
          final nextCharacterIndex = (_currentWordCharacterIndex + 1) % _wordCharacters.length;
          int nextStage = _learningStage;
          
          // For 2-character words: alternate between stages for each character
          // Pattern: char1-stage0, char2-stage0, char1-stage1, char2-stage1, char1-stage2, char2-stage2
          if (nextCharacterIndex == 0) {
            // We've completed both characters at current stage, advance to next stage
            nextStage = _learningStage + 1;
          }
          
          setState(() {
            _currentWordCharacterIndex = nextCharacterIndex;
            _learningStage = nextStage;
            
            _completedStrokeIndices.clear();
            _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
            _userStrokes.clear();
            _showHintPath = false;
            _showFullCharacter = false;
            _usedHint = false;
            _missedStrokes = 0;
            _showManualGrading = false;
            _showSuccess = false;
            _loadCharacterData();
          });
        } else {
          // Single character - advance to next stage
          setState(() {
            _learningStage++;
            _completedStrokeIndices.clear();
            _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
            _userStrokes.clear();
            _showHintPath = false;
            _showFullCharacter = false;
            _usedHint = false;
            _missedStrokes = 0;
            _showManualGrading = false;
            _showSuccess = false;
          });
        }
        return;
      }
      
      // Check if we should mark the current item as learned
      // This happens when we complete stage 2 successfully in learning mode
      if (widget.mode == PracticeMode.learning && _learningStage == 2 && wasCorrect) {
        // Don't mark as learned here - we'll do it when moving to the next character
        // This ensures we only mark as learned when all 3 stages are complete
        // Production: removed debug print
      }
      
      // Auto-progress to next character (testing mode or completed all stages in learning)
      if (widget.isWord && _wordCharacters.length > 1 && widget.allCharacters != null && widget.allCharacters!.length > 1) {
        // Handle learning mode completion for multi-character words in practice all mode
        if (widget.mode == PracticeMode.learning && _learningStage == 2) {
          final nextCharacterIndex = (_currentWordCharacterIndex + 1) % _wordCharacters.length;
          
          // Check if we've completed a full cycle at stage 2
          if (nextCharacterIndex == 0) {
            
            // Mark as learned
            if (wasCorrect) {
              if (_wordCharacters.length > 1) {
                await _learningService.markWordAsLearned(widget.character);
              } else {
                await _learningService.markCharacterAsLearned(widget.character);
              }
            }
            
            // Exit practice
            if (mounted) {
              // Refresh progress before exiting
              try {
                refreshSetsProgress();
              } catch (_) {
                // Ignore if main screen is not available
              }
              Navigator.pop(context);
            }
            return;
          } else {
            // Continue to next character in stage 2
            setState(() {
              _currentWordCharacterIndex = nextCharacterIndex;
              _completedStrokeIndices.clear();
              _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
              _userStrokes.clear();
              _showHintPath = false;
              _showFullCharacter = false;
              _usedHint = false;
              _missedStrokes = 0;
              _showManualGrading = false;
              _showSuccess = false;
              _loadCharacterData();
            });
            return;
          }
        }
        
        // For testing mode - only do infinite cycling if practicing a single word
        if (widget.allCharacters == null || widget.allCharacters!.length == 1) {
          // Single word continuous practice - cycle through characters infinitely
          final nextCharacterIndex = (_currentWordCharacterIndex + 1) % _wordCharacters.length;
          
          setState(() {
          // Track the result for this character
          _wordCharacterResults[_currentWordCharacterIndex] = wasCorrect;
          _currentWordCharacterIndex = nextCharacterIndex;
          
          // Clear results if we're starting a new cycle
          if (nextCharacterIndex == 0) {
            _wordCharacterResults.clear();
          }
          
          // Don't reset learning stage in testing mode
          if (widget.mode != PracticeMode.learning) {
            _learningStage = 0;
          }
          
          // Clear all visual state immediately
          _completedStrokeIndices.clear();
          _userStrokes.clear();
          _currentStroke.clear();
        _currentStrokeTimestamps.clear();
          _showSuccess = false;
          _showManualGrading = false;
          _autoGradedAsCorrect = false;
          _testingCharacterRevealed = false;
          _showHintPath = false;
          _showFullCharacter = false;
          _usedHint = false;
          _missedStrokes = 0;
          _strokeDeviation = 0.0;
          _autoProceedTimer?.cancel();
          _progressTimer?.cancel();
          _timerProgress = 1.0;
          
          _loadCharacterData();
        });
          return; // Exit here for single word practice
        }
      }
      
      // Handle multi-character word progression in practice all mode
      if (widget.isWord && _wordCharacters.length > 1) {
        // Handle multi-character word progression in practice all mode
        if (_currentWordCharacterIndex < _wordCharacters.length - 1) {
          setState(() {
            // Track the result for this character
            _wordCharacterResults[_currentWordCharacterIndex] = wasCorrect;
            _currentWordCharacterIndex++;
            _learningStage = 0; // Reset to stage 0 for new character
            
            // Clear all visual state immediately
            _completedStrokeIndices.clear();
            _userStrokes.clear();
            _currentStroke.clear();
        _currentStrokeTimestamps.clear();
            _showSuccess = false;
            _showManualGrading = false;
            _autoGradedAsCorrect = false;
            _testingCharacterRevealed = false;
            _showHintPath = false;
            _showFullCharacter = false;
            _usedHint = false;
            _missedStrokes = 0;
            _strokeDeviation = 0.0;
            _autoProceedTimer?.cancel();
            _progressTimer?.cancel();
            _timerProgress = 1.0;
            
            _loadCharacterData();
          });
        } else if (widget.allCharacters != null &&
                   _currentCharacterIndex < widget.allCharacters!.length - 1) {
          // Track the result for the last character
          _wordCharacterResults[_currentWordCharacterIndex] = wasCorrect;
          
          // Mark the current item as learned if we completed stage 2 successfully
          if (widget.mode == PracticeMode.learning && _learningStage == 2 && wasCorrect) {
            final completedItem = widget.allCharacters![_currentCharacterIndex];
            
            // Debug: Check current learned status before marking
            if (completedItem.length > 1) {
              final isAlreadyLearned = await _learningService.isWordLearned(completedItem);
              // Production: removed debug print
              await _learningService.markWordAsLearned(completedItem);
              final isNowLearned = await _learningService.isWordLearned(completedItem);
              // Production: removed debug print
            } else {
              final isAlreadyLearned = await _learningService.isCharacterLearned(completedItem);
              // Production: removed debug print
              await _learningService.markCharacterAsLearned(completedItem);
              final isNowLearned = await _learningService.isCharacterLearned(completedItem);
              // Production: removed debug print
            }
          }
          
          // Move to next item in the set
          setState(() {
            _currentCharacterIndex++;
            _currentWordCharacterIndex = 0;
            _wordCharacterResults.clear(); // Clear results for new word
            _learningStage = 0; // Reset to stage 0 for new character
            
            // Clear all visual state immediately
            _completedStrokeIndices.clear();
            _userStrokes.clear();
            _currentStroke.clear();
        _currentStrokeTimestamps.clear();
            _showSuccess = false;
            _showManualGrading = false;
            _autoGradedAsCorrect = false;
            _testingCharacterRevealed = false;
            _showHintPath = false;
            _showFullCharacter = false;
            _usedHint = false;
            _missedStrokes = 0;
            _strokeDeviation = 0.0;
            _autoProceedTimer?.cancel();
            _progressTimer?.cancel();
            _timerProgress = 1.0;
            
            final nextItem = widget.allCharacters![_currentCharacterIndex];
            if (_dictionary.isMultiCharacterItem(nextItem)) {
              _wordCharacters = _dictionary.splitIntoCharacters(nextItem);
            } else {
              _wordCharacters = [nextItem];
            }
            _loadCharacterData();
          });
        } else if (widget.characterSet == 'Endless Practice') {
          // Track the result for the last character
          _wordCharacterResults[_currentWordCharacterIndex] = wasCorrect;
          // For endless practice with multi-character words, call the completion callback
          if (widget.onComplete != null) {
            widget.onComplete!(wasCorrect);
          }
          // Update streak progress for endless practice
          if (wasCorrect) {
            StreakService().updateProgress(1);
          }
          return;
        } else {
          // Track the result for the last character
          _wordCharacterResults[_currentWordCharacterIndex] = wasCorrect;
          
          // Check if this is individual character practice (only one item)
          final isIndividualPractice = widget.allCharacters != null && widget.allCharacters!.length == 1;
          
          if (isIndividualPractice) {
            // For individual character practice, don't show summary
            // Just call the completion callback if provided
            if (widget.onComplete != null) {
              widget.onComplete!(wasCorrect);
            }
            
            // Update streak if successful
            if (wasCorrect) {
              StreakService().updateProgress(1);
            }
            
            // Navigate back
            if (mounted) {
              // Refresh progress before exiting
              try {
                refreshSetsProgress();
              } catch (_) {
                // Ignore if main screen is not available
              }
              Navigator.pop(context);
            }
          } else {
            // Only show completion dialog in testing mode for sets
            if (widget.mode == PracticeMode.testing) {
              _showCompletionDialog();
            } else {
              // In learning mode, mark the set as learned if we completed all characters
              if (widget.allCharacters != null) {
                _learningService.markSetAsLearned(widget.characterSet, widget.allCharacters!);
              }
              // Just exit
              if (mounted) {
                Navigator.pop(context);
              }
            }
          }
        }
      } else if (widget.allCharacters != null &&
          widget.allCharacters!.length > 1 &&
          _currentCharacterIndex < widget.allCharacters!.length - 1) {
        
        // Mark the current item as learned if we completed stage 2 successfully
        if (widget.mode == PracticeMode.learning && _learningStage == 2 && wasCorrect) {
          final completedItem = widget.allCharacters![_currentCharacterIndex];
          
          // Debug: Check current learned status before marking
          if (completedItem.length > 1) {
            final isAlreadyLearned = await _learningService.isWordLearned(completedItem);
            // Production: removed debug print
            await _learningService.markWordAsLearned(completedItem);
            final isNowLearned = await _learningService.isWordLearned(completedItem);
            // Production: removed debug print
          } else {
            final isAlreadyLearned = await _learningService.isCharacterLearned(completedItem);
            // Production: removed debug print
            await _learningService.markCharacterAsLearned(completedItem);
            final isNowLearned = await _learningService.isCharacterLearned(completedItem);
            // Production: removed debug print
          }
          
          // Update streak progress when learning
          StreakService().updateProgress(1);
        }
        
        // Move to next item (could be character or word)
        setState(() {
          _currentCharacterIndex++;
          _learningStage = 0; // Reset to stage 0 for new character
          
          // Clear all visual state immediately
          _completedStrokeIndices.clear();
          _userStrokes.clear();
          _currentStroke.clear();
        _currentStrokeTimestamps.clear();
          _showSuccess = false;
          _showManualGrading = false;
          _autoGradedAsCorrect = false;
          _testingCharacterRevealed = false;
          _showHintPath = false;
          _showFullCharacter = false;
          _usedHint = false;
          _missedStrokes = 0;
          _strokeDeviation = 0.0;
          _autoProceedTimer?.cancel();
          _progressTimer?.cancel();
          _timerProgress = 1.0;
          
          if (widget.isWord) {
            final nextItem = widget.allCharacters![_currentCharacterIndex];
            if (_dictionary.isMultiCharacterItem(nextItem)) {
              _wordCharacters = _dictionary.splitIntoCharacters(nextItem);
            } else {
              _wordCharacters = [nextItem];
            }
          }
          _loadCharacterData();
        });
      } else if (widget.characterSet == 'Endless Practice') {
        // For endless practice, call the completion callback
        if (widget.onComplete != null) {
          widget.onComplete!(wasCorrect);
        }
        // Update streak progress for endless practice
        if (wasCorrect) {
          StreakService().updateProgress(1);
        }
        return;
      } else {
        // Only show completion dialog in testing mode
        if (widget.mode == PracticeMode.testing) {
          _showCompletionDialog();
        } else {
          // In learning mode, mark the set as learned if we completed all characters
          if (widget.allCharacters != null) {
            _learningService.markSetAsLearned(widget.characterSet, widget.allCharacters!);
          }
          // Just exit
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    });
  }
  
  void _savePracticeData(bool wasCorrect) async {
    // Calculate practice duration
    final duration = _practiceStartTime != null 
        ? DateTime.now().difference(_practiceStartTime!) 
        : Duration.zero;
    
    // Calculate total attempts
    final totalAttempts = _wrongAttempts.reduce((a, b) => a + b) + _completedStrokeIndices.length;
    
    // Record statistics - only count after manual grading
    await _statsService.recordPracticeSession(
      character: currentCharacter,
      isWord: widget.isWord && _wordCharacters.length > 1,
      success: wasCorrect,
      duration: duration,
      attempts: totalAttempts,
      usedHint: _usedHint,
    );
    
    // Save to local storage as well
    await _storageService.savePracticeData({
      'character': currentCharacter,
      'characterSet': widget.characterSet,
      'completed': true,
      'wrongAttempts': _wrongAttempts.reduce((a, b) => a + b),
      'practiceTime': DateTime.now().toIso8601String(),
      'duration': duration.inSeconds,
      'attempts': totalAttempts,
      'usedHint': _usedHint,
      'successRate': wasCorrect ? 1.0 : 0.0,
    });
  }
  
  void _saveSessionSummary(int totalCards, int correctCards, Duration sessionDuration) async {
    // Save session summary data
    await _storageService.savePracticeData({
      'characterSet': widget.characterSet,
      'isSessionSummary': true,
      'totalCards': totalCards,
      'correctCards': correctCards,
      'duration': sessionDuration.inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      'successRate': totalCards > 0 ? correctCards / totalCards : 0.0,
    });
  }
  
  void _showCompletionDialog() {
    // Calculate statistics
    final totalItems = _totalItemsStudied;
    final correctCount = _itemResults.values.where((v) => v).length;
    final incorrectCount = _itemResults.values.where((v) => !v).length;
    final percentage = totalItems > 0 ? (correctCount / totalItems * 100).round() : 0;
    final sessionDuration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!) 
        : Duration.zero;
    
    // Save session summary data
    _saveSessionSummary(totalItems, correctCount, sessionDuration);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              percentage >= 80 ? Icons.star : Icons.check_circle,
              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                  : (percentage >= 80 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(width: 8),
            const Text('Practice Complete!'),
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
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                            : (percentage >= 80 
                                ? Theme.of(context).colorScheme.primary
                                : percentage >= 60 
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.error),
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
              _buildStatRow(Icons.check_circle, 'Correct', '$correctCount', 
                Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                  : Theme.of(context).colorScheme.primary),
              _buildStatRow(Icons.cancel, 'Incorrect', '$incorrectCount', 
                Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.6)
                  : Theme.of(context).colorScheme.error),
              _buildStatRow(Icons.format_list_numbered, 'Total Items', '$totalItems', Theme.of(context).colorScheme.primary),
              _buildStatRow(Icons.timer, 'Time', _formatDuration(sessionDuration), 
                Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                  : Theme.of(context).colorScheme.secondary),
              
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
                    backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.errorContainer,
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
          TextButton.icon(
            onPressed: () => _retestAll(),
            icon: const Icon(Icons.replay),
            label: const Text('Retest All'),
          ),
          if (_incorrectItems.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () => _practiceIncorrect(),
              icon: const Icon(Icons.refresh),
              label: const Text('Practice Incorrect'),
            ),
            TextButton.icon(
              onPressed: () => _createCustomSetFromIncorrect(),
              icon: const Icon(Icons.add_box),
              label: const Text('Create Set from Incorrect'),
            ),
          ],
          FilledButton(
            onPressed: () {
              // Refresh progress before exiting
              try {
                refreshSetsProgress();
              } catch (_) {
                // Ignore if main screen is not available
              }
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
    HapticService().lightImpact();
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WritingPracticePage(
          character: _incorrectItems.first,
          characterSet: widget.characterSet,
          allCharacters: _incorrectItems,
          isWord: widget.isWord,
          mode: widget.mode,
        ),
      ),
    );
  }
  
  void _retestAll() {
    // Get all the original characters/words that were practiced
    final allItems = widget.allCharacters ?? [widget.character];
    
    HapticService().lightImpact();
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WritingPracticePage(
          character: allItems.first,
          characterSet: widget.characterSet,
          allCharacters: allItems,
          isWord: widget.isWord,
          mode: widget.mode,
        ),
      ),
    );
  }
  
  Future<void> _createCustomSetFromIncorrect() async {
    // First, close the current dialog
    Navigator.of(context).pop();
    
    // Show dialog to get set name
    final TextEditingController nameController = TextEditingController();
    final baseName = '${widget.characterSet} - Review';
    nameController.text = baseName;
    
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
    
    // Save custom set
    final customSets = prefs.getStringList('custom_sets') ?? [];
    final setData = {
      'id': setId,
      'name': setName,
      'characters': _incorrectItems,
      'isWordSet': widget.isWord,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    customSets.add(jsonEncode(setData));
    await prefs.setStringList('custom_sets', customSets);
    
    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created custom set: $setName'),
          backgroundColor: _getSuccessColor(),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to home and then to sets tab
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Use a post-frame callback to navigate after the current frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToCustomSets();
              });
            },
          ),
        ),
      );
      
      // Navigate back to home
      Navigator.of(context).pop();
    }
  }
  
  void _navigateToCustomSets() {
    // Just pop back to the previous screen
    if (mounted) {
      // Pop all the way back
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Created custom set: ${widget.characterSet}'),
            backgroundColor: _getSuccessColor(),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to sets tab
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  
  Widget _buildWordPronunciation() {
    // Get pronunciation for the word
    String? pinyin;
    String? definition;
    
    if (_cedictService.isLoaded) {
      final cedictEntry = _cedictService.lookup(currentWord);
      if (cedictEntry != null) {
        pinyin = PinyinUtils.convertToneNumbersToMarks(cedictEntry.pinyin);
        definition = cedictEntry.definition;
      }
    }
    
    if (pinyin == null || definition == null) {
      final wordInfo = _dictionary.getWordInfo(currentWord);
      pinyin ??= wordInfo?.pinyin != null ? PinyinUtils.convertToneNumbersToMarks(wordInfo!.pinyin) : null;
      definition ??= wordInfo?.definition;
    }
    
    if (pinyin == null && definition == null) return const SizedBox.shrink();
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (pinyin != null)
            Text(
              pinyin,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
          if (definition != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                definition,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildWordProgressBoxes() {
    // Just the progress boxes for multi-character words
    if (_wordCharacters.length <= 1) return const SizedBox.shrink();
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_wordCharacters.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minWidth: 48),
            decoration: BoxDecoration(
              border: Border.all(
                color: index == _currentWordCharacterIndex && !_showSuccess
                    ? Theme.of(context).colorScheme.primary
                    : (index < _currentWordCharacterIndex || 
                       (index == _currentWordCharacterIndex && _showSuccess))
                        ? (widget.mode == PracticeMode.learning || _wordCharacterResults[index] == true 
                            ? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                                : Theme.of(context).colorScheme.primary)
                            : (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.6)
                                : Theme.of(context).colorScheme.error))
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: (index == _currentWordCharacterIndex && !_showSuccess) ? 3 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              color: (index < _currentWordCharacterIndex || 
                      (index == _currentWordCharacterIndex && _showSuccess))
                  ? (widget.mode == PracticeMode.learning || _wordCharacterResults[index] == true 
                      ? (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3))
                      : (Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.05)
                          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)))
                  : null,
            ),
            child: Center(
              child: Text(
                (index < _currentWordCharacterIndex || 
                 (index == _currentWordCharacterIndex && _showSuccess)) 
                    ? _wordCharacters[index] 
                    : '_',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: index == _currentWordCharacterIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
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
      if (charInfo != null && charInfo.pinyin != null) {
        pinyinParts.add(PinyinUtils.convertToneNumbersToMarks(charInfo.pinyin));
        continue;
      }
      
      // If no pinyin found for this character, return null
      return null;
    }
    
    // Join all pinyin parts with spaces
    return pinyinParts.join(' ');
  }
  
  Widget _buildCharacterInfoSection() {
    // Try CEDICT first, then fall back to dictionary
    CharacterInfo? charInfo;
    String? pinyin;
    String? definition;
    
    // Check if this is continuous practice mode
    final isIndividualPractice = widget.allCharacters != null && widget.allCharacters!.length == 1;
    final isContinuousPractice = widget.mode == PracticeMode.testing && isIndividualPractice;
    
    // For multi-character words, show the full word definition
    if (widget.isWord && _wordCharacters.length > 1) {
      if (_cedictService.isLoaded) {
        final cedictEntry = _cedictService.lookup(currentWord);
        if (cedictEntry != null) {
          pinyin = PinyinUtils.convertToneNumbersToMarks(cedictEntry.pinyin);
          definition = cedictEntry.definition;
        } else {
          // If multi-character term has no CEDICT entry, build pinyin from individual characters
          pinyin = _buildPinyinFromCharacters(currentWord);
        }
      }
      
      if (pinyin == null || definition == null) {
        final wordInfo = _dictionary.getWordInfo(currentWord);
        pinyin ??= wordInfo?.pinyin != null ? PinyinUtils.convertToneNumbersToMarks(wordInfo!.pinyin) : null;
        definition ??= wordInfo?.definition;
        
        // If still no pinyin and CEDICT is loaded, try building from characters
        if (pinyin == null && _cedictService.isLoaded) {
          pinyin = _buildPinyinFromCharacters(currentWord);
        }
      }
    } else {
      // For single characters, show character definition
      // Looking up character
      if (_cedictService.isLoaded) {
        // CEDICT service is loaded
        final cedictEntry = _cedictService.lookup(currentCharacter);
        if (cedictEntry != null) {
          pinyin = PinyinUtils.convertToneNumbersToMarks(cedictEntry.pinyin);
          definition = cedictEntry.definition;
          // Found in CEDICT
        } else {
          // Not found in CEDICT
          // For multi-character strings labeled as single character, try building pinyin
          if (currentCharacter.length > 1) {
            pinyin = _buildPinyinFromCharacters(currentCharacter);
          }
        }
      } else {
        // CEDICT service not loaded
      }
      
      if (pinyin == null || definition == null) {
        // Falling back to CharacterDictionary
        charInfo = _dictionary.getCharacterInfo(currentCharacter);
        if (charInfo != null) {
          pinyin ??= charInfo.pinyin != null ? PinyinUtils.convertToneNumbersToMarks(charInfo.pinyin) : null;
          definition ??= charInfo.definition;
          // Found in CharacterDictionary
        } else {
          // Not found in CharacterDictionary either
        }
      }
    }
    
    if (widget.mode == PracticeMode.testing) {
      // Testing mode: show pronunciation and definition, hide character
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            // Character reveal box - only show for single characters
            if (!widget.isWord || _wordCharacters.length <= 1)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _testingCharacterRevealed 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                ),
                child: Center(
                  child: Text(
                    _testingCharacterRevealed ? currentCharacter : ' ',
                    style: TextStyle(
                      fontSize: _testingCharacterRevealed ? 48 : 36,
                      fontWeight: FontWeight.w300,
                      color: _testingCharacterRevealed 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            // Pronunciation and definition
            if (pinyin != null && definition != null) ...[
              Text(
                pinyin,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                definition,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                pinyin ?? '',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                definition ?? 'No definition available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    
    // Learning mode: show pronunciation and definition
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pinyin ?? '',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            definition ?? 'No definition available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Check if the stroke error is due to wrong direction
  bool _checkDirectionError(List<Offset> userStroke, int strokeIndex) {
    if (_characterStroke == null || userStroke.length < 2) return false;
    
    final medians = _characterStroke!.medians[strokeIndex];
    if (medians.length < 2) return false;
    
    // Get canvas size for normalization
    final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    
    final canvasSize = box.size;
    // Use rounded calculations to avoid floating-point precision issues
    final paddingInt = (canvasSize.width * 0.08).round();
    final padding = paddingInt.toDouble();
    final drawSize = canvasSize.width.round() - (paddingInt * 2);
    
    // Normalize user stroke
    final normalizedUser = userStroke.map((p) => Offset(
      (p.dx - padding) / drawSize,
      (p.dy - padding) / drawSize,
    )).toList();
    
    // Normalize median points
    final normalizedMedian = medians.map((p) => 
      Offset(p[0] / 1024, (1024 - p[1]) / 1024)
    ).toList();
    
    // Check if start and end are swapped (indicating wrong direction)
    final startToStart = (normalizedUser.first - normalizedMedian.first).distance;
    final startToEnd = (normalizedUser.first - normalizedMedian.last).distance;
    final endToEnd = (normalizedUser.last - normalizedMedian.last).distance;
    final endToStart = (normalizedUser.last - normalizedMedian.first).distance;
    
    // If user's start is closer to median's end and user's end is closer to median's start
    return (startToEnd < startToStart * 0.7) && (endToStart < endToEnd * 0.7);
  }
  
  // Get direction hint for a stroke
  String _getDirectionHint(int strokeIndex) {
    if (_characterStroke == null) return "start to end";
    
    final medians = _characterStroke!.medians[strokeIndex];
    if (medians.length < 2) return "start to end";
    
    final start = medians.first;
    final end = medians.last;
    
    // Determine primary direction
    final dx = end[0] - start[0];
    final dy = end[1] - start[1]; // Note: Y is already flipped in display
    
    String direction = "";
    
    // Vertical component
    if (dy.abs() > dx.abs() * 0.5) {
      direction += dy > 0 ? "bottom" : "top";
    }
    
    // Horizontal component
    if (dx.abs() > dy.abs() * 0.5) {
      if (direction.isNotEmpty) direction += " ";
      direction += dx > 0 ? "right" : "left";
    }
    
    // If no clear direction, use general terms
    if (direction.isEmpty) {
      direction = "start";
    }
    
    return "$direction to ${_getOppositeDirection(direction)}";
  }
  
  String _getOppositeDirection(String direction) {
    final opposites = {
      'top': 'bottom',
      'bottom': 'top',
      'left': 'right',
      'right': 'left',
      'top left': 'bottom right',
      'top right': 'bottom left',
      'bottom left': 'top right',
      'bottom right': 'top left',
    };
    return opposites[direction] ?? 'end';
  }
  
  bool _canCombineCurrentStroke() {
    if (_characterStroke == null) return false;
    
    final remainingStrokes = <int>[];
    for (int i = 0; i < _characterStroke!.strokes.length; i++) {
      if (!_completedStrokeIndices.contains(i)) {
        remainingStrokes.add(i);
      }
    }
    
    final groups = StrokeCombinationRules.getCombinableGroups(currentCharacter);
    for (final group in groups) {
      if (group.every((index) => remainingStrokes.contains(index))) {
        return true;
      }
    }
    
    return false;
  }
  
  // Special validation for 女 strokes 1 and 2 - more balanced validation
  bool _validateZhongLastStroke(List<Offset> userStroke, Size canvasSize) {
    if (userStroke.length < 2) return false;
    
    // Extremely simple validation for 中's last vertical stroke
    final start = userStroke.first;
    final end = userStroke.last;
    final direction = end - start;
    
    // Just check if it's going downward and has some length
    final isDownward = direction.dy > 0; // Going down
    final isLongEnough = direction.distance > canvasSize.height * 0.1; // Just 10% of canvas height
    
    // Extremely lenient vertical check - just needs to be more vertical than horizontal
    final isVerticalish = direction.dy.abs() > direction.dx.abs() * 0.5;
    
    return isDownward && isLongEnough && isVerticalish;
  }
  
  bool _validateNvStroke(List<Offset> userStroke, List<List<double>> medianPoints, Size canvasSize) {
    if (userStroke.length < 10 || medianPoints.length < 3) return false;
    
    // First check if stroke is too small
    final userBounds = _getBoundingBox(userStroke);
    final minStrokeSize = canvasSize.width * 0.05; // Reduced to 5% for more leniency
    
    if (userBounds.width < minStrokeSize || userBounds.height < minStrokeSize) {
      // Production: removed debug print
      return false;
    }
    
    // Avoid excessive rounding to prevent distortion on real devices
    final padding = canvasSize.width * 0.08;
    final drawSize = canvasSize.width - (padding * 2);
    final scale = drawSize / 1024.0 * 1.05; // Match character_stroke_service scaling
    final scaledSize = 1024 * scale;
    final offsetX = (canvasSize.width - scaledSize) / 2;
    final offsetY = (canvasSize.height - scaledSize) / 2 - (canvasSize.height * 0.08);
    
    // Convert median points to canvas coordinates
    final canvasMedians = medianPoints.map((p) => Offset(
      p[0] * scale + offsetX,
      (1024 - p[1]) * scale + offsetY,
    )).toList();
    
    // Balanced location tolerance
    final strokeSize = math.max(userBounds.width, userBounds.height) / canvasSize.width;
    final sizeFactor = strokeSize > 0.3 ? 1.2 : 1.0; // Slight scaling for large strokes
    final locationTolerance = canvasSize.width * 0.06 * sizeFactor; // 6% tolerance
    
    // Check shape by analyzing the stroke's direction changes
    final userDirection = userStroke.last - userStroke.first;
    final expectedDirection = canvasMedians.last - canvasMedians.first;
    
    // Normalize directions
    final userDirNorm = userDirection / userDirection.distance;
    final expectedDirNorm = expectedDirection / expectedDirection.distance;
    
    // Check if general direction matches (dot product)
    final directionMatch = userDirNorm.dx * expectedDirNorm.dx + 
                          userDirNorm.dy * expectedDirNorm.dy;
    
    // Require good direction match
    if (directionMatch < 0.85) {
      return false; // Wrong general direction
    }
    
    // Check start and end points must be very close
    final startDist = (userStroke.first - canvasMedians.first).distance;
    final endDist = (userStroke.last - canvasMedians.last).distance;
    
    // Must start and end very close to expected positions
    if (startDist > locationTolerance || endDist > locationTolerance) {
      // Production: removed debug print
      return false;
    }
    
    // Check stroke length relative to expected
    final userLength = _calculatePathLength(userStroke);
    final expectedLength = _calculatePathLength(canvasMedians);
    final lengthRatio = userLength / expectedLength;
    
    // Stroke must be very similar length
    if (lengthRatio < 0.85 || lengthRatio > 1.2) {
      return false;
    }
    
    // Get expected bounds for size comparison
    final expectedBounds = _getBoundingBox(canvasMedians);
    
    // Check absolute size requirements
    final expectedWidth = expectedBounds.width;
    final expectedHeight = expectedBounds.height;
    
    // User stroke must be at least 60% of expected size - more lenient
    if (userBounds.width < expectedWidth * 0.6 || userBounds.height < expectedHeight * 0.6) {
      // Production: removed debug print
      return false;
    }
    
    // Check if stroke is in wrong location entirely
    final xOffset = (userBounds.center.dx - expectedBounds.center.dx).abs();
    final yOffset = (userBounds.center.dy - expectedBounds.center.dy).abs();
    
    // Maximum allowed offset - more lenient for large strokes
    final maxOffset = canvasSize.width * 0.08 * sizeFactor;
    if (xOffset > maxOffset || yOffset > maxOffset) {
      // Production: removed debug print
      return false;
    }
    
    // Check size similarity - very strict
    final widthRatio = userBounds.width / expectedBounds.width;
    final heightRatio = userBounds.height / expectedBounds.height;
    
    if (widthRatio < 0.7 || widthRatio > 1.3 || heightRatio < 0.7 || heightRatio > 1.3) {
      // Production: removed debug print
      return false;
    }
    
    // Check area - prevent tiny strokes
    final userArea = userBounds.width * userBounds.height;
    final expectedArea = expectedBounds.width * expectedBounds.height;
    final areaRatio = userArea / expectedArea;
    
    if (areaRatio < 0.5) {
      // Production: removed debug print
      return false;
    }
    
    // Check shape by sampling many points along the path
    int matchedPoints = 0;
    double totalDeviation = 0;
    double maxDeviation = 0;
    final sampleCount = 20; // Many more samples
    
    for (int i = 0; i < sampleCount; i++) {
      final t = i / (sampleCount - 1);
      final userIndex = (userStroke.length * t).round().clamp(0, userStroke.length - 1);
      final medianIndex = (canvasMedians.length * t).round().clamp(0, canvasMedians.length - 1);
      
      final userPoint = userStroke[userIndex];
      final medianPoint = canvasMedians[medianIndex];
      final distance = (userPoint - medianPoint).distance;
      
      totalDeviation += distance;
      if (distance > maxDeviation) maxDeviation = distance;
      
      if (distance < locationTolerance) {
        matchedPoints++;
      }
    }
    
    // Require at least 90% of sampled points to match
    if (matchedPoints < sampleCount * 0.9) {
      // Production: removed debug print
      return false;
    }
    
    // Average deviation must be very small
    final avgDeviation = totalDeviation / sampleCount;
    if (avgDeviation > locationTolerance * 0.6) {
      // Production: removed debug print
      return false;
    }
    
    // No single point should deviate too much
    if (maxDeviation > locationTolerance * 2) {
      // Production: removed debug print
      return false;
    }
    
    // Check curvature at key points
    if (userStroke.length >= 20 && canvasMedians.length >= 10) {
      // Sample curvature at quarter points
      for (double fraction in [0.25, 0.5, 0.75]) {
        final userIdx = (userStroke.length * fraction).round();
        final medianIdx = (canvasMedians.length * fraction).round();
        
        if (!_checkLocalCurvature(userStroke, userIdx, canvasMedians, medianIdx)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  Rect _getBoundingBox(List<Offset> points) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  bool _checkLocalCurvature(List<Offset> userStroke, int userIdx, 
                           List<Offset> medianStroke, int medianIdx) {
    // Check if the local curvature direction matches
    final lookback = 3;
    final lookahead = 3;
    
    if (userIdx - lookback < 0 || userIdx + lookahead >= userStroke.length ||
        medianIdx - lookback < 0 || medianIdx + lookahead >= medianStroke.length) {
      return true; // Skip if not enough points
    }
    
    // Get local tangent vectors
    final userBefore = userStroke[userIdx] - userStroke[userIdx - lookback];
    final userAfter = userStroke[userIdx + lookahead] - userStroke[userIdx];
    
    final medianBefore = medianStroke[medianIdx] - medianStroke[medianIdx - lookback];
    final medianAfter = medianStroke[medianIdx + lookahead] - medianStroke[medianIdx];
    
    // Calculate turn angles (cross product)
    final userTurn = userBefore.dx * userAfter.dy - userBefore.dy * userAfter.dx;
    final medianTurn = medianBefore.dx * medianAfter.dy - medianBefore.dy * medianAfter.dx;
    
    // Signs should match (same turn direction)
    return userTurn * medianTurn >= 0;
  }
  
  double _calculatePathLength(List<Offset> points) {
    if (points.length < 2) return 0;
    double length = 0;
    for (int i = 1; i < points.length; i++) {
      length += (points[i] - points[i-1]).distance;
    }
    return length;
  }
  
  double _calculateStrokeDeviation(List<Offset> userStroke, List<List<double>> medianPoints, Size canvasSize) {
    if (userStroke.length < 2 || medianPoints.length < 2) return 0.0;
    
    // Account for padding when normalizing
    // Avoid excessive rounding to prevent distortion on real devices
    final padding = canvasSize.width * 0.08;
    final drawSize = canvasSize.width - (padding * 2);
    final scale = drawSize / 1024.0 * 1.05; // Match character_stroke_service scaling
    
    // Calculate average deviation
    double totalDeviation = 0.0;
    int samples = math.min(10, math.min(userStroke.length, medianPoints.length));
    
    for (int i = 0; i < samples; i++) {
      final userIndex = (userStroke.length * i / samples).round().clamp(0, userStroke.length - 1);
      final medianIndex = (medianPoints.length * i / samples).round().clamp(0, medianPoints.length - 1);
      
      final userPoint = userStroke[userIndex];
      final scaledSize = 1024 * scale;
      final offsetX = (canvasSize.width - scaledSize) / 2;
      final offsetY = (canvasSize.height - scaledSize) / 2 - (canvasSize.height * 0.08);
      
      final medianPoint = Offset(
        medianPoints[medianIndex][0] * scale + offsetX,
        (1024 - medianPoints[medianIndex][1]) * scale + offsetY,
      );
      
      totalDeviation += (userPoint - medianPoint).distance;
    }
    
    // Return normalized deviation (0.0 to 1.0)
    return (totalDeviation / samples / canvasSize.width).clamp(0.0, 0.3);
  }
  
  bool _isMultiDirectionalStroke(int strokeIndex) {
    if (_characterStroke == null || strokeIndex >= _characterStroke!.medians.length) return false;
    
    final medianPoints = _characterStroke!.medians[strokeIndex];
    if (medianPoints.length < 4) return false; // Need enough points to detect real curves
    
    // Check overall stroke direction first
    final start = Offset(medianPoints.first[0], medianPoints.first[1]);
    final end = Offset(medianPoints.last[0], medianPoints.last[1]);
    final overallDirection = end - start;
    
    // Check for significant direction changes in the stroke
    bool hasSignificantTurn = false;
    for (int i = 1; i < medianPoints.length - 1; i++) {
      final p1 = Offset(medianPoints[i-1][0], medianPoints[i-1][1]);
      final p2 = Offset(medianPoints[i][0], medianPoints[i][1]);
      final p3 = Offset(medianPoints[i+1][0], medianPoints[i+1][1]);
      
      final dir1 = p2 - p1;
      final dir2 = p3 - p2;
      
      // Both segments need meaningful length
      if (dir1.distance > 20 && dir2.distance > 20) {
        final dot = (dir1.dx * dir2.dx + dir1.dy * dir2.dy) / (dir1.distance * dir2.distance);
        if (dot < -0.5) { // Only count very sharp turns (> 120 degrees)
          hasSignificantTurn = true;
          break;
        }
      }
    }
    
    // Also check if the middle deviates significantly from a straight line
    if (!hasSignificantTurn && medianPoints.length >= 5) {
      final midIndex = medianPoints.length ~/ 2;
      final midPoint = Offset(medianPoints[midIndex][0], medianPoints[midIndex][1]);
      
      // Project midpoint onto the straight line from start to end
      if (overallDirection.distance > 0) {
        final t = ((midPoint - start).dx * overallDirection.dx + 
                   (midPoint - start).dy * overallDirection.dy) / 
                   (overallDirection.distance * overallDirection.distance);
        final projectedPoint = start + overallDirection * t.clamp(0.0, 1.0);
        final deviation = (midPoint - projectedPoint).distance;
        
        // Only consider multi-directional if deviation is very significant (> 25% of stroke length)
        if (deviation > overallDirection.distance * 0.25) {
          hasSignificantTurn = true;
        }
      }
    }
    
    return hasSignificantTurn;
  }
  
  bool _isLongVerticalStroke(int strokeIndex) {
    if (_characterStroke == null || strokeIndex >= _characterStroke!.medians.length) return false;
    
    final medianPoints = _characterStroke!.medians[strokeIndex];
    if (medianPoints.length < 2) return false;
    
    // Check if stroke is vertical and long
    final start = Offset(medianPoints.first[0], medianPoints.first[1]);
    final end = Offset(medianPoints.last[0], medianPoints.last[1]);
    final direction = end - start;
    
    // Check if primarily vertical (more lenient check)
    final isVertical = direction.dy.abs() > direction.dx.abs() * 1.5;
    
    // Check if it's long (more than 20% of expected character height)
    final strokeLength = direction.distance;
    final isLong = strokeLength > 200; // Much lower threshold to catch more vertical strokes
    
    // Also check if it's the last stroke of the character (often the case for long verticals)
    final isLastStroke = strokeIndex == _characterStroke!.strokes.length - 1;
    
    return isVertical && isLong;
  }
  
  bool _isVerticalStroke(int strokeIndex) {
    if (_characterStroke == null || strokeIndex >= _characterStroke!.medians.length) return false;
    
    final medianPoints = _characterStroke!.medians[strokeIndex];
    if (medianPoints.length < 2) return false;
    
    // Check if stroke is vertical
    final start = Offset(medianPoints.first[0], medianPoints.first[1]);
    final end = Offset(medianPoints.last[0], medianPoints.last[1]);
    final direction = end - start;
    
    // Check if primarily vertical (very lenient check)
    final isVertical = direction.dy.abs() > direction.dx.abs();
    
    return isVertical;
  }
  
  bool _isDiagonalStroke(int strokeIndex) {
    if (_characterStroke == null || strokeIndex >= _characterStroke!.medians.length) return false;
    
    final medianPoints = _characterStroke!.medians[strokeIndex];
    if (medianPoints.length < 2) return false;
    
    // Check if stroke is diagonal
    final start = Offset(medianPoints.first[0], medianPoints.first[1]);
    final end = Offset(medianPoints.last[0], medianPoints.last[1]);
    final direction = end - start;
    
    // Check if it's diagonal (both dx and dy are significant)
    final isDiagonal = direction.dx.abs() > direction.distance * 0.3 && 
                      direction.dy.abs() > direction.distance * 0.3;
    
    // Check if it's top-right to bottom-left (pie stroke)
    final isPieStroke = direction.dx < 0 && direction.dy > 0;
    
    return isDiagonal && isPieStroke;
  }
  
  bool _isHorizontalStroke(int strokeIndex) {
    if (_characterStroke == null || strokeIndex >= _characterStroke!.medians.length) return false;
    
    final medianPoints = _characterStroke!.medians[strokeIndex];
    if (medianPoints.length < 2) return false;
    
    // Check if stroke is horizontal
    final start = Offset(medianPoints.first[0], medianPoints.first[1]);
    final end = Offset(medianPoints.last[0], medianPoints.last[1]);
    final direction = end - start;
    
    // Check if primarily horizontal
    final isHorizontal = direction.dx.abs() > direction.dy.abs() * 2.0;
    
    return isHorizontal;
  }
  
  
  void _startBounceAnimation(int strokeIndex) {
    _bounceController?.dispose();
    
    // Create animation controller with shorter duration
    final duration = Duration(milliseconds: 200 + (_strokeDeviation * 200).round());
    _bounceController = AnimationController(
      duration: duration,
      vsync: this,
    );
    
    // Create bounce animation with gentler curve
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController!,
      curve: Curves.easeOutBack,
    ));
    
    _bouncingStrokeIndex = strokeIndex;
    
    _bounceController!.forward().then((_) {
      if (mounted) {
        setState(() {
          _bouncingStrokeIndex = null;
        });
      }
    });
  }
  
  Widget _buildAppBarTitle() {
    // Check if this is endless practice mode
    final isEndlessPractice = widget.characterSet == 'Endless Practice';
    
    // Show simple title
    String title = widget.characterSet;
    
    // Add progress for endless practice
    if (isEndlessPractice) {
      // Use shorter format for endless practice to prevent overflow
      title = 'Endless (${widget.endlessPracticeCount ?? 1}/∞)';
    } else if (widget.allCharacters != null && widget.allCharacters!.length > 1) {
      // Add progress for regular sets
      title = '$title (${_currentCharacterIndex + 1}/${widget.allCharacters!.length})';
    }
    
    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
  
  Widget _buildLearningModeNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous stage button
        IconButton(
          onPressed: _learningStage > 0 ? () {
            setState(() {
              _learningStage--;
              _completedStrokeIndices.clear();
              _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
              _userStrokes.clear();
              _showHintPath = false;
              _showFullCharacter = false;
              _usedHint = false;
              _missedStrokes = 0;
            });
          } : null,
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
              : null,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use foreground color
              : Theme.of(context).colorScheme.primaryContainer,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Current stage indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Stage ${_learningStage + 1}/3',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Next stage button
        IconButton(
          onPressed: (_learningStage < 2 && 
              _completedStrokeIndices.length == (_characterStroke?.strokes.length ?? 0)) ? () {
            setState(() {
              _learningStage++;
              _completedStrokeIndices.clear();
              _wrongAttempts.fillRange(0, _wrongAttempts.length, 0);
              _userStrokes.clear();
              _showHintPath = false;
              _showFullCharacter = false;
              _usedHint = false;
              _missedStrokes = 0;
              _showManualGrading = false;
              _autoProceedTimer?.cancel();
              _progressTimer?.cancel();
              _timerProgress = 1.0;
            });
          } : null,
          icon: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
              : null,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use foreground color
              : Theme.of(context).colorScheme.primaryContainer,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTestingModeNavigation() {
    // Don't show any manual grading buttons - they're already shown in the manual grading section above
    if (_showSuccess && _characterStroke != null) {
      return const SizedBox.shrink();
    }
    
    // Don't show navigation for endless practice
    if (widget.characterSet == 'Endless Practice') {
      return const SizedBox.shrink();
    }
    
    // Normal navigation when not grading
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: widget.allCharacters != null && _currentCharacterIndex > 0 ? () {
            setState(() {
              _currentCharacterIndex--;
              _loadCharacterData();
            });
          } : null,
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
              : null,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use foreground color
              : Theme.of(context).colorScheme.primaryContainer,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Current position indicator
        if (widget.allCharacters != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentCharacterIndex + 1} / ${widget.allCharacters!.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        
        const SizedBox(width: 16),
        
        // Next button
        IconButton(
          onPressed: widget.allCharacters != null && 
              _currentCharacterIndex < widget.allCharacters!.length - 1 ? () {
            setState(() {
              _currentCharacterIndex++;
              _loadCharacterData();
            });
          } : null,
          icon: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
              : null,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use foreground color
              : Theme.of(context).colorScheme.primaryContainer,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
  
  void _proceedToNext() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.allCharacters != null &&
          _currentCharacterIndex < widget.allCharacters!.length - 1) {
        setState(() {
          _currentCharacterIndex++;
          _loadCharacterData();
        });
      } else {
        _showCompletionDialog();
      }
    });
  }
}

// Painters
class CurrentStrokePainter extends CustomPainter {
  final List<Offset> currentStroke;
  final List<int>? strokeTimestamps;
  final Color strokeColor;
  final double strokeWidth;
  final StrokeType strokeType;
  final bool isDarkMode;
  final bool isDuotone;
  final Color? accentColor;

  CurrentStrokePainter({
    required this.currentStroke,
    this.strokeTimestamps,
    required this.strokeColor,
    this.strokeWidth = 4.0,
    this.strokeType = StrokeType.classic,
    this.isDarkMode = false,
    this.isDuotone = false,
    this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentStroke.isEmpty) return;
    
    switch (strokeType) {
      case StrokeType.invisible:
        // Don't paint anything for invisible strokes
        break;
      case StrokeType.classic:
        _paintClassicStroke(canvas, size);
        break;
    }
  }
  
  
  void _paintInkStroke(Canvas canvas, Size size) {
    if (currentStroke.length < 2) {
      // For single point, draw a small circle
      final paint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(currentStroke.first, strokeWidth * 0.5, paint);
      return;
    }
    
    // Calculate velocities and angles for ink effect
    final List<double> velocities = [];
    final List<double> angles = [];
    final List<double> pressures = [];
    final List<double> widths = [];
    
    // Calculate properties for each point
    for (int i = 0; i < currentStroke.length; i++) {
      if (i == 0) {
        // First point - use direction to second point
        final delta = currentStroke[1] - currentStroke[0];
        angles.add(math.atan2(delta.dy, delta.dx));
        velocities.add(0.2);
        pressures.add(0.8);
      } else {
        final delta = currentStroke[i] - currentStroke[i - 1];
        final distance = delta.distance;
        final angle = math.atan2(delta.dy, delta.dx);
        
        // Simulate velocity (normalized to 0-1)
        final velocity = math.min(distance / 15.0, 1.0);
        velocities.add(velocity);
        angles.add(angle);
        
        // Simulate pressure based on velocity (slower = more pressure)
        pressures.add(1.0 - velocity * 0.5);
      }
      
      // Calculate width for each point
      final speedFactor = 1.0 - (velocities[i] * 0.6);
      widths.add(strokeWidth * pressures[i] * speedFactor * 1.2);
    }
    
    // Build a continuous path for the main stroke
    final mainPath = Path();
    final paint = Paint()
      ..color = strokeColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3);
    
    // Create the stroke outline using all points
    final leftPoints = <Offset>[];
    final rightPoints = <Offset>[];
    
    for (int i = 0; i < currentStroke.length; i++) {
      final point = currentStroke[i];
      final width = widths[i];
      double angle;
      
      // Calculate perpendicular angle
      if (i == 0) {
        angle = angles[0];
      } else if (i == currentStroke.length - 1) {
        angle = angles[i - 1];
      } else {
        // Average angle for smoother transitions
        angle = (angles[i - 1] + angles[i]) / 2;
      }
      
      final perpAngle = angle + math.pi / 2;
      final halfWidth = width / 2;
      
      final dx = math.cos(perpAngle) * halfWidth;
      final dy = math.sin(perpAngle) * halfWidth;
      
      leftPoints.add(Offset(point.dx - dx, point.dy - dy));
      rightPoints.add(Offset(point.dx + dx, point.dy + dy));
    }
    
    // Build the path
    if (leftPoints.isNotEmpty) {
      mainPath.moveTo(leftPoints.first.dx, leftPoints.first.dy);
      
      // Draw left side
      for (int i = 1; i < leftPoints.length; i++) {
        mainPath.lineTo(leftPoints[i].dx, leftPoints[i].dy);
      }
      
      // Draw end cap (rounded)
      if (rightPoints.isNotEmpty) {
        final endCenter = currentStroke.last;
        final endRadius = widths.last / 2;
        mainPath.arcToPoint(
          rightPoints.last,
          radius: Radius.circular(endRadius),
          clockwise: true,
        );
      }
      
      // Draw right side (in reverse)
      for (int i = rightPoints.length - 1; i >= 0; i--) {
        mainPath.lineTo(rightPoints[i].dx, rightPoints[i].dy);
      }
      
      // Draw start cap (rounded)
      final startCenter = currentStroke.first;
      final startRadius = widths.first / 2;
      mainPath.arcToPoint(
        leftPoints.first,
        radius: Radius.circular(startRadius),
        clockwise: true,
      );
      
      mainPath.close();
    }
    
    // Draw the main stroke
    canvas.drawPath(mainPath, paint);
    
    // Add subtle bristle texture
    final random = math.Random(42);
    for (int i = 0; i < currentStroke.length - 1; i++) {
      final width = widths[i];
      final angle = angles[i];
      final perpAngle = angle + math.pi / 2;
      
      // Fewer bristles for cleaner look
      final bristleCount = (width * 0.15).round().clamp(2, 8);
      
      for (int b = 0; b < bristleCount; b++) {
        final progress = b / (bristleCount - 1) - 0.5; // -0.5 to 0.5
        final offset = progress * width * 0.8;
        
        // Slight random variation
        final variation = (random.nextDouble() - 0.5) * width * 0.1;
        
        final bristleStart = currentStroke[i] + Offset(
          math.cos(perpAngle) * (offset + variation),
          math.sin(perpAngle) * (offset + variation),
        );
        
        final bristleEnd = (i < currentStroke.length - 1 ? currentStroke[i + 1] : currentStroke[i]) + Offset(
          math.cos(perpAngle) * (offset + variation * 0.5),
          math.sin(perpAngle) * (offset + variation * 0.5),
        );
        
        final bristlePaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.15)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(bristleStart, bristleEnd, bristlePaint);
      }
    }
    
    // Add ink pooling at start and end
    final poolPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawCircle(currentStroke.first, widths.first * 0.6, poolPaint);
    canvas.drawCircle(currentStroke.last, widths.last * 0.5, poolPaint);
  }
  
  void _paintClassicStroke(Canvas canvas, Size size) {
    if (currentStroke.isEmpty) return;
    
    // Get current time for age calculations
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Draw as circles with size variation and time-based color
    final dotSpacing = strokeWidth * 0.2; // Small spacing for smooth but visible dots
    double accumulatedDistance = 0.0;
    
    // Store dots with their creation time
    final List<(Offset, double, int)> dotsToRender = []; // position, speed, timestamp
    
    for (int i = 0; i < currentStroke.length; i++) {
      if (i == 0) {
        // Calculate initial speed from first few points if available
        double initialSpeed = 0.0;
        if (currentStroke.length > 1) {
          initialSpeed = (currentStroke[1] - currentStroke[0]).distance;
          if (currentStroke.length > 2) {
            // Average with second segment for better estimate
            initialSpeed = (initialSpeed + (currentStroke[2] - currentStroke[1]).distance) / 2.0;
          }
        }
        // Use actual timestamp if available, otherwise estimate
        final timestamp = (strokeTimestamps != null && i < strokeTimestamps!.length) 
          ? strokeTimestamps![i] 
          : currentTime - ((currentStroke.length - i) * 16);
        dotsToRender.add((currentStroke[i], initialSpeed, timestamp));
      } else {
        final distance = (currentStroke[i] - currentStroke[i-1]).distance;
        accumulatedDistance += distance;
        
        // Draw dots at regular intervals
        while (accumulatedDistance >= dotSpacing) {
          // Interpolate position
          final t = 1.0 - (accumulatedDistance - dotSpacing) / distance;
          final interpolatedPos = Offset.lerp(currentStroke[i-1], currentStroke[i], t)!;
          
          // Calculate speed (distance between consecutive points)
          final speed = distance;
          
          // Interpolate timestamp
          final timestamp = (strokeTimestamps != null && i < strokeTimestamps!.length && i > 0) 
            ? (strokeTimestamps![i-1] + (strokeTimestamps![i] - strokeTimestamps![i-1]) * t).round()
            : currentTime - ((currentStroke.length - i + 1 - t) * 16).round();
          
          dotsToRender.add((interpolatedPos, speed, timestamp));
          accumulatedDistance -= dotSpacing;
        }
      }
    }
    
    // Always add the last dot
    if (currentStroke.length > 1) {
      final lastSpeed = (currentStroke.last - currentStroke[currentStroke.length - 2]).distance;
      final timestamp = (strokeTimestamps != null && currentStroke.length <= strokeTimestamps!.length) 
        ? strokeTimestamps![currentStroke.length - 1]
        : currentTime;
      dotsToRender.add((currentStroke.last, lastSpeed, timestamp));
    }
    
    // Now render all dots with time-based coloring
    for (final (position, speed, timestamp) in dotsToRender) {
      final age = currentTime - timestamp; // How old is this dot in milliseconds
      _drawClassicDot(canvas, position, speed, age.toDouble());
    }
    
    return;
  }
  
  void _drawClassicDot(Canvas canvas, Offset position, double speed, double ageMs) {
    // Subtle size variation based on speed
    final maxDotSize = strokeWidth * 0.7;  // Slightly larger when slow
    final minDotSize = strokeWidth * 0.4;  // Slightly smaller when fast
    
    // Less sensitive speed normalization
    final normalizedSpeed = math.min(speed / 10.0, 1.0);  // Much less sensitive
    
    // Use linear interpolation for gentle changes
    final sizeFactor = 1.0 - normalizedSpeed;
    final dotRadius = minDotSize + (maxDotSize - minDotSize) * sizeFactor;
    
    // Time-based color: newest dots are very light (almost white), then fade to stroke color
    final Color dotColor;
    
    if (ageMs < 20) {
      // Very new (< 20ms): very light version of stroke color
      dotColor = Color.lerp(
        Colors.white,
        strokeColor,
        0.2,  // 80% white, 20% stroke color
      )!;
    } else if (ageMs < 80) {
      // Recent (20-80ms): fade to lighter stroke color
      final t = (ageMs - 20) / 60;
      dotColor = Color.lerp(
        Color.lerp(Colors.white, strokeColor, 0.2)!,  // Very light
        Color.lerp(Colors.white, strokeColor, 0.5)!,  // Light
        t,
      )!;
    } else if (ageMs < 200) {
      // Medium age (80-200ms): fade to full stroke color
      final t = (ageMs - 80) / 120;
      dotColor = Color.lerp(
        Color.lerp(Colors.white, strokeColor, 0.5)!,  // Light
        strokeColor,  // Full stroke color
        t,
      )!;
    } else {
      // Old (>200ms): stay at stroke color
      dotColor = strokeColor;
    }
    
    // Main dot
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    
    canvas.drawCircle(position, dotRadius, paint);
  }
  
  void _paintDotsStroke(Canvas canvas, Size size) {
    if (currentStroke.isEmpty) return;
    
    // First, smooth the stroke points
    final smoothedPoints = <Offset>[];
    final smoothedSpeeds = <double>[];
    
    // Apply smoothing to reduce choppiness
    const smoothingFactor = 0.15; // How much to smooth (0 = no smoothing, 1 = maximum smoothing)
    
    for (int i = 0; i < currentStroke.length; i++) {
      if (i == 0 || i == currentStroke.length - 1) {
        // Keep start and end points exact
        smoothedPoints.add(currentStroke[i]);
        if (i == 0) {
          smoothedSpeeds.add(0.0);
        } else {
          final distance = (currentStroke[i] - currentStroke[i-1]).distance;
          smoothedSpeeds.add(distance);
        }
      } else {
        // Smooth intermediate points
        final prevPoint = smoothedPoints.isEmpty ? currentStroke[i-1] : smoothedPoints.last;
        final targetPoint = currentStroke[i];
        
        // Weighted average for position
        final smoothedPoint = Offset(
          prevPoint.dx + (targetPoint.dx - prevPoint.dx) * (1 - smoothingFactor),
          prevPoint.dy + (targetPoint.dy - prevPoint.dy) * (1 - smoothingFactor),
        );
        
        smoothedPoints.add(smoothedPoint);
        
        // Calculate and smooth speeds
        final distance = (smoothedPoint - prevPoint).distance;
        final prevSpeed = smoothedSpeeds.isEmpty ? distance : smoothedSpeeds.last;
        final smoothedSpeed = prevSpeed + (distance - prevSpeed) * (1 - smoothingFactor);
        smoothedSpeeds.add(smoothedSpeed);
      }
    }
    
    // Draw dots along the smoothed path
    final dotSpacing = strokeWidth * 0.15; // Much smaller spacing for more dots
    double accumulatedDistance = 0.0;
    
    for (int i = 0; i < smoothedPoints.length; i++) {
      if (i == 0) {
        // Always draw the first dot
        _drawDot(canvas, smoothedPoints[i], smoothedSpeeds[i], 0.0);
      } else {
        final distance = (smoothedPoints[i] - smoothedPoints[i-1]).distance;
        accumulatedDistance += distance;
        
        // Draw dots at regular intervals
        while (accumulatedDistance >= dotSpacing) {
          // Interpolate position and speed
          final t = 1.0 - (accumulatedDistance - dotSpacing) / distance;
          final interpolatedPos = Offset.lerp(smoothedPoints[i-1], smoothedPoints[i], t)!;
          final interpolatedSpeed = smoothedSpeeds[i-1] + (smoothedSpeeds[i] - smoothedSpeeds[i-1]) * t;
          
          // Calculate progress along stroke for color fade
          final progress = i / (smoothedPoints.length - 1.0);
          
          _drawDot(canvas, interpolatedPos, interpolatedSpeed, progress);
          accumulatedDistance -= dotSpacing;
        }
      }
    }
    
    // Always draw the last dot
    if (smoothedPoints.isNotEmpty) {
      _drawDot(canvas, smoothedPoints.last, smoothedSpeeds.last, 1.0);
    }
  }
  
  void _drawDot(Canvas canvas, Offset position, double speed, double progress) {
    // Calculate dot size based on speed (slower = MUCH bigger)
    final maxDotSize = strokeWidth * 5.0;  // EXTREMELY large max size (75 pixels with default width)
    final minDotSize = strokeWidth * 0.05;  // TINY min size (0.75 pixels)
    
    // Normalize speed (typical range 0-10 pixels per frame)
    // Make it MUCH more sensitive to speed changes
    final normalizedSpeed = math.min(speed / 2.0, 1.0);  // Very sensitive to speed
    
    // Invert and apply cubic curve for EXTREME size changes
    final sizeFactor = math.pow(1.0 - normalizedSpeed, 3.0).toDouble();  // Cubic for extreme effect
    final dotRadius = minDotSize + (maxDotSize - minDotSize) * sizeFactor;
    
    // Time-based color fade from bright white to deep blue
    final timeProgress = 1.0 - progress;  // Invert so 1.0 is newest
    
    // Use pure colors for maximum contrast
    final dotColor = timeProgress > 0.5 
      ? Color.lerp(
          const Color(0xFF0000FF),  // Deep blue for old dots
          const Color(0xFF4080FF),  // Medium blue for middle
          (timeProgress - 0.5) * 2.0,
        )!
      : Color.lerp(
          const Color(0xFF4080FF),  // Medium blue for middle
          const Color(0xFFFFFFFF),  // Pure white for newest dots
          timeProgress * 2.0,
        )!;
    
    // Draw the dot with a soft edge
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotRadius * 0.2);  // More blur for larger dots
    
    canvas.drawCircle(position, dotRadius, paint);
    
    // Add a bright white highlight for the newest dots
    if (timeProgress > 0.7) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity((timeProgress - 0.7) * 3.33)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(position, dotRadius * 0.5, highlightPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint for animated stroke types
    if (strokeType == StrokeType.classic) return true;
    
    if (oldDelegate is CurrentStrokePainter) {
      return currentStroke.length != oldDelegate.currentStroke.length ||
             strokeColor != oldDelegate.strokeColor ||
             strokeWidth != oldDelegate.strokeWidth ||
             strokeType != oldDelegate.strokeType;
    }
    return true;
  }
}

class CompletedStrokesPainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final List<int> completedIndices;
  final Size canvasSize;
  final bool showSuccess;
  final bool isCorrect;
  final BuildContext context;
  final int? bouncingStrokeIndex;
  final double bounceProgress;
  final double strokeDeviation;

  CompletedStrokesPainter({
    required this.characterStroke,
    required this.completedIndices,
    required this.canvasSize,
    required this.context,
    this.showSuccess = false,
    this.isCorrect = true,
    this.bouncingStrokeIndex,
    this.bounceProgress = 0.0,
    this.strokeDeviation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Determine fill color based on success state
    Color fillColor;
    final duotoneTheme = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDuotone = duotoneTheme?.isDuotoneTheme == true;
    
    if (showSuccess && !isDuotone) {
      // Show appropriate colors for correct/incorrect only in non-duotone mode
      fillColor = isCorrect ? Colors.blue : Colors.red;
    } else {
      // Normal stroke color (used for both normal and success states in duotone)
      if (isDuotone) {
        fillColor = duotoneTheme!.duotoneColor2!.withValues(alpha: 0.95);
      } else {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        fillColor = isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black.withValues(alpha: 0.95);
      }
    }
    
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    // Add a subtle outline paint to separate overlapping strokes
    final outlinePaint = Paint()
      ..color = fillColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw each stroke individually with the same fill color
    for (final index in completedIndices) {
      if (index < characterStroke.strokes.length) {
        final path = SvgPathConverter.parsePath(
          characterStroke.strokes[index],
          size,
        );
        
        // Apply bounce animation if this is the bouncing stroke
        if (index == bouncingStrokeIndex && bounceProgress > 0) {
          canvas.save();
          
          // Get stroke bounds to find center
          final bounds = path.getBounds();
          final center = bounds.center;
          
          // Apply transformations
          canvas.translate(center.dx, center.dy);
          
          // Scale effect - more subtle grow and shrink
          final scale = 1.0 + (math.sin(bounceProgress * math.pi) * 0.05 * (1 + strokeDeviation));
          canvas.scale(scale, scale);
          
          // Remove rotation and shake effects for cleaner animation
          
          // Translate back
          canvas.translate(-center.dx, -center.dy);
        }
        
        // Fill with appropriate color
        canvas.drawPath(path, fillPaint);
        
        // Draw subtle outline to separate overlapping strokes
        canvas.drawPath(path, outlinePaint);
        
        if (index == bouncingStrokeIndex && bounceProgress > 0) {
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HintPainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;
  final double strokeWidth;
  final bool showDirectionArrows;

  HintPainter({
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
    this.strokeWidth = 8.0,
    this.showDirectionArrows = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeIndex >= characterStroke.strokes.length) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = SvgPathConverter.parsePath(
      characterStroke.strokes[strokeIndex],
      size,
    );
    canvas.drawPath(path, paint);
    
    // Draw direction indicators
    if (strokeIndex < characterStroke.medians.length &&
        characterStroke.medians[strokeIndex].isNotEmpty) {
      final medians = characterStroke.medians[strokeIndex];
      final start = medians.first;
      final end = medians.last;
      
      // Account for padding
      final padding = size.width * 0.08; // Match character_stroke_service padding
      final drawSize = size.width - (padding * 2);
      final scale = drawSize / 1024 * 1.05; // Match character_stroke_service scaling
      
      final startPoint = Offset(
        start[0] * scale + padding,
        (1024 - start[1]) * scale + padding,  // Flip Y coordinate
      );
      
      final endPoint = Offset(
        end[0] * scale + padding,
        (1024 - end[1]) * scale + padding,  // Flip Y coordinate
      );
      
      // Draw starting point (green circle)
      final startPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(startPoint, 12, startPaint);
      
      // Draw "START" text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'START',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        startPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
      
      if (showDirectionArrows && medians.length > 2) {
        // Draw direction arrows along the path
        for (int i = 1; i < medians.length - 1; i += 2) {
          final point = medians[i];
          final nextPoint = i + 1 < medians.length ? medians[i + 1] : medians[i];
          
          final arrowPos = Offset(
            point[0] * scale + padding,
            (1024 - point[1]) * scale + padding,
          );
          
          final nextPos = Offset(
            nextPoint[0] * scale + padding,
            (1024 - nextPoint[1]) * scale + padding,
          );
          
          // Calculate arrow direction
          final direction = nextPos - arrowPos;
          if (direction.distance > 0) {
            final angle = direction.direction;
            
            // Draw arrow
            canvas.save();
            canvas.translate(arrowPos.dx, arrowPos.dy);
            canvas.rotate(angle);
            
            final arrowPaint = Paint()
              ..color = color
              ..style = PaintingStyle.fill;
            
            final arrowPath = Path()
              ..moveTo(0, -5)
              ..lineTo(10, 0)
              ..lineTo(0, 5)
              ..close();
            
            canvas.drawPath(arrowPath, arrowPaint);
            canvas.restore();
          }
        }
      }
      
      // Draw ending point (red circle) if different from start
      if ((endPoint - startPoint).distance > 20) {
        final endPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(endPoint, 10, endPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  final Color color;
  final bool isDuotone;

  GridPainter({required this.color, this.isDuotone = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDuotone ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.3)
      ..strokeWidth = isDuotone ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;

    final centerPaint = Paint()
      ..color = isDuotone ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.5)
      ..strokeWidth = isDuotone ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    // Center lines
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    // Diagonals
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CharacterGuidePainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final Size canvasSize;
  final Color color;

  CharacterGuidePainter({
    required this.characterStroke,
    required this.canvasSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a single combined path to avoid opacity overlap
    final combinedPath = Path();
    
    for (final strokePath in characterStroke.strokes) {
      final path = SvgPathConverter.parsePath(strokePath, size);
      combinedPath.addPath(path, Offset.zero);
    }
    
    // Use non-zero fill rule to handle overlapping areas properly
    combinedPath.fillType = PathFillType.nonZero;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Draw the entire character as one shape
    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animation widget for set creation
class _AnimatedSetCreation extends StatefulWidget {
  final VoidCallback onComplete;
  
  const _AnimatedSetCreation({required this.onComplete});
  
  @override
  State<_AnimatedSetCreation> createState() => _AnimatedSetCreationState();
}

class _AnimatedSetCreationState extends State<_AnimatedSetCreation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
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
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInBack),
    ));
    
    _controller.forward().then((_) {
      widget.onComplete();
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
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) => Container(
              color: Colors.black.withValues(alpha: _opacityAnimation.value * 0.5),
            ),
          ),
          // Animated set card
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_box,
                            color: Colors.white,
                            size: 60,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Custom Set Created',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stroke order painter for learning stage 0
class StrokeOrderPainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final Size canvasSize;
  final int currentStrokeIndex;
  final Color color;

  StrokeOrderPainter({
    required this.characterStroke,
    required this.canvasSize,
    required this.currentStrokeIndex,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentStrokeIndex >= characterStroke.strokes.length) return;
    
    // Draw all strokes with numbers
    for (int i = 0; i <= currentStrokeIndex; i++) {
      if (i >= characterStroke.strokes.length) break;
      
      final strokePath = characterStroke.strokes[i];
      final path = SvgPathConverter.parsePath(strokePath, size);
      
      // Draw stroke outline
      final strokePaint = Paint()
        ..color = i == currentStrokeIndex ? color : color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == currentStrokeIndex ? 3.0 : 2.0;
      
      canvas.drawPath(path, strokePaint);
      
      // Draw stroke number at median point
      if (i < characterStroke.medians.length && characterStroke.medians[i].isNotEmpty) {
        final medianPoint = characterStroke.medians[i][0];
        final padding = size.width * 0.08; // Match character_stroke_service padding
        final drawSize = size.width - (padding * 2);
        final scale = drawSize / 1024 * 1.05; // Match character_stroke_service scaling
        
        final numberPosition = Offset(
          medianPoint[0] * scale + padding,
          (1024 - medianPoint[1]) * scale + padding,
        );
        
        // Draw number background
        final bgPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(numberPosition, 12, bgPaint);
        
        // Draw number border
        final borderPaint = Paint()
          ..color = i == currentStrokeIndex ? color : color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawCircle(numberPosition, 12, borderPaint);
        
        // Draw number text
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
              color: i == currentStrokeIndex ? color : color.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          numberPosition - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
    
    // Draw directional arrow for current stroke
    if (currentStrokeIndex < characterStroke.medians.length) {
      final medians = characterStroke.medians[currentStrokeIndex];
      if (medians.length >= 2) {
        final padding = size.width * 0.08; // Match character_stroke_service padding
        final drawSize = size.width - (padding * 2);
        final scale = drawSize / 1024 * 1.05; // Match character_stroke_service scaling
        
        // Draw arrow at 25% of the stroke
        final arrowIndex = (medians.length * 0.25).round().clamp(1, medians.length - 1);
        final currentPoint = medians[arrowIndex];
        final prevPoint = medians[arrowIndex - 1];
        
        final arrowPos = Offset(
          currentPoint[0] * scale + padding,
          (1024 - currentPoint[1]) * scale + padding,
        );
        
        final prevPos = Offset(
          prevPoint[0] * scale + padding,
          (1024 - prevPoint[1]) * scale + padding,
        );
        
        final direction = arrowPos - prevPos;
        if (direction.distance > 0) {
          final angle = direction.direction;
          
          canvas.save();
          canvas.translate(arrowPos.dx, arrowPos.dy);
          canvas.rotate(angle);
          
          final arrowPaint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
          
          final arrowPath = Path()
            ..moveTo(0, -6)
            ..lineTo(12, 0)
            ..lineTo(0, 6)
            ..close();
          
          canvas.drawPath(arrowPath, arrowPaint);
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}