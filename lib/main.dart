import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/local_storage_service.dart';
import 'services/character_cache_manager.dart';
import 'services/profile_service.dart';
import 'pages/data_backup_page.dart';
import 'pages/sets_page.dart' as sets;
import 'pages/settings_page.dart';
import 'pages/progress_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/practice_history_page.dart';
import 'pages/mark_as_learned_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/image_cache_service.dart';
import 'services/statistics_service.dart';
import 'services/streak_service.dart';
import 'services/learning_service.dart';
import 'services/haptic_service.dart';
import 'widgets/streak_display.dart';
import 'package:url_launcher/url_launcher.dart';

// Theme extension for duotone themes
class DuotoneThemeExtension extends ThemeExtension<DuotoneThemeExtension> {
  final bool isDuotoneTheme;
  final Color gridColor;
  final Color? duotoneColor1;
  final Color? duotoneColor2;

  const DuotoneThemeExtension({
    this.isDuotoneTheme = false,
    required this.gridColor,
    this.duotoneColor1,
    this.duotoneColor2,
  });

  @override
  DuotoneThemeExtension copyWith({
    bool? isDuotoneTheme,
    Color? gridColor,
    Color? duotoneColor1,
    Color? duotoneColor2,
  }) {
    return DuotoneThemeExtension(
      isDuotoneTheme: isDuotoneTheme ?? this.isDuotoneTheme,
      gridColor: gridColor ?? this.gridColor,
      duotoneColor1: duotoneColor1 ?? this.duotoneColor1,
      duotoneColor2: duotoneColor2 ?? this.duotoneColor2,
    );
  }

  @override
  DuotoneThemeExtension lerp(ThemeExtension<DuotoneThemeExtension>? other, double t) {
    if (other is! DuotoneThemeExtension) {
      return this;
    }
    return DuotoneThemeExtension(
      isDuotoneTheme: t < 0.5 ? isDuotoneTheme : other.isDuotoneTheme,
      gridColor: Color.lerp(gridColor, other.gridColor, t) ?? gridColor,
      duotoneColor1: Color.lerp(duotoneColor1, other.duotoneColor1, t),
      duotoneColor2: Color.lerp(duotoneColor2, other.duotoneColor2, t),
    );
  }
}

// Global key to access MainApp state from anywhere
final GlobalKey<_MainAppState> mainAppKey = GlobalKey<_MainAppState>();

// Global key to access MainScreen state from anywhere
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

// Method to force app restart
void restartApp() {
  mainAppKey.currentState?.restartApp();
}

// Method to refresh streak display
void refreshStreakDisplay() {
  mainScreenKey.currentState?.refreshStreakDisplay();
}

// Method to refresh sets progress
void refreshSetsProgress() {
  mainScreenKey.currentState?.refreshSetsProgress();
}

