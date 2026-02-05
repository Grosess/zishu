import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import '../services/learning_service.dart';
import '../services/statistics_service.dart';
import '../services/streak_service.dart';
import '../services/profile_service.dart';
import '../main.dart' show DuotoneThemeExtension, restartApp, MainScreen;
import '../l10n/app_localizations.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  final LocalStorageService _storageService = LocalStorageService();
  final LearningService _learningService = LearningService();
  final TextEditingController _importController = TextEditingController();
  bool _isLoading = false;
  String? _exportedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dataBackup),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.backup,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.exportData,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.saveProgressToShare,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.download),
                      label: Text(AppLocalizations.of(context)!.exportDataButton),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (_exportedData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.exportedDataTapToCopy,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () => _copyToClipboard(_exportedData!),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _copyToClipboard(_exportedData!),
                              child: Text(
                                _exportedData!.length > 200
                                    ? '${_exportedData!.substring(0, 200)}...'
                                    : _exportedData!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
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
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restore,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.importData,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.restoreProgress,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _importController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.pasteExportedData,
                        hintText: AppLocalizations.of(context)!.pasteExportedData,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.upload),
                      label: Text(AppLocalizations.of(context)!.importDataButton),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.howItWorks,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.exportDataStep1),
                    Text(AppLocalizations.of(context)!.exportDataStep2),
                    Text(AppLocalizations.of(context)!.exportDataStep3),
                    Text(AppLocalizations.of(context)!.exportDataStep4),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.backupNote,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Divider(
              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                  ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withValues(alpha: 0.2)
                  : null,
            ),
            const SizedBox(height: 32),
            // Reset All Data Section
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 32,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.dangerZone,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.permanentlyDeleteAllData,
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.deleteAllDataWarning,
                      style: TextStyle(
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showResetConfirmationDialog,
                        icon: const Icon(Icons.delete_forever),
                        label: Text(AppLocalizations.of(context)!.resetAllData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
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
    );
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _storageService.exportData();
      setState(() {
        _exportedData = data;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dataExportedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    final data = _importController.text.trim();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleasePasteDataToImport),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final success = await _storageService.importData(data);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (success) {
          _importController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.dataImportedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidDataFormat),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToImportData),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copiedToClipboard),
      ),
    );
  }
  
  Future<void> _showResetConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.confirmReset),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.confirmResetQuestion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.thisWillPermanentlyDelete),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.allLearnedCharactersAndWords),
            Text(AppLocalizations.of(context)!.allPracticeHistoryAndStats),
            Text(AppLocalizations.of(context)!.allCustomCharacterSets),
            Text(AppLocalizations.of(context)!.allFoldersAndOrganization),
            Text(AppLocalizations.of(context)!.allSettingsAndPreferences),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.thisActionCannotBeUndone,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.yesDeleteEverything),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _resetAllData();
    }
  }
  
  Future<void> _resetAllData() async {
    setState(() => _isLoading = true);
    
    try {
      // Import necessary services
      final StatisticsService statsService = StatisticsService();
      final StreakService streakService = StreakService();
      final ProfileService profileService = ProfileService();
      
      // Reset all data using the storage service (this clears SharedPreferences)
      await _storageService.clearAllData();
      
      // Reset profile service to clear user data from memory
      profileService.resetProfile();
      
      // Set default theme based on system brightness
      final prefs = await SharedPreferences.getInstance();
      final systemBrightness = MediaQuery.of(context).platformBrightness;
      
      // Set duotone theme as default
      await prefs.setString('theme_mode', 'duotone');
      
      // Set duotone colors based on system brightness
      if (systemBrightness == Brightness.light) {
        // Light mode: white background, blue accent
        await prefs.setString('duotone_background', 'white');
        await prefs.setString('duotone_color', 'blue');
      } else {
        // Dark mode: black background, blue accent
        await prefs.setString('duotone_background', 'black');
        await prefs.setString('duotone_color', 'blue');
      }
      
      // Reset user name and profile picture (they will be cleared automatically by clearAllData)
      // No need to explicitly reset them as clearAllData removes all SharedPreferences keys
      
      // Reset learning data and clear cache
      await _learningService.resetLearningData();
      _learningService.clearCache();
      
      // Clear statistics service cache
      statsService.clearCache();
      
      // Reset streak data
      await streakService.resetStreak();
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        // Check if duotone theme is set (it will be after reset)
        final prefs = await SharedPreferences.getInstance();
        final themeMode = prefs.getString('theme_mode') ?? 'duotone';
        final isDuotone = themeMode == 'duotone';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.allDataHasBeenReset),
            backgroundColor: isDuotone ? Colors.blue : Colors.green,
          ),
        );
        
        // Restart the app to reload theme settings
        restartApp();
        
        // Navigate to home and clear all navigation history
        // This forces all widgets to rebuild with fresh data
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }
}