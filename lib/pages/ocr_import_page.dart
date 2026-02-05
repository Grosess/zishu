import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/character_set_manager.dart';
import '../services/haptic_service.dart';
import '../main.dart' show DuotoneThemeExtension;
import '../generated/l10n.dart';
import '../l10n/app_localizations.dart';

class OCRImportPage extends StatefulWidget {
  const OCRImportPage({super.key});

  @override
  State<OCRImportPage> createState() => _OCRImportPageState();
}

class _OCRImportPageState extends State<OCRImportPage> {
  final OCRService _ocrService = OCRService();
  final CharacterSetManager _setManager = CharacterSetManager();
  
  bool _isProcessing = false;
  List<VocabItem>? _scannedItems;
  String _setName = '';
  final TextEditingController _nameController = TextEditingController();
  
  // Photo collection state
  List<XFile> _selectedImages = [];
  bool _isCollectingPhotos = true; // New state for photo collection vs scanning
  int _termsPerGroup = 10; // Default terms per group
  bool _isPickingImage = false; // Prevent multiple simultaneous picker calls
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _addPhotoFromCamera() async {
    if (_isPickingImage) return;
    
    setState(() {
      _isPickingImage = true;
    });
    
    try {
      // Ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 50));
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          if (mounted) {
            _showError('Camera timeout - please try again');
          }
          return null;
        },
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to capture image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }
  
  Future<void> _addPhotosFromGallery() async {
    if (_isPickingImage) return;
    
    setState(() {
      _isPickingImage = true;
    });
    
    try {
      // Ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 50));
      
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultipleMedia(
        limit: 10,
        imageQuality: 85,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          if (mounted) {
            _showError('Gallery timeout - please try again');
          }
          return [];
        },
      );
      
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to select images: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }
  
  Future<void> _processImages() async {
    if (_selectedImages.isEmpty) {
      _showError('Please add at least one image');
      return;
    }
    
    if (!Platform.isIOS) {
      _showError('OCR is currently only available on iOS devices');
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _isCollectingPhotos = false;
    });
    
