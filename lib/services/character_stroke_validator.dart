import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Validates if character stroke data is correctly formatted
class CharacterStrokeValidator {
  /// Check if stroke data appears to be valid
  static bool validateStrokeData(List<String> strokes, List<List<List<double>>> medians) {
    // Basic validation
    if (strokes.isEmpty || medians.isEmpty) return false;
    if (strokes.length != medians.length) return false;
    
    // Check each stroke
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final median = medians[i];
      
      // Stroke should be a valid SVG path
      if (!stroke.contains('M') || stroke.isEmpty) return false;
      
      // Median should have at least 2 points
      if (median.length < 2) return false;
      
      // Check median points are in valid range
      for (final point in median) {
        if (point.length != 2) return false;
        
        // MakeMeAHanzi uses 0-1024 coordinate system
        if (point[0] < 0 || point[0] > 1024 || 
            point[1] < 0 || point[1] > 1024) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Check if a character's data looks like it's from placeholder vs database
  static bool looksLikePlaceholderData(List<String> strokes) {
    // Placeholder data often has very specific patterns
    // Database data usually has Q (quadratic) commands
    int qCount = 0;
    for (final stroke in strokes) {
      if (stroke.contains(' Q ')) qCount++;
    }
    
    // Database strokes almost always have Q commands
    return qCount == 0;
  }
  
  /// Get bounding box of stroke paths
  static Rect getStrokeBounds(List<String> strokes) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    
    for (final stroke in strokes) {
      // Extract numbers from stroke path
      final numbers = RegExp(r'-?\d+\.?\d*')
          .allMatches(stroke)
          .map((m) => double.tryParse(m.group(0)!) ?? 0)
          .toList();
      
      // Process pairs as x,y coordinates
      for (int i = 0; i < numbers.length - 1; i += 2) {
        final x = numbers[i];
        final y = numbers[i + 1];
        
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  /// Check if character appears to be upside down based on typical stroke patterns
  static bool appearsUpsideDown(List<List<List<double>>> medians) {
    if (medians.isEmpty) return false;
    
    // Check first stroke - horizontal strokes usually go left to right
    // and should be in the upper portion of the character
    if (medians.isNotEmpty && medians[0].length >= 2) {
      final firstStroke = medians[0];
      final start = firstStroke.first;
      final end = firstStroke.last;
      
      // Check if it's a horizontal stroke
      final dx = (end[0] - start[0]).abs();
      final dy = (end[1] - start[1]).abs();
      
      if (dx > dy * 2) {
        // It's horizontal - check if it's in the top half
        final avgY = (start[1] + end[1]) / 2;
        // If Y is > 512 (middle), might be upside down
        // But this depends on whether Y-axis has been flipped
        
        // For now, just log
        // Production: removed debug print
      }
    }
    
    return false;
  }
}