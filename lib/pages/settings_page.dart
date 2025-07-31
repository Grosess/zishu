import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/haptic_service.dart';

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
  bool _hapticFeedbackEnabled = true;
  bool _handwritingMode = false;

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
    _themeMode = _prefs.getString('theme_mode') ?? 'system';
    _accentColor = _prefs.getString('accent_color') ?? 'blue';
    
    // Load duotone colors - prioritize direct values over legacy presets
    _duotoneBackground = _prefs.getString('duotone_background') ?? 'white';
    _duotoneColor = _prefs.getString('duotone_color') ?? 'green';
    
    // Only check legacy preset if no direct values are saved
    if (!_prefs.containsKey('duotone_background') || !_prefs.containsKey('duotone_color')) {
      final duotonePreset = _prefs.getString('duotone_preset') ?? '';
      if (duotonePreset.contains('_')) {
        final parts = duotonePreset.split('_');
        _duotoneColor = parts[0];
        _duotoneBackground = parts[1];
      }
    }
    
    // Validate duotone colors synchronously
    _validateDuotoneColorsSync();
    
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
    _hapticFeedbackEnabled = _prefs.getBool('haptic_feedback_enabled') ?? true;
    _handwritingMode = _prefs.getBool('handwriting_mode') ?? false;
    
    // Initialize haptic service
    await HapticService().initialize();
    
    // Update UI after all settings are loaded
    setState(() {
      _isLoading = false;
    });
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName.split(' ').first; // Use first name only
    
    if (hour < 12) {
      return 'Good morning, $name';
    } else if (hour < 17) {
      return 'Good afternoon, $name';
    } else {
      return 'Good evening, $name';
    }
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
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Greeting message
                if (_userName.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Practice Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Appearance Settings
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Theme'),
                  subtitle: Text(_themeMode == 'system' ? 'System' : 
                               _themeMode == 'light' ? 'Light' : 
                               _themeMode == 'dark' ? 'Dark' : 
                               _themeMode == 'duotone' ? 'Duotone' : 'System'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Choose Theme'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: const Text('System'),
                              value: 'system',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Light'),
                              value: 'light',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Dark'),
                              value: 'dark',
                              groupValue: _themeMode,
                              onChanged: (value) {
                                Navigator.pop(context);
                                _updateTheme(value!);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Duotone'),
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
                    title: const Text('Accent Color'),
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
                        Text(_accentColor.substring(0, 1).toUpperCase() + _accentColor.substring(1)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Choose Accent Color'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAccentColorOption('Blue', 'blue'),
                              _buildAccentColorOption('Red', 'red'),
                              _buildAccentColorOption('Green', 'green'),
                              _buildAccentColorOption('Purple', 'purple'),
                              _buildAccentColorOption('Orange', 'orange'),
                              _buildAccentColorOption('Teal', 'teal'),
                              _buildAccentColorOption('Light Pink', 'lightpink'),
                              _buildAccentColorOption('Hot Pink', 'hotpink'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                
                // Duotone Settings (only show when duotone theme is selected)
                if (_themeMode == 'duotone') ...[
                  ListTile(
                    title: const Text('Background Color'),
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
                        Text(_duotoneBackground.substring(0, 1).toUpperCase() + _duotoneBackground.substring(1)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Choose Background Color'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _getBackgroundColorOptions(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Accent Color'),
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
                        Text(_duotoneColor.substring(0, 1).toUpperCase() + _duotoneColor.substring(1)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Choose Accent Color'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _getAccentColorOptions(),
                          ),
                        ),
                      );
                    },
                  ),
                  // Invert Colors Button
                  ListTile(
                    title: const Text('Invert Colors'),
                    subtitle: Text('Swap background and foreground colors'),
                    leading: Icon(Icons.swap_vert, color: Theme.of(context).colorScheme.primary),
                    trailing: FilledButton.icon(
                      onPressed: () async {
                        // Store current colors
                        final currentBg = _duotoneBackground;
                        final currentAccent = _duotoneColor;
                        
                        // Determine new colors based on swap
                        String newBackground;
                        String newAccent;
                        
                        // If background is a neutral (black/white), swap with accent
                        if (currentBg == 'white' || currentBg == 'black') {
                          newBackground = currentAccent; // accent becomes background
                          newAccent = currentBg; // background (white/black) becomes accent
                        } else {
                          // If background is already a color, swap back
                          newBackground = currentAccent;
                          newAccent = currentBg;
                        }
                        
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
                      label: const Text('Invert'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
                
                // Practice Settings
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Practice Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Handwriting Mode'),
                  subtitle: const Text('Draw freely without stroke guidance, then self-assess'),
                  value: _handwritingMode,
                  onChanged: (value) {
                    HapticService().selectionClick();
                    setState(() {
                      _handwritingMode = value;
                    });
                    _saveBoolSetting('handwriting_mode', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Grid'),
                  subtitle: const Text('Display grid lines in the practice area'),
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
                  title: const Text('Show Guide by Default'),
                  subtitle: const Text('Show character outline in learning mode'),
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
                  title: const Text('Show Stroke Animation'),
                  subtitle: const Text('Animate stroke hints in learning mode'),
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
                      const Text('Show Radical Analysis'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Beta',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text('Display character components in learning mode'),
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
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Subtle vibrations for interactions'),
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
                
                // Daily Learn Goal Setting
                ListTile(
                  title: const Text('Cards Per Group'),
                  subtitle: Text('$_dailyLearnGoal characters per group'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: _dailyLearnGoal.toDouble(),
                      min: 5.0,
                      max: 50.0,
                      divisions: 9,
                      label: _dailyLearnGoal.toString(),
                      onChanged: (value) {
                        setState(() {
                          _dailyLearnGoal = value.round();
                        });
                        _saveIntSetting('daily_learn_goal', _dailyLearnGoal);
                      },
                    ),
                  ),
                ),
                
                // Stroke Settings
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Stroke Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Stroke Width'),
                  subtitle: Text('${_strokeWidth.toStringAsFixed(1)} pixels'),
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
                  title: Text('Stroke Color',
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
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_themeMode == 'duotone'
                        ? 'Using Duotone Foreground'
                        : _strokeColor == 'primary' ? 'Theme Color' : _strokeColor.substring(0, 1).toUpperCase() + _strokeColor.substring(1)),
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
                        title: const Text('Choose Stroke Color'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildColorOption('Theme Color', 'primary', isStroke: true),
                            _buildColorOption('Red', 'red', isStroke: true),
                            _buildColorOption('Green', 'green', isStroke: true),
                            _buildColorOption('Blue', 'blue', isStroke: true),
                            _buildColorOption('Purple', 'purple', isStroke: true),
                            _buildColorOption('Orange', 'orange', isStroke: true),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  enabled: _themeMode != 'duotone',
                  title: Text('Stroke Type',
                    style: TextStyle(
                      color: _themeMode == 'duotone'
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : null,
                    ),
                  ),
                  subtitle: Text(_themeMode == 'duotone' ? 'Classic (Fixed)' : _getStrokeTypeLabel(_strokeType)),
                  trailing: Icon(Icons.chevron_right,
                    color: _themeMode == 'duotone'
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                      : null,
                  ),
                  onTap: _themeMode == 'duotone' ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Choose Stroke Type'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStrokeTypeOption('Classic', StrokeType.classic, 'Smooth calligraphy brush'),
                            _buildStrokeTypeOption('Invisible', StrokeType.invisible, 'No visual feedback'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_themeMode != 'duotone')
                  ListTile(
                    title: const Text('Hint Color'),
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
                        Text(_hintColor == 'primary' ? 'Theme Color' : _hintColor.substring(0, 1).toUpperCase() + _hintColor.substring(1)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Choose Hint Color'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildColorOption('Theme Color', 'primary'),
                              _buildColorOption('Red', 'red'),
                              _buildColorOption('Green', 'green'),
                              _buildColorOption('Blue', 'blue'),
                              _buildColorOption('Purple', 'purple'),
                              _buildColorOption('Orange', 'orange'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
  
  String _getStrokeTypeLabel(StrokeType type) {
    switch (type) {
      case StrokeType.invisible:
        return 'Invisible';
      case StrokeType.classic:
        return 'Classic';
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
        
        // Re-validate the combination
        _validateDuotoneColorsSync();
        
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
        
        // Re-validate the combination
        _validateDuotoneColorsSync();
        
        if (mounted) {
          MainApp.of(context)?.updateTheme('duotone', duotoneBackground: _duotoneBackground, duotoneColor: _duotoneColor);
          Navigator.pop(context);
        }
      },
    );
  }
  
  
  void _validateDuotoneColorsSync() {
    final isBackgroundNeutral = _duotoneBackground == 'white' || _duotoneBackground == 'black';
    final isAccentNeutral = _duotoneColor == 'white' || _duotoneColor == 'black';
    
    // Check if both are the same (invalid - no contrast)
    if (_duotoneBackground == _duotoneColor) {
      // Default to white background, green accent
      _duotoneBackground = 'white';
      _duotoneColor = 'green';
      // Save corrected values
      _prefs.setString('duotone_background', _duotoneBackground);
      _prefs.setString('duotone_color', _duotoneColor);
    }
    // Check if both are neutral (invalid)
    else if (isBackgroundNeutral && isAccentNeutral) {
      // Keep white/black background, change accent to green
      _duotoneColor = 'green';
      // Save corrected value
      _prefs.setString('duotone_color', _duotoneColor);
    } 
    // Check if both are colors (invalid - must have one neutral)
    else if (!isBackgroundNeutral && !isAccentNeutral) {
      // Keep the background, make accent white or black based on background brightness
      if (_duotoneBackground == 'lightpink' || _duotoneBackground == 'gold') {
        _duotoneColor = 'black'; // Use black for light backgrounds
      } else {
        _duotoneColor = 'white'; // Use white for dark backgrounds
      }
      // Save corrected value
      _prefs.setString('duotone_color', _duotoneColor);
    }
    // Otherwise the combination is valid
  }
  
  List<Widget> _getBackgroundColorOptions() {
    List<Widget> options = [];
    
    // Check if current accent is neutral (white/black)
    final isAccentNeutral = _duotoneColor == 'white' || _duotoneColor == 'black';
    
    if (isAccentNeutral) {
      // If accent is neutral, any color can be background
      options.addAll([
        _buildBackgroundOption('White', 'white'),
        _buildBackgroundOption('Black', 'black'),
        _buildBackgroundOption('Blue', 'blue'),
        _buildBackgroundOption('Green', 'green'),
        _buildBackgroundOption('Blue Green', 'bluegreen'),
        _buildBackgroundOption('Red', 'red'),
        _buildBackgroundOption('Light Pink', 'lightpink'),
        _buildBackgroundOption('Hot Pink', 'hotpink'),
        _buildBackgroundOption('Gold', 'gold'),
        _buildBackgroundOption('Purple', 'purple'),
      ]);
    } else {
      // If accent is a color, only neutral backgrounds are valid
      options.addAll([
        _buildBackgroundOption('White', 'white'),
        _buildBackgroundOption('Black', 'black'),
      ]);
    }
    
    return options;
  }
  
  List<Widget> _getAccentColorOptions() {
    List<Widget> options = [];
    
    // Check if current background is neutral (white/black)
    final isBackgroundNeutral = _duotoneBackground == 'white' || _duotoneBackground == 'black';
    
    if (isBackgroundNeutral) {
      // If background is neutral, any color can be accent
      final allColors = [
        ['Blue', 'blue'],
        ['Green', 'green'],
        ['Blue Green', 'bluegreen'],
        ['Red', 'red'],
        ['Light Pink', 'lightpink'],
        ['Hot Pink', 'hotpink'],
        ['Gold', 'gold'],
        ['Purple', 'purple'],
      ];
      
      for (final color in allColors) {
        options.add(_buildDuotoneColorOption(color[0], color[1]));
      }
    } else {
      // If background is a color, only neutral accents are valid
      options.addAll([
        _buildDuotoneColorOption('White', 'white'),
        _buildDuotoneColorOption('Black', 'black'),
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
  
}