    // Show loading dialog for model download
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(S.of(context).ocrProcessing),
              const SizedBox(height: 8),
              Text(
                S.of(context).downloadingModel,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    try {
      final items = await _ocrService.processSelectedImages(_selectedImages);
      
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (items.isEmpty) {
        _showError('No vocabulary items found in the images');
        setState(() {
          _isCollectingPhotos = true;
        });
      } else {
        setState(() {
          _scannedItems = items;
        });
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showError('Failed to process images: ${e.toString()}');
      setState(() {
        _isCollectingPhotos = true;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  void _showError(String message) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExtension = Theme.of(context).extension<DuotoneThemeExtension>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDuotone && duotoneExtension?.duotoneColor2 != null
            ? duotoneExtension!.duotoneColor2!
            : Colors.red,
      ),
    );
  }
  
  Future<void> _saveAsCharacterSet() async {
    if (_scannedItems == null || _scannedItems!.isEmpty) {
      _showError('No items to save');
      return;
    }
    
    if (_setName.isEmpty) {
      _showError('Please enter a name for the character set');
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final characters = _scannedItems!.map((item) => item.character).toList();
      
      // Create a map of character to definition for OCR-imported sets
      final Map<String, String> definitions = {};
      for (final item in _scannedItems!) {
        definitions[item.character] = item.definition;
      }
      
      // Check if we have multi-character terms (word set) or single characters
      final hasMultiCharTerms = characters.any((char) => char.length > 1);
      
      final characterSet = await _setManager.createCustomSet(
        name: _setName,
        characters: characters,
        description: 'Imported via OCR from vocabulary sheet',
        isWordSet: hasMultiCharTerms,
        source: 'ocr_import',
        definitions: definitions,
        groupSize: _termsPerGroup,
      );
      
      HapticService().mediumImpact();
      
      if (mounted) {
        Navigator.pop(context, characterSet);
      }
    } catch (e) {
      _showError('Failed to save character set: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExtension = Theme.of(context).extension<DuotoneThemeExtension>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCollectingPhotos ? S.of(context).addPhotos : S.of(context).importFromPhoto),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: _isCollectingPhotos && _selectedImages.isNotEmpty ? [
          TextButton(
            onPressed: _clearAllImages,
            child: Text(
              S.of(context).removeAll,
              style: TextStyle(
                color: isDuotone && duotoneExtension?.duotoneColor2 != null
                    ? duotoneExtension!.duotoneColor2!
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ] : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isCollectingPhotos) ...[
              // Photo collection mode
              if (_selectedImages.isEmpty) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera,
                          size: 80,
                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? duotoneExtension!.duotoneColor1!.withAlpha(128)
                              : Theme.of(context).colorScheme.primary.withAlpha(128),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Add photos of your vocabulary sheet',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take photos or select from gallery',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                ? duotoneExtension!.duotoneColor1!.withAlpha(179)
                                : Theme.of(context).colorScheme.onSurface.withAlpha(179),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isPickingImage ? null : () async => await _addPhotoFromCamera(),
                              icon: const Icon(Icons.camera_alt),
                              label: Text(S.of(context).takePhoto),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                minimumSize: const Size(200, 50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isPickingImage ? null : () async => await _addPhotosFromGallery(),
                              icon: const Icon(Icons.photo_library),
                              label: Text(S.of(context).selectFromGallery),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                minimumSize: const Size(200, 50),
                                backgroundColor: isDuotone && duotoneExtension?.duotoneColor2 != null
                                    ? duotoneExtension!.duotoneColor2!
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Show selected images
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${_selectedImages.length} photo${_selectedImages.length != 1 ? 's' : ''} selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                          ? duotoneExtension!.duotoneColor1!
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _selectedImages.length + 1, // +1 for add more button
                    itemBuilder: (context, index) {
                      if (index == _selectedImages.length) {
                        // Add more button
                        return InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: Text(S.of(context).takePhoto),
                                      enabled: !_isPickingImage,
                                      onTap: _isPickingImage ? null : () async {
                                        Navigator.pop(context);
                                        // Add a small delay to ensure modal is closed
                                        await Future.delayed(const Duration(milliseconds: 100));
                                        await _addPhotoFromCamera();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: Text(S.of(context).selectFromGallery),
                                      enabled: !_isPickingImage,
                                      onTap: _isPickingImage ? null : () async {
                                        Navigator.pop(context);
                                        // Add a small delay to ensure modal is closed
                                        await Future.delayed(const Duration(milliseconds: 100));
                                        await _addPhotosFromGallery();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                  ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                                  : Theme.of(context).colorScheme.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                    ? duotoneExtension!.duotoneColor1!.withAlpha(77)
                                    : Theme.of(context).colorScheme.primary.withAlpha(77),
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 40,
                              color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                  ? duotoneExtension!.duotoneColor1!
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }
                      
                      // Image preview
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(128),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Terms per group setting - Clear and prominent
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                        ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                        : Theme.of(context).colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                          ? duotoneExtension!.duotoneColor1!.withAlpha(77)
                          : Theme.of(context).colorScheme.primary.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group_work,
                            size: 20,
                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                ? duotoneExtension!.duotoneColor1!
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Practice Group Size',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                  ? duotoneExtension!.duotoneColor1!
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How many vocabulary terms will be practiced together in each study session',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? duotoneExtension!.duotoneColor1!.withAlpha(179)
                              : Theme.of(context).colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDuotone && duotoneExtension?.duotoneColor2 != null
                                  ? duotoneExtension!.duotoneColor2!.withAlpha(77)
                                  : Theme.of(context).colorScheme.primary.withAlpha(77),
                              border: Border.all(
                                color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                    ? duotoneExtension!.duotoneColor1!
                                    : Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _termsPerGroup,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                      ? duotoneExtension!.duotoneColor1!
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                dropdownColor: isDuotone && duotoneExtension?.duotoneColor2 != null
                                    ? duotoneExtension!.duotoneColor2!
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                menuMaxHeight: 200, // Make it scrollable
                                style: TextStyle(
                                  color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                      ? duotoneExtension!.duotoneColor1!
                                      : Theme.of(context).colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: List.generate(25, (index) {
                                  final value = index + 1;
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                              ? duotoneExtension!.duotoneColor1!
                                              : Theme.of(context).colorScheme.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _termsPerGroup = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'vocabulary terms per practice session',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Example: 10 = practice 10 words at a time',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!.withAlpha(128)
                                        : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Process button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processImages,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isDuotone && duotoneExtension?.duotoneColor2 != null
                            ? duotoneExtension!.duotoneColor2!
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: isDuotone && duotoneExtension?.duotoneColor2 != null
                            ? duotoneExtension!.duotoneColor1!
                            : Colors.white,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.document_scanner),
                          const SizedBox(width: 8),
                          Text(S.of(context).scanVocabulary),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              S.of(context).beta,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ] else if (_isProcessing) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text(S.of(context).processingImages),
                      SizedBox(height: 8),
                      Text(S.of(context).extractingCharacters),
                      SizedBox(height: 8),
                      Text(S.of(context).mayTakeMoment),
                    ],
                  ),
                ),
              ),
            ] else if (_scannedItems != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.characterSetName,
                    hintText: AppLocalizations.of(context)!.enterNameForSet,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _setName = value;
                    });
                  },
                ),
              ),
              // Spreadsheet-style table view
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                          ? duotoneExtension!.duotoneColor1!.withAlpha(77)
                          : Theme.of(context).colorScheme.outline.withAlpha(77),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Container(
                        decoration: BoxDecoration(
                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                              : Theme.of(context).colorScheme.primary.withAlpha(26),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7),
                            topRight: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                          ? duotoneExtension!.duotoneColor1!.withAlpha(51)
                                          : Theme.of(context).colorScheme.outline.withAlpha(51),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Chinese',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                          ? duotoneExtension!.duotoneColor1!.withAlpha(51)
                                          : Theme.of(context).colorScheme.outline.withAlpha(51),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Pinyin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'English',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Data rows
                      Expanded(
                        child: ListView.builder(
                          itemCount: _scannedItems!.length,
                          itemBuilder: (context, index) {
                            final item = _scannedItems![index];
                            final pinyin = (item.rawData?['pinyin'] ?? '') as String;
                            final isEvenRow = index % 2 == 0;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isEvenRow 
                                    ? Colors.transparent
                                    : (isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!.withAlpha(13)
                                        : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(26)),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                        ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                                        : Theme.of(context).colorScheme.outline.withAlpha(26),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                                ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                                                : Theme.of(context).colorScheme.outline.withAlpha(26),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        item.character,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                                ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                                                : Theme.of(context).colorScheme.outline.withAlpha(26),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        pinyin.isEmpty || pinyin == 'null' ? '-' : pinyin,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                              ? duotoneExtension!.duotoneColor1!.withAlpha(204)
                                              : Theme.of(context).colorScheme.onSurface.withAlpha(204),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        (item.definition.isEmpty || item.definition == 'No definition' || item.definition == 'null') ? '-' : item.definition,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                              ? duotoneExtension!.duotoneColor1!.withAlpha(230)
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Summary row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? duotoneExtension!.duotoneColor1!.withAlpha(13)
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(51),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Total: ${_scannedItems!.length} items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                    ? duotoneExtension!.duotoneColor1!.withAlpha(179)
                                    : Theme.of(context).colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetToPhotoCollection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? BorderSide(color: duotoneExtension!.duotoneColor1!)
                              : null,
                          foregroundColor: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? duotoneExtension!.duotoneColor1!
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _setName.isNotEmpty ? _saveAsCharacterSet : null,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Set'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: isDuotone && duotoneExtension?.duotoneColor2 != null
                              ? duotoneExtension!.duotoneColor2!
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: isDuotone && duotoneExtension?.duotoneColor2 != null
                              ? duotoneExtension!.duotoneColor1!
                              : Colors.white,
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
    );
  }
  
  void _resetToPhotoCollection() {
    setState(() {
      _isCollectingPhotos = true;
      _scannedItems = null;
      _setName = '';
      _nameController.clear();
    });
  }
}