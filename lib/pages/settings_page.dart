import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selection_dialog.dart';
import 'attributions_page.dart';
import '../pages/writing_practice_page.dart' show WritingMode;

enum StrokeType {
  invisible,
  classic,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences _prefs;
  bool _showGrid = true;
  bool _showGuide = true;
  bool _isLoading = true;
  String _userName = '';
  String _themeMode = 'system';
  String _accentColor = 'blue';
  String _duotoneBackground = 'white';
  String _duotoneColor = 'green';
  double _strokeWidth = 8.0;
  String _strokeColor = 'primary';
  String _hintColor = 'primary';
  bool _showStrokeAnimation = true;
  bool _showRadicalAnalysis = false;
  StrokeType _strokeType = StrokeType.classic;
  int _dailyLearnGoal = 10;
  double _strokeLeniency = 0.55; // Default leniency (0.3-0.8 range)
  bool _hapticFeedbackEnabled = true;
  WritingMode _writingMode = WritingMode.auto;
  bool _autoPronounceChinese = true;
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload settings when page regains focus
    if (!_isLoading) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load all settings first
    _showGrid = _prefs.getBool('show_grid') ?? true;
    _showGuide = _prefs.getBool('show_guide') ?? true;
    _userName = _prefs.getString('user_name') ?? '';
    _themeMode = _prefs.getString('theme_mode') ?? 'duotone';
    _accentColor = _prefs.getString('accent_color') ?? 'blue';
    
    // Load duotone colors - prioritize direct values over legacy presets
    _duotoneBackground = _prefs.getString('duotone_background') ?? 'black';
    _duotoneColor = _prefs.getString('duotone_color') ?? 'white';
    
    // Only check legacy preset if no direct values are saved
    if (!_prefs.containsKey('duotone_background') || !_prefs.containsKey('duotone_color')) {
      final duotonePreset = _prefs.getString('duotone_preset') ?? '';
      if (duotonePreset.contains('_')) {
        final parts = duotonePreset.split('_');
        _duotoneColor = parts[0];
        _duotoneBackground = parts[1];
      }
    }

    // Don't validate on initialization - trust saved preferences
    // Only validate when user actively changes colors

    _strokeWidth = _prefs.getDouble('stroke_width') ?? 8.0; // Default 8.0
    // Clamp to valid range (3.0 - 10.0)
    _strokeWidth = _strokeWidth.clamp(3.0, 10.0);
    _strokeColor = _prefs.getString('stroke_color') ?? 'primary';
    _hintColor = _prefs.getString('hint_color') ?? _prefs.getString('stroke_color') ?? 'primary';
    _showStrokeAnimation = _prefs.getBool('show_stroke_animation') ?? true;
    _showRadicalAnalysis = _prefs.getBool('show_radical_analysis') ?? true;
    final strokeTypeString = _prefs.getString('stroke_type') ?? 'classic';
    _strokeType = StrokeType.values.firstWhere(
      (type) => type.name == strokeTypeString,
      orElse: () => StrokeType.classic,
    );
    _dailyLearnGoal = _prefs.getInt('daily_learn_goal') ?? 10;
    _dailyLearnGoal = _dailyLearnGoal.clamp(5, 50); // Clamp to valid range
    _strokeLeniency = _prefs.getDouble('stroke_leniency') ?? 0.55;
    _strokeLeniency = _strokeLeniency.clamp(0.3, 0.8); // Clamp to valid range
    _hapticFeedbackEnabled = _prefs.getBool('haptic_feedback_enabled') ?? true;
    final writingModeString = _prefs.getString('writing_mode') ?? 'auto';
    _writingMode = WritingMode.values.firstWhere(
      (mode) => mode.name == writingModeString,
      orElse: () => WritingMode.auto,
    );
    _autoPronounceChinese = _prefs.getBool('auto_pronounce_chinese') ?? true;
    
    // Initialize haptic service
    await HapticService().initialize();
    
