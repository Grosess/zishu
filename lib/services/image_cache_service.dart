import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Service to manage image caching for better performance
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();
  
  // Cache for decoded images
  final Map<String, ui.Image> _imageCache = {};
  
  /// Preload essential images
  Future<void> preloadImages(BuildContext context) async {
    // Currently no images to preload
  }
  
  /// Clear image cache to free memory
  void clearCache() {
    _imageCache.clear();
    PaintingBinding.instance.imageCache.clear();
  }
  
  /// Clear cache if memory pressure is high
  void handleMemoryPressure() {
    // Clear non-essential images
    if (_imageCache.length > 5) {
      _imageCache.clear();
    }
    
    // Reduce Flutter's image cache
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.currentSizeBytes > 25 * 1024 * 1024) { // 25MB
      imageCache.clear();
    }
  }
  
  /// Configure optimal cache settings
  static void configureImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    // Set maximum cache size to 50MB
    imageCache.maximumSizeBytes = 50 * 1024 * 1024;
    // Set maximum number of images to 100
    imageCache.maximumSize = 100;
  }
}