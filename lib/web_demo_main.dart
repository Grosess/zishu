import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/writing_practice_page.dart';
import 'services/theme_service.dart';
import 'main.dart'; // For theme extensions

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const WebDemoApp());
}

class WebDemoApp extends StatefulWidget {
  const WebDemoApp({super.key});

  @override
  State<WebDemoApp> createState() => _WebDemoAppState();
}

class _WebDemoAppState extends State<WebDemoApp> {
  final ThemeService _themeService = ThemeService();
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    await _themeService.loadTheme();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        ThemeData theme;
        ThemeData darkTheme;
        
        if (_themeService.isDuotoneTheme) {
          theme = _themeService.currentDuotoneTheme!.theme;
          darkTheme = theme; // Duotone themes don't change with system
        } else {
          theme = ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          );
          darkTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          );
        }
        
        return MaterialApp(
          title: 'Zishu Demo',
          theme: theme,
          darkTheme: darkTheme,
          themeMode: _themeService.themeMode,
          home: const DemoScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // Demo characters to cycle through
  final List<String> demoCharacters = ['一', '人', '大', '水', '火', '木'];
  int currentIndex = 0;

  void _nextCharacter() {
    setState(() {
      currentIndex = (currentIndex + 1) % demoCharacters.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: WritingPracticePage(
            character: demoCharacters[currentIndex],
            characterSet: 'Demo',
            mode: PracticeMode.learning,
            allCharacters: demoCharacters,
            onComplete: (success) {
              // Automatically advance to next character
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _nextCharacter();
                }
              });
            },
          ),
        ),
      ),
    );
  }
}