import 'package:flutter/material.dart';
import '../services/character_set_manager.dart';
import '../main.dart' show DuotoneThemeExtension, refreshStreakDisplay, refreshSetsProgress;
import '../services/character_database.dart';
import '../services/learning_service.dart';
import '../services/statistics_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class MarkAsLearnedPage extends StatefulWidget {
  const MarkAsLearnedPage({super.key});

  @override
  State<MarkAsLearnedPage> createState() => _MarkAsLearnedPageState();
}

class _MarkAsLearnedPageState extends State<MarkAsLearnedPage> {
  final CharacterSetManager _characterSetManager = CharacterSetManager();
  final CharacterDatabase _characterDatabase = CharacterDatabase();
  final LearningService _learningService = LearningService();
  
  LearningService _getLearningService() => LearningService();
  
  List<String> _allCharacters = [];
  Map<String, bool> _learnedStatus = {};
  bool _isLoading = true;
  
  
  // Track if any changes were made
  bool _changesMade = false;
  
  // Key to force rebuild of count
  Key _countKey = UniqueKey();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
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
  
  
  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Known Characters'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter all characters you already know:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '你好世界学习中文...',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: You can paste characters from other sources.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _importCharacters(result);
    }
  }
  
  Future<void> _importCharacters(String text) async {
    // Extract all Chinese characters from the text
    final characters = <String>{};
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (_isChineseCharacter(char)) {
        characters.add(char);
      }
    }
    
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Chinese characters found in the input'),
        ),
      );
      return;
    }
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Mark all characters as learned in batch
    final charactersList = characters.toList();
    await _learningService.markCharactersAsLearned(charactersList, updateTodayProgress: false);
    final importedCount = charactersList.length;
    
    // Close progress dialog
    Navigator.pop(context);
    
    setState(() {
      _changesMade = true;
      _countKey = UniqueKey(); // Force count rebuild
    });
    
    // Clear caches to ensure UI updates
    final statsService = StatisticsService();
    statsService.clearCache();
    _learningService.clearCache();
    
    // Force SharedPreferences to reload to ensure data is persisted
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    // Reload all data to update the UI
    await _loadData();
    
    // Refresh streak display and sets progress
    try {
      refreshStreakDisplay();
      refreshSetsProgress();
    } catch (_) {
      // Ignore if main screen is not available
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(importedCount == 1 
            ? 'Imported 1 new character'
            : 'Imported $importedCount new characters'),
      ),
    );
  }
  
  Future<void> _importFromSkritter() async {
    // Show instructions dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Skritter'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To export your words from Skritter:'),
            SizedBox(height: 12),
            Text('1. Login to skritter.com'),
            Text('2. Press the three bars in the top left'),
            Text('3. Click "My Words"'),
            Text('4. Click "Export"'),
            Text('5. Save the file (.tsv or .csv)'),
            SizedBox(height: 12),
            Text('Then select the exported file to import.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select File'),
          ),
        ],
      ),
    );
    
    if (shouldProceed != true) return;
    
    // Open file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tsv', 'csv'],
    );
    
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await _parseSkritterFile(file);
    }
  }
  
  Future<void> _parseSkritterFile(File file) async {
    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // Determine if it's TSV or CSV
      final isTsv = file.path.endsWith('.tsv');
      final separator = isTsv ? '\t' : ',';
      
      final characters = <String>{};
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Split by separator
        final parts = line.split(separator);
        if (parts.isNotEmpty) {
          // The first column usually contains the Chinese characters/words
          final chineseText = parts[0].trim();
          
          // Extract individual Chinese characters
          for (int i = 0; i < chineseText.length; i++) {
            final char = chineseText[i];
            if (_isChineseCharacter(char)) {
              characters.add(char);
            }
          }
        }
      }
      
      // Close progress dialog
      Navigator.pop(context);
      
      if (characters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Chinese characters found in the file'),
          ),
        );
        return;
      }
      
      // Show confirmation dialog
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Import'),
          content: Text('Found ${characters.length} unique characters to import. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      
      if (shouldImport == true) {
        // Show progress dialog again
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Mark all characters as learned in batch
        final charactersList = characters.toList();
        await _learningService.markCharactersAsLearned(charactersList, updateTodayProgress: false);
        final importedCount = charactersList.length;
        
        // Close progress dialog
        Navigator.pop(context);
        
        setState(() {
          _changesMade = true;
          _countKey = UniqueKey(); // Force count rebuild
        });
        
        // Clear caches to ensure UI updates
        final statsService = StatisticsService();
        statsService.clearCache();
        _learningService.clearCache();
        
        // Force SharedPreferences to reload to ensure data is persisted
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        
        // Reload all data to update the UI
        await _loadData();
        
        // Refresh streak display and sets progress
        try {
          refreshStreakDisplay();
          refreshSetsProgress();
        } catch (_) {
          // Ignore if main screen is not available
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importedCount == 1
                ? 'Imported 1 new character from Skritter'
                : 'Imported $importedCount new characters from Skritter'),
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading file: ${e.toString()}'),
        ),
      );
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
          actions: [],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 24),
                Text(
                  'Import Your Known Characters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Material(
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                        : Theme.of(context).colorScheme.primary,
                    child: PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.upload, 
                              size: 24, 
                              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1
                                  : Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Import',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                    ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_drop_down, 
                              size: 24, 
                              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ),
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'text') {
                          _showImportDialog();
                        } else if (value == 'skritter') {
                          _importFromSkritter();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'text',
                          child: ListTile(
                            leading: Icon(
                              Icons.text_fields,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Import Text'),
                            subtitle: const Text('Paste characters you know'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'skritter',
                          child: ListTile(
                            leading: Icon(
                              Icons.file_upload,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Import from Skritter'),
                            subtitle: const Text('Upload .tsv or .csv file'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FutureBuilder<int>(
                  key: _countKey,
                  future: _getLearningService().getLearnedCharacters().then((chars) => chars.length),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      count == 1 
                          ? '1 character marked as learned'
                          : '$count characters marked as learned',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}