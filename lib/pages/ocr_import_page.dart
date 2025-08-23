import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/character_set_manager.dart';
import '../services/haptic_service.dart';
import '../main.dart' show DuotoneThemeExtension;

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
  int _termsPerGroup = 8; // Default terms per group for testing
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _addPhotoFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showError('Failed to capture image: ${e.toString()}');
    }
  }
  
  Future<void> _addPhotosFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultipleMedia(
        limit: 10,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showError('Failed to select images: ${e.toString()}');
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
    
    try {
      final items = await _ocrService.processSelectedImages(_selectedImages);
      
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
      
      // Check if we have multi-character terms (word set) or single characters
      final hasMultiCharTerms = characters.any((char) => char.length > 1);
      
      final characterSet = await _setManager.createCustomSet(
        name: _setName,
        characters: characters,
        description: 'Imported via OCR from vocabulary sheet',
        isWordSet: hasMultiCharTerms,
        source: 'ocr_import',
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
        title: Text(_isCollectingPhotos ? 'Add Photos' : 'Import from Photo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: _isCollectingPhotos && _selectedImages.isNotEmpty ? [
          TextButton(
            onPressed: _clearAllImages,
            child: Text(
              'Clear All',
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
                              onPressed: _addPhotoFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                minimumSize: const Size(200, 50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addPhotosFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Select from Gallery'),
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
                                      title: const Text('Take Photo'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _addPhotoFromCamera();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Select from Gallery'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _addPhotosFromGallery();
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
                // Terms per group setting
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Terms per group (for testing):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDuotone && duotoneExtension?.duotoneColor1 != null
                              ? duotoneExtension!.duotoneColor1!
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 60,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                ? duotoneExtension!.duotoneColor1!.withAlpha(128)
                                : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: TextEditingController(text: _termsPerGroup.toString()),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                ? duotoneExtension!.duotoneColor1!
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          ),
                          onChanged: (value) {
                            final int? newValue = int.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              setState(() {
                                _termsPerGroup = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Process button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _processImages,
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scan Vocabulary'),
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
                    ),
                  ),
                ),
              ],
            ] else if (_isProcessing) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text('Processing images...'),
                      SizedBox(height: 8),
                      Text('Extracting Chinese characters and definitions'),
                      SizedBox(height: 8),
                      Text('This may take a moment for multiple images'),
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
                    labelText: 'Character Set Name',
                    hintText: 'Enter a name for this set',
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Found ${_scannedItems!.length} vocabulary items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDuotone && duotoneExtension?.duotoneColor1 != null
                        ? duotoneExtension!.duotoneColor1!.withAlpha(179)
                        : Theme.of(context).colorScheme.onSurface.withAlpha(179),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _scannedItems!.length,
                  itemBuilder: (context, index) {
                    final item = _scannedItems![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                                : Theme.of(context).colorScheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.character,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        title: Text(
                          item.definition,
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.originalCharacter != item.character) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Traditional: ${item.originalCharacter}',
                                style: TextStyle(
                                  color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                      ? duotoneExtension!.duotoneColor1!.withAlpha(128)
                                      : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: item.confidence > 0
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                          ? duotoneExtension!.duotoneColor1!.withAlpha(26)
                                          : _getConfidenceColor(item.confidence).withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isDuotone ? Border.all(
                                        color: duotoneExtension?.duotoneColor1?.withAlpha(51) ?? Colors.transparent,
                                        width: 1,
                                      ) : null,
                                    ),
                                    child: Text(
                                      '${(item.confidence * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                            ? duotoneExtension!.duotoneColor1!
                                            : _getConfidenceColor(item.confidence),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getConfidenceLabel(item.confidence),
                                    style: TextStyle(
                                      color: isDuotone && duotoneExtension?.duotoneColor1 != null
                                          ? duotoneExtension!.duotoneColor1!.withAlpha(128)
                                          : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
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
  
  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.95) return 'Excellent';
    if (confidence >= 0.85) return 'Very Good';
    if (confidence >= 0.70) return 'Good';
    if (confidence >= 0.50) return 'Fair';
    return 'Review';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.95) return Colors.green;
    if (confidence >= 0.85) return Colors.lightGreen;
    if (confidence >= 0.70) return Colors.orange;
    if (confidence >= 0.50) return Colors.deepOrange;
    return Colors.red;
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