import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  static const MethodChannel _channel = MethodChannel('com.zishu.ocr');
  static final OCRService _instance = OCRService._internal();
  
  factory OCRService() => _instance;
  
  OCRService._internal();
  
  final ImagePicker _picker = ImagePicker();
  
  Future<List<VocabItem>> scanVocabSheet({ImageSource source = ImageSource.camera, bool allowMultiple = true}) async {
    try {
      if (allowMultiple && source == ImageSource.gallery) {
        // Try multiple image selection for gallery
        try {
          final List<XFile> images = await _picker.pickMultipleMedia(
            limit: 10,
            imageQuality: 85,
          );
          
          if (images.isNotEmpty) {
            return await _processMultipleImages(images);
          }
        } catch (e) {
          // Fall back to single image if multiple selection fails
        }
      }
      
      // Single image selection
      return await _scanSingleImage(source);
    } catch (e) {
      print('OCR Error: $e');
      rethrow;
    }
  }
  
  Future<List<VocabItem>> processSelectedImages(List<XFile> images) async {
    return await _processMultipleImages(images);
  }
  
  Future<List<VocabItem>> _processMultipleImages(List<XFile> images) async {
    final List<VocabItem> allItems = [];
    final Set<String> seenCharacters = {};
    
    for (int i = 0; i < images.length; i++) {
      try {
        final imageBytes = await images[i].readAsBytes();
        
        if (!Platform.isIOS) {
          throw UnsupportedError('OCR is currently only supported on iOS');
        }
        
        final List<dynamic> results = await _channel.invokeMethod('performOCR', {
          'imageData': imageBytes,
        });
        
        for (final result in results) {
          final String character = result['character'] ?? '';
          final String definition = result['definition'] ?? '';
          
          if (character.isNotEmpty && !seenCharacters.contains(character)) {
            seenCharacters.add(character);
            
            String cleanedDefinition = _cleanDefinition(definition);
            
            if (cleanedDefinition.isNotEmpty && cleanedDefinition != 'No definition found') {
              allItems.add(VocabItem(
                character: character,
                definition: cleanedDefinition,
                originalCharacter: result['originalCharacter'] ?? character,
                confidence: (result['confidence'] ?? 0.0).toDouble(),
              ));
            }
          }
        }
      } catch (e) {
        print('Error processing image ${i + 1}: $e');
        // Continue with other images
      }
    }
    
    allItems.sort((a, b) => b.confidence.compareTo(a.confidence));
    return allItems;
  }
  
  Future<List<VocabItem>> _scanSingleImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    
    if (image == null) {
      throw Exception('No image selected');
    }
    
    final imageBytes = await image.readAsBytes();
    
    if (!Platform.isIOS) {
      throw UnsupportedError('OCR is currently only supported on iOS');
    }
    
    final List<dynamic> results = await _channel.invokeMethod('performOCR', {
      'imageData': imageBytes,
    });
    
    final List<VocabItem> vocabItems = [];
    final Set<String> seenCharacters = {};
    
    for (final result in results) {
      final String character = result['character'] ?? '';
      final String definition = result['definition'] ?? '';
      
      if (character.isNotEmpty && !seenCharacters.contains(character)) {
        seenCharacters.add(character);
        
        String cleanedDefinition = _cleanDefinition(definition);
        
        if (cleanedDefinition.isNotEmpty) {
          vocabItems.add(VocabItem(
            character: character,
            definition: cleanedDefinition,
            originalCharacter: result['originalCharacter'] ?? character,
            confidence: (result['confidence'] ?? 0.0).toDouble(),
          ));
        }
      }
    }
    
    vocabItems.sort((a, b) => b.confidence.compareTo(a.confidence));
    return vocabItems;
  }
  
  String _cleanDefinition(String definition) {
    if (definition.isEmpty) {
      return 'No definition found';
    }
    
    String cleaned = definition
        .replaceAll(RegExp(r'^\d+\.?\s*'), '') // Remove line numbers
        .replaceAll(RegExp(r'^[,;]\s*'), '') // Remove leading punctuation
        .trim();
    
    if (cleaned.isEmpty) {
      return 'No definition found';
    }
    
    return cleaned;
  }
  
  Future<Map<String, dynamic>> createCharacterSetFromOCR({
    required List<VocabItem> items,
    required String setName,
  }) async {
    final List<Map<String, dynamic>> characters = [];
    
    for (final item in items) {
      characters.add({
        'character': item.character,
        'definition': item.definition,
        'isCustomDefinition': true,
      });
    }
    
    return {
      'name': setName,
      'characters': characters,
      'source': 'ocr_import',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

class VocabItem {
  final String character;
  final String definition;
  final String originalCharacter;
  final double confidence;
  
  VocabItem({
    required this.character,
    required this.definition,
    required this.originalCharacter,
    this.confidence = 0.0,
  });
  
  Map<String, dynamic> toJson() => {
    'character': character,
    'definition': definition,
    'originalCharacter': originalCharacter,
    'confidence': confidence,
  };
}