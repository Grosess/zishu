import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import '../services/learning_service.dart';
import '../services/statistics_service.dart';
import '../services/streak_service.dart';
import '../main.dart' show DuotoneThemeExtension, restartApp, MainScreen;

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
        title: const Text('Data Backup'),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Data',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Save your progress to share with other devices',
                                style: TextStyle(fontSize: 14),
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
                      label: const Text('Export Data'),
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
                                const Text(
                                  'Exported Data (tap to copy):',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Data',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Restore your progress from another device',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _importController,
                      decoration: const InputDecoration(
                        labelText: 'Paste exported data here',
                        hintText: 'Paste the JSON data from export',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.upload),
                      label: const Text('Import Data'),
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
                    const Text(
                      'How it works:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Export your data on one device'),
                    const Text('2. Copy the exported text'),
                    const Text('3. Send it to your other device (email, message, etc.)'),
                    const Text('4. Paste and import on the other device'),
                    const SizedBox(height: 16),
                    Text(
                      'Note: This is a simple backup solution. Your data stays on your devices only.',
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
                                'Danger Zone',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Permanently delete all your data',
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
                      'This will delete all your learned characters, practice history, custom sets, and all other data. This action cannot be undone!',
                      style: TextStyle(
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showResetConfirmationDialog,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Reset All Data'),
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
          const SnackBar(
            content: Text('Data exported successfully'),
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
        const SnackBar(
          content: Text('Please paste data to import'),
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
            const SnackBar(
              content: Text('Data imported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid data format'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
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
            const Text('Confirm Reset'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you absolutely sure you want to reset all data?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('This will permanently delete:'),
            SizedBox(height: 8),
            Text('• All learned characters and words'),
            Text('• All practice history and statistics'),
            Text('• All custom character sets'),
            Text('• All folders and organization'),
            Text('• All settings and preferences'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete Everything'),
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
      
      // Reset all data using the storage service (this clears SharedPreferences)
      await _storageService.clearAllData();
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset'),
            backgroundColor: Colors.green,
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