    // Update UI after all settings are loaded
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  Future<void> _saveStringSetting(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  Future<void> _saveDoubleSetting(String key, double value) async {
    await _prefs.setDouble(key, value);
  }
  
  Future<void> _saveIntSetting(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  String _getWritingModeDescription(WritingMode mode) {
    final localizations = AppLocalizations.of(context)!;
    switch (mode) {
      case WritingMode.auto:
        return localizations.writingModeAutoDesc;
      case WritingMode.handwriting:
        return localizations.writingModeHandwritingDesc;
      case WritingMode.trueHandwriting:
        return localizations.writingModeTrueHandwritingDesc;
    }
  }

  void _updateTheme(String mode) async {
    setState(() {
      _themeMode = mode;
    });
    await _saveStringSetting('theme_mode', mode);
    
    // Update theme immediately
    MainApp.of(context)?.updateTheme(mode);
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
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
  
  Color _getAccentColorFromString(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'teal':
        return Colors.teal;
      case 'lightpink':
        return const Color(0xFFFFC1CC); // Light pink
      case 'hotpink':
        return const Color(0xFFFF69B4); // Hot pink
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.practiceSettings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Appearance Settings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.appearance,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Language Selection
                ListTile(
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(_languageService.getLanguageName(_languageService.locale)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => LanguageSelectionDialog(
                        languageService: _languageService,
                        isWelcome: false,
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.theme),
                  subtitle: Text(_themeMode == 'system' ? AppLocalizations.of(context)!.system :
                               _themeMode == 'light' ? AppLocalizations.of(context)!.light :
                               _themeMode == 'dark' ? AppLocalizations.of(context)!.dark :
                               _themeMode == 'duotone' ? AppLocalizations.of(context)!.duotone : AppLocalizations.of(context)!.system),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.chooseTheme),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.system),
                              value: 'system',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.light),
                              value: 'light',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.dark),
                              value: 'dark',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.duotone),
                              value: 'duotone',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_themeMode != 'duotone')
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.accentColor),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getAccentColorFromString(_accentColor),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getColorName(_accentColor)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.accentColor),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAccentColorOption(AppLocalizations.of(context)!.blue, 'blue'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.red, 'red'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.green, 'green'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.purple, 'purple'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.orange, 'orange'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.teal, 'teal'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.lightPink, 'lightpink'),
                              _buildAccentColorOption(AppLocalizations.of(context)!.hotPink, 'hotpink'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                
                // Duotone Settings (only show when duotone theme is selected)
                if (_themeMode == 'duotone') ...[
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.backgroundColor),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(_duotoneBackground),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getColorName(_duotoneBackground)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isSmallDevice = screenWidth <= 400;

                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.backgroundColor),
                            content: isSmallDevice
                              ? SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _getBackgroundColorOptions(),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _getBackgroundColorOptions(),
                                ),
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.accentColor),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getDuotoneAccentColor(_duotoneColor, _duotoneBackground),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getColorName(_duotoneColor)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isSmallDevice = screenWidth <= 400;

                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.accentColor),
                            content: isSmallDevice
                              ? SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _getAccentColorOptions(),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _getAccentColorOptions(),
                                ),
                          );
                        },
                      );
                    },
                  ),
                  // Swap Colors Button
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.swapColors),
                    subtitle: Text(AppLocalizations.of(context)!.swapColorsDesc),
                    leading: Icon(Icons.swap_vert, color: Theme.of(context).colorScheme.primary),
                    trailing: FilledButton.icon(
                      onPressed: () async {
                        // Store current colors
                        final currentBg = _duotoneBackground;
                        final currentAccent = _duotoneColor;
                        
                        // Simply swap the colors
                        String newBackground = currentAccent;
                        String newAccent = currentBg;
                        
                        setState(() {
                          _duotoneBackground = newBackground;
                          _duotoneColor = newAccent;
                        });
                        
                        await _saveStringSetting('duotone_background', newBackground);
                        await _saveStringSetting('duotone_color', newAccent);
                        
                        if (mounted) {
                          MainApp.of(context)?.updateTheme('duotone', 
                            duotoneBackground: newBackground, 
                            duotoneColor: newAccent
                          );
                        }
                      },
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(AppLocalizations.of(context)!.swap),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
                
                // Practice Settings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.practiceSettings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.writingMode),
                  subtitle: Text(_getWritingModeDescription(_writingMode)),
                  trailing: DropdownButton<WritingMode>(
                    value: _writingMode,
                    items: [
                      DropdownMenuItem(
                        value: WritingMode.auto,
                        child: Text(AppLocalizations.of(context)!.auto),
                      ),
                      DropdownMenuItem(
                        value: WritingMode.handwriting,
                        child: Text(AppLocalizations.of(context)!.handwriting),
                      ),
                      DropdownMenuItem(
                        value: WritingMode.trueHandwriting,
                        child: Text(AppLocalizations.of(context)!.trueHandwriting),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        HapticService().selectionClick();
                        setState(() {
                          _writingMode = value;
                        });
                        _prefs.setString('writing_mode', value.name);
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.showGrid),
                  subtitle: Text(AppLocalizations.of(context)!.showGridDesc),
                  value: _showGrid,
                  onChanged: (value) {
                    HapticService().selectionClick();
                    setState(() {
                      _showGrid = value;
                    });
                    _saveBoolSetting('show_grid', value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.showGuideByDefault),
                  subtitle: Text(AppLocalizations.of(context)!.showGuideDesc),
                  value: _showGuide,
                  onChanged: (value) {
                    HapticService().selectionClick();
                    setState(() {
                      _showGuide = value;
                    });
                    _saveBoolSetting('show_guide', value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.showStrokeAnimation),
                  subtitle: Text(AppLocalizations.of(context)!.showStrokeAnimationDesc),
                  value: _showStrokeAnimation,
                  onChanged: (value) {
                    HapticService().selectionClick();
                    setState(() {
                      _showStrokeAnimation = value;
                    });
                    _saveBoolSetting('show_stroke_animation', value);
                  },
                ),
                SwitchListTile(
                  title: Row(
                    children: [
                      Text(AppLocalizations.of(context)!.showRadicalAnalysis),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.beta,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(AppLocalizations.of(context)!.showRadicalAnalysisDesc),
                  value: _showRadicalAnalysis,
                  onChanged: (value) {
                    HapticService().selectionClick();
                    setState(() {
                      _showRadicalAnalysis = value;
                    });
                    _saveBoolSetting('show_radical_analysis', value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.hapticFeedback),
                  subtitle: Text(AppLocalizations.of(context)!.hapticFeedbackDesc),
                  value: _hapticFeedbackEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _hapticFeedbackEnabled = value;
                    });
                    await HapticService().setEnabled(value);
                    if (value) {
                      // Give a light haptic feedback when enabled
                      HapticService().lightImpact();
                    }
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.autoPronounce),
                  subtitle: Text(AppLocalizations.of(context)!.autoPronounceDesc),
                  value: _autoPronounceChinese,
                  onChanged: (value) {
                    HapticService().selectionClick();
                    setState(() {
                      _autoPronounceChinese = value;
                    });
                    _saveBoolSetting('auto_pronounce_chinese', value);
                  },
                ),
                
                // Daily Learn Goal Setting
                ListTile(
                  title: Text(AppLocalizations.of(context)!.cardsPerGroup),
                  subtitle: Text(AppLocalizations.of(context)!.cardsPerGroupDesc(_dailyLearnGoal)),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: _dailyLearnGoal.toDouble(),
                      min: 5.0,
                      max: 50.0,
                      divisions: 9,
                      label: _dailyLearnGoal.toString(),
                      onChanged: (value) async {
                        final newGoal = value.round();
                        setState(() {
                          _dailyLearnGoal = newGoal;
                        });
                        await _saveIntSetting('daily_learn_goal', newGoal);
                      },
                    ),
                  ),
                ),

                // Stroke Leniency Setting
                ListTile(
                  title: Text(AppLocalizations.of(context)!.strokeLeniency),
                  subtitle: Text('${AppLocalizations.of(context)!.strokeLeniencyDesc} (${(_strokeLeniency * 100).toInt()}%)'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: _strokeLeniency,
                      min: 0.3,
                      max: 0.8,
                      divisions: 10,
                      label: '${(_strokeLeniency * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() {
                          _strokeLeniency = value;
                        });
                        _prefs.setDouble('stroke_leniency', value);
                      },
                    ),
                  ),
                ),

                // Stroke Settings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.strokeAppearance,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.strokeWidth),
                  subtitle: Text(AppLocalizations.of(context)!.pixelsValue(_strokeWidth.toStringAsFixed(1))),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: _strokeWidth,
                      min: 3.0,
                      max: 10.0,
                      divisions: 14,
                      label: _strokeWidth.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _strokeWidth = value;
                        });
                        _saveDoubleSetting('stroke_width', value);
                      },
                    ),
                  ),
                ),
                ListTile(
                  enabled: _themeMode != 'duotone' && _themeMode != 'duotone',
                  title: Text(AppLocalizations.of(context)!.strokeColor,
                    style: TextStyle(
                      color: (_themeMode == 'duotone' || _themeMode == 'duotone')
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : null,
                    ),
                  ),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _themeMode == 'duotone'
                            ? _getDuotoneAccentColor(_duotoneColor, _duotoneBackground) // Use actual duotone foreground color
                            : _getColorFromString(_strokeColor),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _themeMode == 'duotone'
                              ? (_duotoneBackground == 'black' ? Colors.white : Colors.black)
                              : Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _themeMode == 'duotone'
                          ? AppLocalizations.of(context)!.usingDuotoneForeground
                          : _strokeColor == 'primary' ? AppLocalizations.of(context)!.themeColor : _strokeColor.substring(0, 1).toUpperCase() + _strokeColor.substring(1),
                        style: TextStyle(
                          color: _themeMode == 'duotone'
                            ? _getDuotoneAccentColor(_duotoneColor, _duotoneBackground)
                            : null,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right,
                    color: (_themeMode == 'duotone' || _themeMode == 'duotone')
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                      : null,
                  ),
                  onTap: (_themeMode == 'duotone' || _themeMode == 'duotone') ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.chooseColor),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildColorOption(AppLocalizations.of(context)!.themeColor, 'primary', isStroke: true),
                            _buildColorOption(AppLocalizations.of(context)!.red, 'red', isStroke: true),
                            _buildColorOption(AppLocalizations.of(context)!.green, 'green', isStroke: true),
                            _buildColorOption(AppLocalizations.of(context)!.blue, 'blue', isStroke: true),
                            _buildColorOption(AppLocalizations.of(context)!.purple, 'purple', isStroke: true),
                            _buildColorOption(AppLocalizations.of(context)!.orange, 'orange', isStroke: true),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  enabled: _themeMode != 'duotone',
                  title: Text(AppLocalizations.of(context)!.strokeType,
                    style: TextStyle(
                      color: _themeMode == 'duotone'
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : null,
                    ),
                  ),
                  subtitle: Text(
                    _themeMode == 'duotone' ? AppLocalizations.of(context)!.classicFixed : _getStrokeTypeLabel(context, _strokeType),
                    style: TextStyle(
                      color: _themeMode == 'duotone'
                        ? _getDuotoneAccentColor(_duotoneColor, _duotoneBackground)
                        : null,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right,
                    color: _themeMode == 'duotone'
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                      : null,
                  ),
                  onTap: _themeMode == 'duotone' ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.chooseStrokeType),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStrokeTypeOption(AppLocalizations.of(context)!.classic, StrokeType.classic, AppLocalizations.of(context)!.smoothCalligraphyBrush),
                            _buildStrokeTypeOption(AppLocalizations.of(context)!.invisible, StrokeType.invisible, AppLocalizations.of(context)!.noVisualFeedback),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_themeMode != 'duotone')
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.hintColor),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getColorFromString(_hintColor),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_hintColor == 'primary' ? AppLocalizations.of(context)!.themeColor : _getColorName(_hintColor)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.chooseHintColor),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildColorOption(AppLocalizations.of(context)!.themeColor, 'primary'),
                              _buildColorOption(AppLocalizations.of(context)!.red, 'red'),
                              _buildColorOption(AppLocalizations.of(context)!.green, 'green'),
                              _buildColorOption(AppLocalizations.of(context)!.blue, 'blue'),
                              _buildColorOption(AppLocalizations.of(context)!.purple, 'purple'),
                              _buildColorOption(AppLocalizations.of(context)!.orange, 'orange'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              
              // About section
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.about,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.attribution),
                title: Text(AppLocalizations.of(context)!.attributions),
                subtitle: Text(AppLocalizations.of(context)!.attributionsDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttributionsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(AppLocalizations.of(context)!.version),
                subtitle: const Text('1.1.1'),
              ),
              const SizedBox(height: 32),
              ],
            ),
    );
  }
  
  Widget _buildColorOption(String label, String colorValue, {bool isStroke = false}) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getColorFromString(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      title: Text(label),
      trailing: (isStroke ? _strokeColor == colorValue : _hintColor == colorValue) ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          if (isStroke) {
            _strokeColor = colorValue;
          } else {
            _hintColor = colorValue;
          }
        });
        _saveStringSetting(isStroke ? 'stroke_color' : 'hint_color', colorValue);
        Navigator.pop(context);
      },
    );
  }
  
  Widget _buildAccentColorOption(String label, String colorValue) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getAccentColorFromString(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      title: Text(label),
      trailing: _accentColor == colorValue ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          _accentColor = colorValue;
        });
        _saveStringSetting('accent_color', colorValue);
        MainApp.of(context)?.updateAccentColor(colorValue);
        Navigator.pop(context);
      },
    );
  }
  
  String _getStrokeTypeLabel(BuildContext context, StrokeType type) {
    switch (type) {
      case StrokeType.invisible:
        return AppLocalizations.of(context)!.invisible;
      case StrokeType.classic:
        return AppLocalizations.of(context)!.classic;
    }
  }
  
  Widget _buildStrokeTypeOption(String label, StrokeType type, String description) {
    return ListTile(
      title: Text(label),
      subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
      trailing: _strokeType == type ? const Icon(Icons.check) : null,
      onTap: () async {
        setState(() {
          _strokeType = type;
          // Set optimal stroke width for each type
          switch (type) {
            case StrokeType.invisible:
              _strokeWidth = 8.0; // Default width (won't be visible anyway)
              break;
            case StrokeType.classic:
              _strokeWidth = 8.0; // Default size for classic effect
              break;
          }
        });
        await _saveStringSetting('stroke_type', type.name);
        await _saveDoubleSetting('stroke_width', _strokeWidth);
        Navigator.pop(context);
      },
    );
  }
  
  Widget _buildBackgroundOption(String label, String value) {
    Color displayColor;
    switch (value) {
      case 'white':
        displayColor = Colors.white;
        break;
      case 'black':
        displayColor = Colors.black;
        break;
      case 'green':
        displayColor = const Color(0xFF2E7D32);
        break;
      case 'bluegreen':
        displayColor = const Color(0xFF037A76);
        break;
      case 'red':
        displayColor = const Color(0xFFD32F2F);
        break;
      case 'blue':
        displayColor = const Color(0xFF1976D2);
        break;
      case 'lightpink':
        displayColor = const Color(0xFFFFC1CC);
        break;
      case 'hotpink':
        displayColor = const Color(0xFFFF69B4);
        break;
      case 'gold':
        displayColor = const Color(0xFFFF8F00);
        break;
      case 'purple':
        displayColor = const Color(0xFF7B1FA2);
        break;
      default:
        displayColor = Colors.white;
    }
    
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      title: Text(label),
      trailing: _duotoneBackground == value 
          ? const Icon(Icons.check) 
          : null,
      onTap: () async {
        // Prevent selecting the same color as accent
        if (value == _duotoneColor) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background and accent colors must be different'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        setState(() {
          _duotoneBackground = value;
        });
        await _saveStringSetting('duotone_background', value);

        // Re-validate the combination and save if needed
        _validateDuotoneColorsSync(saveToPrefs: true);
        
        if (mounted) {
          MainApp.of(context)?.updateTheme('duotone', duotoneBackground: _duotoneBackground, duotoneColor: _duotoneColor);
          Navigator.pop(context);
        }
      },
    );
  }
  
  Widget _buildDuotoneColorOption(String label, String value) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getDuotoneAccentColor(value, _duotoneBackground),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      title: Text(label),
      trailing: _duotoneColor == value 
          ? const Icon(Icons.check) 
          : null,
      onTap: () async {
        // Prevent selecting the same color as background
        if (value == _duotoneBackground) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background and accent colors must be different'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        setState(() {
          _duotoneColor = value;
        });
        await _saveStringSetting('duotone_color', value);

        // Re-validate the combination and save if needed
        _validateDuotoneColorsSync(saveToPrefs: true);
        
        if (mounted) {
          MainApp.of(context)?.updateTheme('duotone', duotoneBackground: _duotoneBackground, duotoneColor: _duotoneColor);
          Navigator.pop(context);
        }
      },
    );
  }
  
  
  void _validateDuotoneColorsSync({bool saveToPrefs = false}) {
    final isBackgroundNeutral = _duotoneBackground == 'white' || _duotoneBackground == 'black';
    final isAccentNeutral = _duotoneColor == 'white' || _duotoneColor == 'black';

    // Check if both are the same (invalid - no contrast)
    if (_duotoneBackground == _duotoneColor) {
      // Default to black background, blue accent
      _duotoneBackground = 'black';
      _duotoneColor = 'blue';
      // Only save if explicitly requested (e.g., user is changing colors)
      if (saveToPrefs) {
        _prefs.setString('duotone_background', _duotoneBackground);
        _prefs.setString('duotone_color', _duotoneColor);
      }
    }
    // Check if neither is neutral (invalid - must have one neutral)
    else if (!isBackgroundNeutral && !isAccentNeutral) {
      // Keep the background, make accent white or black based on background brightness
      if (_duotoneBackground == 'lightpink' || _duotoneBackground == 'gold') {
        _duotoneColor = 'black'; // Use black for light backgrounds
      } else {
        _duotoneColor = 'white'; // Use white for dark backgrounds
      }
      // Only save if explicitly requested
      if (saveToPrefs) {
        _prefs.setString('duotone_color', _duotoneColor);
      }
    }
    // Otherwise the combination is valid (one is neutral, they're different)
  }
  
  List<Widget> _getBackgroundColorOptions() {
    List<Widget> options = [];
    
    // Check if current accent is neutral (white/black)
    final isAccentNeutral = _duotoneColor == 'white' || _duotoneColor == 'black';
    
    if (isAccentNeutral) {
      // If accent is neutral, any color can be background (except the same color)
      if (_duotoneColor != 'white') {
        options.add(_buildBackgroundOption(AppLocalizations.of(context)!.white, 'white'));
      }
      if (_duotoneColor != 'black') {
        options.add(_buildBackgroundOption(AppLocalizations.of(context)!.black, 'black'));
      }
      options.addAll([
        _buildBackgroundOption(AppLocalizations.of(context)!.blue, 'blue'),
        _buildBackgroundOption(AppLocalizations.of(context)!.green, 'green'),
        _buildBackgroundOption(AppLocalizations.of(context)!.blueGreen, 'bluegreen'),
        _buildBackgroundOption(AppLocalizations.of(context)!.red, 'red'),
        _buildBackgroundOption(AppLocalizations.of(context)!.lightPink, 'lightpink'),
        _buildBackgroundOption(AppLocalizations.of(context)!.hotPink, 'hotpink'),
        _buildBackgroundOption(AppLocalizations.of(context)!.gold, 'gold'),
        _buildBackgroundOption(AppLocalizations.of(context)!.purple, 'purple'),
      ]);
    } else {
      // If accent is a color, only neutral backgrounds are valid
      options.addAll([
        _buildBackgroundOption(AppLocalizations.of(context)!.white, 'white'),
        _buildBackgroundOption(AppLocalizations.of(context)!.black, 'black'),
      ]);
    }
    
    return options;
  }
  
  List<Widget> _getAccentColorOptions() {
    List<Widget> options = [];
    
    // Check if current background is neutral (white/black)
    final isBackgroundNeutral = _duotoneBackground == 'white' || _duotoneBackground == 'black';
    
    if (isBackgroundNeutral) {
      // If background is neutral, any color can be accent (except the same color)
      if (_duotoneBackground != 'white') {
        options.add(_buildDuotoneColorOption(AppLocalizations.of(context)!.white, 'white'));
      }
      if (_duotoneBackground != 'black') {
        options.add(_buildDuotoneColorOption(AppLocalizations.of(context)!.black, 'black'));
      }
      options.addAll([
        _buildDuotoneColorOption(AppLocalizations.of(context)!.blue, 'blue'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.green, 'green'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.blueGreen, 'bluegreen'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.red, 'red'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.lightPink, 'lightpink'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.hotPink, 'hotpink'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.gold, 'gold'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.purple, 'purple'),
      ]);
    } else {
      // If background is a color, only neutral accents are valid
      options.addAll([
        _buildDuotoneColorOption(AppLocalizations.of(context)!.white, 'white'),
        _buildDuotoneColorOption(AppLocalizations.of(context)!.black, 'black'),
      ]);
    }
    
    return options;
  }
  
  Color _getBackgroundColor(String background) {
    switch (background) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'green':
        return const Color(0xFF2E7D32);
      case 'bluegreen':
        return const Color(0xFF037A76);
      case 'red':
        return const Color(0xFFD32F2F);
      case 'blue':
        return const Color(0xFF1976D2);
      case 'lightpink':
        return const Color(0xFFFFC1CC); // Light pink
      case 'hotpink':
        return const Color(0xFFFF69B4); // Hot pink
      case 'gold':
        return const Color(0xFFFF8F00);
      case 'purple':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.white;
    }
  }
  
  Color _getDuotoneAccentColor(String color, String background) {
    // Handle white and black accent colors first
    switch (color) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
    }
    
    // For colored accents, adjust based on background
    if (background == 'white') {
      switch (color) {
        case 'green':
          return const Color(0xFF2E7D32);
        case 'bluegreen':
          return const Color(0xFF037A76);
        case 'red':
          return const Color(0xFFD32F2F);
        case 'blue':
          return const Color(0xFF0D47A1);  // Darker blue for better contrast
        case 'lightpink':
          return const Color(0xFFFFB3C1); // Light pink for white background
        case 'hotpink':
          return const Color(0xFFFF1493); // Hot pink for white background
        case 'gold':
          return const Color(0xFFFF8F00);
        case 'purple':
          return const Color(0xFF7B1FA2);
        default:
          return const Color(0xFF2E7D32);
      }
    } else {
      // For dark backgrounds, use lighter shades
      switch (color) {
        case 'green':
          return const Color(0xFF66BB6A);
        case 'bluegreen':
          return const Color(0xFF4DB6AC); // Lighter blue-green for dark backgrounds
        case 'red':
          return const Color(0xFFEF5350);
        case 'blue':
          return const Color(0xFF42A5F5);
        case 'lightpink':
          return const Color(0xFFFFD1DC); // Light pink for dark background
        case 'hotpink':
          return const Color(0xFFFF69B4); // Hot pink for dark background
        case 'gold':
          return const Color(0xFFFFB74D);
        case 'purple':
          return const Color(0xFFAB47BC);
        default:
          return const Color(0xFF66BB6A);
      }
    }
  }

  String _getColorName(String colorValue) {
    switch (colorValue) {
      case 'white':
        return AppLocalizations.of(context)!.white;
      case 'black':
        return AppLocalizations.of(context)!.black;
      case 'blue':
        return AppLocalizations.of(context)!.blue;
      case 'green':
        return AppLocalizations.of(context)!.green;
      case 'bluegreen':
        return AppLocalizations.of(context)!.blueGreen;
      case 'red':
        return AppLocalizations.of(context)!.red;
      case 'lightpink':
        return AppLocalizations.of(context)!.lightPink;
      case 'hotpink':
        return AppLocalizations.of(context)!.hotPink;
      case 'gold':
        return AppLocalizations.of(context)!.gold;
      case 'purple':
        return AppLocalizations.of(context)!.purple;
      default:
        return colorValue.substring(0, 1).toUpperCase() + colorValue.substring(1);
    }
  }

}