Future<void> _initializeApp() async {
  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configure image cache for optimal performance
  ImageCacheService.configureImageCache();
  
  // Clear cache if needed
  await CharacterCacheManager.checkAndClearCache();
  
  // Initialize local storage
  await LocalStorageService().initialize();
  
  // Preload profile data
  await ProfileService().loadProfile();
  
  // Initialize streak service
  await StreakService().initialize();
  
  // Initialize haptic service
  await HapticService().initialize();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  try {
    // Add timeout to prevent hanging
    await Future.any([
      _initializeApp(),
      Future.delayed(Duration(seconds: 10)).then((_) {
        throw TimeoutException('App initialization timed out');
      }),
    ]);
    
    // Load theme settings before running app
    final prefs = await SharedPreferences.getInstance();
    
    // Check if this is the first time running the app
    final isFirstRun = !prefs.containsKey('theme_mode');
    
    // Determine system theme for initial background color
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final systemIsDark = brightness == Brightness.dark;
    
    // Set default theme to system (not duotone) until unlocked
    final themeMode = prefs.getString('theme_mode') ?? 'system';
    final accentColor = prefs.getString('accent_color') ?? 'blue';
    final duotoneBackground = prefs.getString('duotone_background') ?? (systemIsDark ? 'black' : 'white');
    final duotoneColor = prefs.getString('duotone_color') ?? 'blue';
    
    // Save defaults if first run
    if (isFirstRun) {
      await prefs.setString('theme_mode', 'system');
      await prefs.setString('duotone_background', systemIsDark ? 'black' : 'white');
      await prefs.setString('duotone_color', 'blue');
      await prefs.setString('accent_color', 'blue');
    }
    
    runApp(MainApp(
      key: mainAppKey,
      initialThemeMode: themeMode,
      initialAccentColor: accentColor,
      initialDuotoneBackground: duotoneBackground,
      initialDuotoneColor: duotoneColor,
    ));
  } catch (e) {
    // Show error app
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 60, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  e.toString(),
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MainApp extends StatefulWidget {
  final String? initialThemeMode;
  final String? initialAccentColor;
  final String? initialDuotoneBackground;
  final String? initialDuotoneColor;
  
  const MainApp({
    super.key,
    this.initialThemeMode,
    this.initialAccentColor,
    this.initialDuotoneBackground,
    this.initialDuotoneColor,
  });

  @override
  State<MainApp> createState() => _MainAppState();
  
  static _MainAppState? of(BuildContext context) {
    return mainAppKey.currentState;
  }
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late ThemeMode _themeMode;
  late Color _accentColor;
  late bool _isDuotoneTheme;
  late String _duotoneBackground;
  late String _duotoneColor;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize theme from passed values
    _initializeTheme();
    
    // Still load settings to ensure we have the latest values
    _loadThemeSettings();
    _preloadAssets();
  }
  
  void _initializeTheme() {
    final themeModeString = widget.initialThemeMode ?? 'system';
    final accentColorString = widget.initialAccentColor ?? 'blue';
    _duotoneBackground = widget.initialDuotoneBackground ?? 'white';
    _duotoneColor = widget.initialDuotoneColor ?? 'green';
    
    switch (themeModeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        _isDuotoneTheme = false;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        _isDuotoneTheme = false;
        break;
      case 'duotone':
        _themeMode = ThemeMode.light;
        _isDuotoneTheme = true;
        break;
      default:
        _themeMode = ThemeMode.system;
        _isDuotoneTheme = false;
    }
    
    _accentColor = _isDuotoneTheme 
        ? _getDuotoneColors(_duotoneBackground, _duotoneColor)[1] 
        : _getColorFromString(accentColorString);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background, clear some caches
      ImageCacheService().handleMemoryPressure();
    }
  }
  
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Handle memory pressure
    ImageCacheService().handleMemoryPressure();
    // Clear statistics cache
    StatisticsService().clearCache();
  }
  
  Future<void> _preloadAssets() async {
    // Preload images using cache service
    final imageCacheService = ImageCacheService();
    await imageCacheService.preloadImages(context);
  }
  
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Default to system theme if no theme is set
      if (!prefs.containsKey('theme_mode')) {
        await prefs.setString('theme_mode', 'system');
      }
      
      final themeModeString = prefs.getString('theme_mode') ?? 'system';
      final accentColorString = prefs.getString('accent_color') ?? 'blue';
      
      // Load duotone colors - prioritize direct values
      _duotoneBackground = prefs.getString('duotone_background') ?? 'white';
      _duotoneColor = prefs.getString('duotone_color') ?? 'green';
      
      // Only check legacy preset if no direct values are saved
      if (!prefs.containsKey('duotone_background') || !prefs.containsKey('duotone_color')) {
        final duotonePreset = prefs.getString('duotone_preset') ?? '';
        if (duotonePreset.contains('_')) {
          final parts = duotonePreset.split('_');
          _duotoneColor = parts[0];
          _duotoneBackground = parts[1];
        }
      }
      
      // Validate duotone colors
      _validateDuotoneColors();
      
      setState(() {
        switch (themeModeString) {
          case 'light':
            _themeMode = ThemeMode.light;
            _isDuotoneTheme = false;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            _isDuotoneTheme = false;
            break;
          case 'duotone':
            _themeMode = ThemeMode.light;
            _isDuotoneTheme = true;
            break;
          default:
            _themeMode = ThemeMode.system;
            _isDuotoneTheme = false;
        }
        _accentColor = _isDuotoneTheme ? _getDuotoneColors(_duotoneBackground, _duotoneColor)[1] : _getColorFromString(accentColorString);
      });
    } catch (e) {
      // Theme is already initialized, so no need to do anything
    }
  }
  
  void _validateDuotoneColors() async {
    final isBackgroundNeutral = _duotoneBackground == 'white' || _duotoneBackground == 'black';
    final isAccentNeutral = _duotoneColor == 'white' || _duotoneColor == 'black';
    
    bool needsSave = false;
    
    // Check if both are the same (invalid - no contrast)
    if (_duotoneBackground == _duotoneColor) {
      // Default to white background, green accent
      _duotoneBackground = 'white';
      _duotoneColor = 'green';
      needsSave = true;
    }
    // Check if both are neutral (invalid)
    else if (isBackgroundNeutral && isAccentNeutral) {
      // Keep white/black background, change accent to green
      _duotoneColor = 'green';
      needsSave = true;
    } 
    // Check if both are colors (invalid - must have one neutral)
    else if (!isBackgroundNeutral && !isAccentNeutral) {
      // Keep the background, make accent white or black based on background brightness
      if (_duotoneBackground == 'lightpink' || _duotoneBackground == 'gold') {
        _duotoneColor = 'black'; // Use black for light backgrounds
      } else {
        _duotoneColor = 'white'; // Use white for dark backgrounds
      }
      needsSave = true;
    }
    // Otherwise the combination is valid
    
    // Save corrected values if they were changed
    if (needsSave) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('duotone_background', _duotoneBackground);
      await prefs.setString('duotone_color', _duotoneColor);
    }
  }
  
  Color _getColorFromString(String colorName) {
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
        return const Color(0xFF037A76); // Blue-green color
      case 'lightpink':
        return const Color(0xFFFFC1CC); // Light pink
      case 'hotpink':
        return const Color(0xFFFF1493); // True hot pink (DeepPink)
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.blue;
    }
  }
  
  String _getColorName(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.red) return 'red';
    if (color == Colors.green) return 'green';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.orange) return 'orange';
    if (color == const Color(0xFF037A76)) return 'teal';
    if (color == const Color(0xFFFFC1CC)) return 'lightpink';
    if (color == const Color(0xFFFF1493)) return 'hotpink';
    if (color == Colors.black) return 'black';
    if (color == Colors.white) return 'white';
    return 'blue';
  }
  
  List<Color> _getDuotoneColors(String background, String color) {
    // Returns [background color, foreground color]
    Color backgroundColor;
    Color foregroundColor;
    
    // Determine background color
    switch (background) {
      case 'white':
        // Special case: make white background slightly darker for white + light pink
        backgroundColor = (color == 'lightpink' || color == 'hotpink') ? const Color(0xFFFAFAFA) : Colors.white;
        break;
      case 'black':
        backgroundColor = Colors.black;
        break;
      case 'green':
        backgroundColor = const Color(0xFF2E7D32);
        break;
      case 'bluegreen':
        backgroundColor = const Color(0xFF037A76);
        break;
      case 'red':
        backgroundColor = const Color(0xFFD32F2F);
        break;
      case 'blue':
        backgroundColor = const Color(0xFF1976D2);
        break;
      case 'lightpink':
        backgroundColor = const Color(0xFFFFC1CC); // Light pink
        break;
      case 'hotpink':
        backgroundColor = const Color(0xFFFF1493); // True hot pink (DeepPink)
        break;
      case 'gold':
        backgroundColor = const Color(0xFFFF8F00);
        break;
      case 'purple':
        backgroundColor = const Color(0xFF7B1FA2);
        break;
      default:
        backgroundColor = Colors.white;
    }
    
    // Determine foreground color based on what would be visible
    switch (color) {
      case 'white':
        foregroundColor = Colors.white;
        break;
      case 'black':
        foregroundColor = Colors.black;
        break;
      case 'green':
        // Use lighter green on dark backgrounds
        foregroundColor = (background == 'black' || background == 'green' || background == 'blue' || background == 'purple' || background == 'bluegreen') 
          ? const Color(0xFF66BB6A) 
          : const Color(0xFF2E7D32);
        break;
      case 'bluegreen':
        // Use lighter blue-green on dark backgrounds
        foregroundColor = (background == 'black' || background == 'bluegreen' || background == 'blue' || background == 'green') 
          ? const Color(0xFF4DB6AC) 
          : const Color(0xFF037A76);
        break;
      case 'red':
        foregroundColor = (background == 'black' || background == 'red' || background == 'purple') 
          ? const Color(0xFFEF5350) 
          : const Color(0xFFD32F2F);
        break;
      case 'blue':
        foregroundColor = (background == 'black' || background == 'blue' || background == 'purple') 
          ? const Color(0xFF42A5F5)  // Lighter blue for dark backgrounds
          : const Color(0xFF0D47A1);  // Much darker blue for white background (blue 900)
        break;
      case 'lightpink':
        // Light pink - use different shades for contrast
        foregroundColor = (background == 'black' || background == 'lightpink') 
          ? const Color(0xFFFFD1DC) // Even lighter pink for dark backgrounds
          : const Color(0xFFFFB3C1); // Light pink for white background
        break;
      case 'hotpink':
        // Hot pink - use different shades for contrast
        foregroundColor = (background == 'black' || background == 'hotpink' || background == 'purple') 
          ? const Color(0xFFFF69B4) // Lighter hot pink for dark backgrounds
          : const Color(0xFFFF1493); // True hot pink (DeepPink) for white background
        break;
      case 'gold':
        foregroundColor = (background == 'black' || background == 'gold') 
          ? const Color(0xFFFFB74D) 
          : const Color(0xFFFF8F00);
        break;
      case 'purple':
        foregroundColor = (background == 'black' || background == 'purple' || background == 'blue') 
          ? const Color(0xFFAB47BC) 
          : const Color(0xFF7B1FA2);
        break;
      default:
        foregroundColor = Colors.black;
    }
    
    return [backgroundColor, foregroundColor];
  }
  
  void updateTheme(String mode, {String? duotoneBackground, String? duotoneColor}) {
    // Load saved accent color to restore when leaving special themes
    SharedPreferences.getInstance().then((prefs) {
      final savedAccentColor = prefs.getString('accent_color') ?? 'blue';
      
      setState(() {
        switch (mode) {
          case 'light':
            _themeMode = ThemeMode.light;
            _isDuotoneTheme = false;
            _accentColor = _getColorFromString(savedAccentColor);
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            _isDuotoneTheme = false;
            _accentColor = _getColorFromString(savedAccentColor);
            break;
          case 'duotone':
            _themeMode = ThemeMode.light;
            _isDuotoneTheme = true;
            if (duotoneBackground != null) {
              _duotoneBackground = duotoneBackground;
              prefs.setString('duotone_background', duotoneBackground);
            }
            if (duotoneColor != null) {
              _duotoneColor = duotoneColor;
              prefs.setString('duotone_color', duotoneColor);
            }
            final colors = _getDuotoneColors(_duotoneBackground, _duotoneColor);
            _accentColor = colors[1]; // Use foreground color
            break;
          default:
            _themeMode = ThemeMode.system;
            _isDuotoneTheme = false;
            _accentColor = _getColorFromString(savedAccentColor);
        }
      });
    });
  }
  
  void updateAccentColor(String colorName) {
    // Don't allow accent color changes in duotone theme
    if (!_isDuotoneTheme) {
      setState(() {
        _accentColor = _getColorFromString(colorName);
      });
    }
  }
  
  void restartApp() {
    // Reload theme settings from SharedPreferences
    _loadThemeSettings();
  }

  ThemeData _buildLightTheme() {
    if (_isDuotoneTheme) {
      // Duotone Theme - [0] is background, [1] is foreground
      final colors = _getDuotoneColors(_duotoneBackground, _duotoneColor);
      final backgroundColor = colors[0];
      final foregroundColor = colors[1];
      
      return ThemeData(
        colorScheme: ColorScheme.light(
          primary: foregroundColor,
          secondary: foregroundColor,
          tertiary: foregroundColor,
          surface: backgroundColor,
          onPrimary: backgroundColor,
          onSecondary: backgroundColor,
          onSurface: foregroundColor,
          surfaceContainerHighest: backgroundColor,
          onSurfaceVariant: foregroundColor,
          outline: foregroundColor.withValues(alpha: 0.3),
          shadow: foregroundColor.withValues(alpha: 0.3),
        ),
        scaffoldBackgroundColor: backgroundColor,
        cardColor: backgroundColor,
        canvasColor: backgroundColor,
        dividerColor: foregroundColor.withValues(alpha: 0.2),
        dialogTheme: DialogThemeData(
          backgroundColor: backgroundColor,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: backgroundColor,
          modalBackgroundColor: backgroundColor,
        ),
        iconTheme: IconThemeData(color: foregroundColor),
        primaryIconTheme: IconThemeData(color: foregroundColor),
        listTileTheme: ListTileThemeData(
          iconColor: foregroundColor,
          textColor: foregroundColor,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: backgroundColor,
          selectedItemColor: foregroundColor,
          unselectedItemColor: foregroundColor.withValues(alpha: 0.5),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: backgroundColor,
          indicatorColor: foregroundColor.withValues(alpha: 0.2),
          iconTheme: WidgetStateProperty.all(IconThemeData(color: foregroundColor)),
          labelTextStyle: WidgetStateProperty.all(TextStyle(color: foregroundColor)),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: foregroundColor),
          bodyMedium: TextStyle(color: foregroundColor),
          bodySmall: TextStyle(color: foregroundColor),
          headlineLarge: TextStyle(color: foregroundColor),
          headlineMedium: TextStyle(color: foregroundColor),
          headlineSmall: TextStyle(color: foregroundColor),
          titleLarge: TextStyle(color: foregroundColor),
          titleMedium: TextStyle(color: foregroundColor),
          titleSmall: TextStyle(color: foregroundColor),
          labelLarge: TextStyle(color: foregroundColor),
          labelMedium: TextStyle(color: foregroundColor),
          labelSmall: TextStyle(color: foregroundColor),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: foregroundColor),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: backgroundColor.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
            statusBarBrightness: backgroundColor.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: backgroundColor,
            systemNavigationBarIconBrightness: backgroundColor.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: foregroundColor,
            foregroundColor: backgroundColor,
            elevation: 4,
            shadowColor: foregroundColor.withValues(alpha: 0.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: foregroundColor,
            foregroundColor: backgroundColor,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(foregroundColor),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return foregroundColor.withValues(alpha: 0.5);
            }
            return foregroundColor.withValues(alpha: 0.2);
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(foregroundColor),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(foregroundColor),
        ),
        cardTheme: CardThemeData(
          color: backgroundColor,
          elevation: 4,
          shadowColor: foregroundColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: foregroundColor.withValues(alpha: 0.1)),
          ),
        ),
        useMaterial3: true,
        fontFamilyFallback: const ['Noto Sans CJK SC', 'Noto Sans SC', 'Microsoft YaHei', 'PingFang SC', 'Hiragino Sans GB', 'Source Han Sans SC', 'WenQuanYi Micro Hei'],
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        extensions: [
          DuotoneThemeExtension(
            isDuotoneTheme: true,
            gridColor: foregroundColor.withValues(alpha: 0.15),
            duotoneColor1: backgroundColor,
            duotoneColor2: foregroundColor,
          ),
        ],
      );
    } else {
      // Regular Light Theme
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
        fontFamilyFallback: const ['Noto Sans CJK SC', 'Noto Sans SC', 'Microsoft YaHei', 'PingFang SC', 'Hiragino Sans GB', 'Source Han Sans SC', 'WenQuanYi Micro Hei'],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _accentColor.withValues(alpha: 0.1), width: 1),
          ),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.grey[800],
          titleTextStyle: TextStyle(
            color: Colors.grey[800],
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.grey[50],
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zishu - Hanzi Practice',
      theme: _buildLightTheme(),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        fontFamilyFallback: const ['Noto Sans CJK SC', 'Noto Sans SC', 'Microsoft YaHei', 'PingFang SC', 'Hiragino Sans GB', 'Source Han Sans SC', 'WenQuanYi Micro Hei'],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _accentColor.withValues(alpha: 0.2), width: 1),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      themeMode: _themeMode,
      home: MainScreen(key: mainScreenKey),
      builder: (context, child) {
        // Determine status bar style and keyboard appearance based on theme
        SystemUiOverlayStyle statusBarStyle;
        Brightness keyboardAppearance;
        
        if (_isDuotoneTheme) {
          // For duotone themes, special rules for black/white
          final colors = _getDuotoneColors(_duotoneBackground, _duotoneColor);
          final backgroundColor = colors[0];
          
          // If background is black OR accent is black, use dark keyboard
          // If background is white OR accent is white, use light keyboard
          if (_duotoneBackground == 'black' || _duotoneColor == 'black') {
            keyboardAppearance = Brightness.dark;
            statusBarStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            );
          } else if (_duotoneBackground == 'white' || _duotoneColor == 'white') {
            keyboardAppearance = Brightness.light;
            statusBarStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            );
          } else {
            // Fallback to luminance check for other color combinations
            final isLightBackground = backgroundColor.computeLuminance() > 0.5;
            keyboardAppearance = isLightBackground ? Brightness.light : Brightness.dark;
            statusBarStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isLightBackground ? Brightness.dark : Brightness.light,
              statusBarBrightness: isLightBackground ? Brightness.light : Brightness.dark,
            );
          }
        } else if (_themeMode == ThemeMode.dark || 
                   (_themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark)) {
          // Dark theme or system dark mode
          statusBarStyle = SystemUiOverlayStyle.light;
          keyboardAppearance = Brightness.dark;
        } else {
          // Light theme or system light mode
          final accentColorName = _getColorName(_accentColor);
          if (accentColorName == 'black') {
            // Black accent - use black status bar
            statusBarStyle = SystemUiOverlayStyle.dark;
          } else if (accentColorName == 'white') {
            // White accent - use white status bar
            statusBarStyle = SystemUiOverlayStyle.light;
          } else {
            // Other colors - use default dark status bar for light theme
            statusBarStyle = SystemUiOverlayStyle.dark;
          }
          keyboardAppearance = Brightness.light;
        }
        
        // Apply keyboard appearance to all text fields
        return Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Theme.of(context).colorScheme.primary,
              selectionColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              selectionHandleColor: Theme.of(context).colorScheme.primary,
            ),
            inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
              // This doesn't directly set keyboard appearance but ensures consistent theming
            ),
          ),
          child: Builder(
            builder: (context) {
              // Set the keyboard appearance for all text fields
              return DefaultTextEditingShortcuts(
                child: Actions(
                  actions: <Type, Action<Intent>>{},
                  child: FocusScope(
                    child: AnnotatedRegion<SystemUiOverlayStyle>(
                      value: statusBarStyle.copyWith(
                        systemNavigationBarColor: _isDuotoneTheme 
                          ? _getDuotoneColors(_duotoneBackground, _duotoneColor)[0]
                          : Theme.of(context).scaffoldBackgroundColor,
                        systemNavigationBarIconBrightness: keyboardAppearance == Brightness.dark 
                          ? Brightness.light 
                          : Brightness.dark,
                      ),
                      child: child!,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;  // Start on Sets tab
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProfileService _profileService = ProfileService();
  

  late final List<Widget> _pages;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<sets.SetsPageState> _setsPageKey = GlobalKey<sets.SetsPageState>();
  final GlobalKey<ProgressPageState> _progressPageKey = GlobalKey<ProgressPageState>();
  
  // Key for streak display to force refresh
  Key _streakDisplayKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = [
      HomePage(key: _homePageKey, onNavigateToTab: _onItemTapped),
      sets.SetsPage(key: _setsPageKey),
      ProgressPage(key: _progressPageKey),
    ];
    
    // Listen to profile changes
    _profileService.addListener(_onProfileChanged);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileService.removeListener(_onProfileChanged);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is back in foreground, refresh the current page
        switch (_selectedIndex) {
          case 0:
            if (_homePageKey.currentState != null) {
              _homePageKey.currentState!.onPageVisible();
            }
            break;
          case 1:
            // Refresh sets page progress
            if (_setsPageKey.currentState != null) {
              dynamic state = _setsPageKey.currentState;
              state.onPageGainsFocus();
            }
            break;
          case 2:
            if (_progressPageKey.currentState != null) {
              _progressPageKey.currentState!.loadStatistics();
            }
            break;
        }
        // Also refresh streak display
        refreshStreakDisplay();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Free up memory when app goes to background
        ImageCacheService().handleMemoryPressure();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Clear caches when app is being terminated
        ImageCacheService().clearCache();
        CharacterCacheManager.clearMemoryCache();
        break;
    }
  }
  
  void _onProfileChanged() {
    setState(() {
      // Profile data updated
    });
  }
  
  void refreshStreakDisplay() {
    setState(() {
      _streakDisplayKey = UniqueKey(); // Force streak display to rebuild
    });
  }
  
  void refreshSetsProgress() {
    // Clear caches to ensure fresh data
    StatisticsService().clearCache();
    LearningService().clearCache();
    
    // Force refresh sets page if it exists
    if (_setsPageKey.currentState != null) {
      dynamic state = _setsPageKey.currentState;
      state.forceRefresh();
    }
    
    // Navigate to sets tab
    _onItemTapped(1);
  }
  
  void _onItemTapped(int index) {
    final previousIndex = _selectedIndex;
    setState(() {
      _selectedIndex = index;
    });
    
    // Scroll to top when tab is selected
    switch (index) {
      case 0:
        if (_homePageKey.currentState != null) {
          _homePageKey.currentState!.scrollToTop();
          if (previousIndex != 0) {
            _homePageKey.currentState!.onPageVisible();
          }
        }
        break;
      case 1:
        _setsPageKey.currentState?.scrollToTop();
        // Refresh progress when navigating to sets tab
        if (_setsPageKey.currentState != null && previousIndex != 1) {
          dynamic state = _setsPageKey.currentState;
          state.onPageGainsFocus();
        }
        break;
      case 2:
        _progressPageKey.currentState?.scrollToTop();
        // Refresh progress data when navigating to the progress tab
        _progressPageKey.currentState?.loadStatistics();
        // Also refresh streak display to ensure consistency
        refreshStreakDisplay();
        break;
    }
  }
  
  void navigateToSetsTab({bool showCustom = false}) {
    setState(() {
      _selectedIndex = 1; // Sets tab is at index 1
    });
    
    if (showCustom) {
      // Wait for the navigation to complete, then switch to custom tab
      Future.delayed(const Duration(milliseconds: 300), () {
        // Access the SetsPage and switch to custom tab
        // This would require adding a key to the SetsPage or using a different approach
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom set created! Check the Custom tab.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }
  
  void refreshSetsPage() {
    // Refresh the sets page to show new custom sets
    if (_setsPageKey.currentState != null) {
      // Force a rebuild of sets page
      setState(() {
        // This will trigger the sets page to reload
      });
      // Navigate to custom tab
      Future.delayed(const Duration(milliseconds: 300), () {
        // The sets page will reload its custom sets automatically
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0, // Align title to the left
        centerTitle: false, // Explicitly left-align the title
        leading: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                    ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                    : Theme.of(context).colorScheme.primary,
                boxShadow: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                    ? [] // No shadow for duotone
                    : [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.transparent,
                backgroundImage: _profileService.profileImageBytes != null 
                    ? MemoryImage(_profileService.profileImageBytes!) 
                    : null,
                child: _profileService.profileImageBytes == null
                    ? Text(
                        _profileService.firstName.isNotEmpty ? _profileService.firstName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                              ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        title: Text(
          'Zishu',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
                : Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: StreakDisplay(key: _streakDisplayKey, showOnlyIcon: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8), // Add spacing from the edge
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        _profileService.firstName.isNotEmpty ? _profileService.firstName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 28,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profileService.firstName.isNotEmpty ? _profileService.firstName : 'User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Tap to edit profile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
              ),
              ),
            ),
            Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'DATA & PROGRESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.cloud_upload,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Data Backup'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataBackupPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Practice History'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PracticeHistoryPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Mark as Learned'),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarkAsLearnedPage(),
                        ),
                      );
                      
                      // Refresh when returning if changes were made
                      if (result == true && mounted) {
                        // Refresh home page
                        _homePageKey.currentState?.refreshData();
                        
                        // Refresh progress page
                        _progressPageKey.currentState?.loadStatistics();
                        
                        // Refresh streak display
                        refreshStreakDisplay();
                        
                        // Force UI update
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'SUPPORT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.feedback,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Give Feedback'),
                onTap: () async {
                  Navigator.pop(context);
                  // Open feedback form in browser
                  final Uri url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSdGjp1NhjeoLslMKkrN0RkfSuqy6_YCDUkt14rqy55Zf4ap3w/viewform');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: NavigationBar(
            height: 70,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onDestinationSelected: _onItemTapped,
            selectedIndex: _selectedIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 28,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 1 ? Icons.folder : Icons.folder_outlined,
                  size: 28,
                ),
                label: 'Sets',
              ),
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 2 ? Icons.bar_chart : Icons.bar_chart_outlined,
                  size: 28,
                ),
                label: 'Progress',
              ),
            ],
          ),
        ),
      ),
    );
  }
}



