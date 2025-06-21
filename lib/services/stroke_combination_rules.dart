import 'dart:ui';

/// Defines rules for characters that can have strokes combined in common writing styles
class StrokeCombinationRules {
  static final Map<String, List<CombinationRule>> _rules = {
    '女': [
      CombinationRule(
        character: '女',
        combinableStrokes: [1, 2], // Second and third strokes can be combined
        description: 'The turning stroke and final stroke can be written continuously',
        ignoreDirection: true,
      ),
    ],
    '子': [
      CombinationRule(
        character: '子',
        combinableStrokes: [0, 1], // First and second strokes can be combined
        description: 'The horizontal and hook can be written as one continuous stroke',
      ),
    ],
    '了': [
      CombinationRule(
        character: '了',
        combinableStrokes: [0, 1], // Can be written as one stroke
        description: 'Can be written as a single curved stroke',
      ),
    ],
    '好': [
      CombinationRule(
        character: '好',
        combinableStrokes: [1, 2], // Second and third strokes of 女 radical (the turning stroke)
        description: 'The turning strokes of 女 can be written continuously',
        ignoreDirection: true,
      ),
      CombinationRule(
        character: '好',
        combinableStrokes: [3, 4], // Last two strokes of 子 radical can be combined (the hook shape)
        description: 'The curved strokes of 子 can be written as one',
      ),
    ],
    '如': [
      CombinationRule(
        character: '如',
        combinableStrokes: [1, 2], // The turning strokes of 女 radical
        description: 'The turning strokes can be written continuously',
        ignoreDirection: true,
      ),
    ],
    '妈': [
      CombinationRule(
        character: '妈',
        combinableStrokes: [1, 2], // The turning strokes of 女 radical
        description: 'The turning strokes can be written continuously',
        ignoreDirection: true,
      ),
    ],
  };

  /// Check if a character allows certain strokes to be combined
  static bool canCombineStrokes(String character, int strokeIndex1, int strokeIndex2) {
    final rules = _rules[character];
    if (rules == null) return false;
    
    for (final rule in rules) {
      if (rule.combinableStrokes.contains(strokeIndex1) &&
          rule.combinableStrokes.contains(strokeIndex2) &&
          (strokeIndex2 - strokeIndex1).abs() == 1) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get all combinable stroke groups for a character
  static List<List<int>> getCombinableGroups(String character) {
    final rules = _rules[character];
    if (rules == null) return [];
    
    return rules.map((rule) => rule.combinableStrokes).toList();
  }
  
  /// Check if a user stroke might be a combination of multiple strokes
  static CombinedStrokeMatch? checkCombinedStroke(
    String character,
    List<Offset> userStroke,
    List<int> remainingStrokes,
    List<List<List<double>>> allMedians,
    Size canvasSize,
  ) {
    final groups = getCombinableGroups(character);
    
    // Sort remaining strokes to find the earliest possible combination
    remainingStrokes.sort();
    
    // Only check combinations that start with the next expected stroke
    final nextExpectedStroke = remainingStrokes.isEmpty ? 0 : remainingStrokes.first;
    
    for (final group in groups) {
      // Skip if this combination doesn't include the next expected stroke
      if (!group.contains(nextExpectedStroke)) {
        continue;
      }
      
      // Check if all strokes in this group are still remaining
      if (!group.every((index) => remainingStrokes.contains(index))) {
        continue;
      }
      
      // Try to match the user stroke against the combined path
      final combinedMedians = <List<double>>[];
      for (final strokeIndex in group) {
        if (strokeIndex < allMedians.length) {
          combinedMedians.addAll(allMedians[strokeIndex]);
        }
      }
      
      if (combinedMedians.isNotEmpty) {
        // Special handling for different characters
        bool match;
        if (character == '女' && group.contains(1) && group.contains(2)) {
          // For 女 strokes 1+2, use special matching
          match = _matchesCombinedPathForNv(userStroke, combinedMedians, canvasSize);
        } else if (character == '子' && group.contains(0) && group.contains(1)) {
          // For 子 strokes 0+1, use strict matching to prevent false positives
          match = _matchesCombinedPathStrict(userStroke, combinedMedians, canvasSize);
        } else {
          // Regular matching for other characters
          match = _matchesCombinedPath(
            userStroke, 
            combinedMedians, 
            canvasSize,
            numberOfStrokes: group.length,
          );
        }
        
        if (match) {
          return CombinedStrokeMatch(
            matchedStrokes: group,
            confidence: 0.8,
          );
        }
      }
    }
    
    return null;
  }
  
  static bool _matchesCombinedPath(
    List<Offset> userStroke,
    List<List<double>> combinedMedians,
    Size canvasSize,
    {int numberOfStrokes = 2}
  ) {
    // Much longer stroke required for combinations
    if (userStroke.length < 30) {
      return false;
    }
    
    final padding = canvasSize.width * 0.1;
    final drawSize = canvasSize.width - (padding * 2);
    final scale = drawSize / 1024;
    
    // Very lenient tolerance
    final tolerance = canvasSize.width * 0.2;
    
    // Convert all median points to canvas coordinates
    final medianPoints = combinedMedians.map((median) => Offset(
      median[0] * scale + padding,
      (1024 - median[1]) * scale + padding,
    )).toList();
    
    // Simple approach: just check if the user stroke covers key points
    int coveredPoints = 0;
    final keyPointIndices = <int>[];
    
    // Select key points to check (start, end, and some middle points)
    keyPointIndices.add(0); // Start of first stroke
    if (medianPoints.length > 10) {
      keyPointIndices.add(medianPoints.length ~/ 4);
      keyPointIndices.add(medianPoints.length ~/ 2);
      keyPointIndices.add(3 * medianPoints.length ~/ 4);
    }
    keyPointIndices.add(medianPoints.length - 1); // End of combined stroke
    
    // Check if user stroke passes near these key points
    for (final idx in keyPointIndices) {
      if (idx >= medianPoints.length) continue;
      
      final keyPoint = medianPoints[idx];
      double minDist = double.infinity;
      
      for (final userPoint in userStroke) {
        final dist = (userPoint - keyPoint).distance;
        if (dist < minDist) minDist = dist;
      }
      
      if (minDist < tolerance) {
        coveredPoints++;
      }
    }
    
    // For 女 specifically, be very lenient
    // If we cover at least 3 key points, accept it
    if (coveredPoints >= 3) {
      return true;
    }
    
    // Alternative check: see if user stroke follows the general path
    // by checking if it stays within tolerance of the median path
    int nearPathPoints = 0;
    
    for (final userPoint in userStroke) {
      double minDist = double.infinity;
      
      for (final medianPoint in medianPoints) {
        final dist = (userPoint - medianPoint).distance;
        if (dist < minDist) minDist = dist;
      }
      
      if (minDist < tolerance) {
        nearPathPoints++;
      }
    }
    
    // If at least 50% of user stroke points are near the path, accept it
    // But also require substantial coverage of the expected path
    if (nearPathPoints < userStroke.length * 0.5) {
      return false;
    }
    
    // Also check that we cover enough of the expected path
    int coveredMedianPoints = 0;
    for (final medianPoint in medianPoints) {
      for (final userPoint in userStroke) {
        if ((userPoint - medianPoint).distance < tolerance) {
          coveredMedianPoints++;
          break;
        }
      }
    }
    
    // Must cover at least 70% of the expected path
    return coveredMedianPoints >= medianPoints.length * 0.7;
  }
  
  /// Special lenient matching for 女 character strokes 1+2
  static bool _matchesCombinedPathForNv(
    List<Offset> userStroke,
    List<List<double>> combinedMedians,
    Size canvasSize,
  ) {
    // Need reasonable length for combined stroke
    if (userStroke.length < 15) return false;
    
    final padding = canvasSize.width * 0.1;
    final drawSize = canvasSize.width - (padding * 2);
    final scale = drawSize / 1024;
    
    // Convert median points
    final medianPoints = combinedMedians.map((median) => Offset(
      median[0] * scale + padding,
      (1024 - median[1]) * scale + padding,
    )).toList();
    
    if (medianPoints.length < 6) return false;
    
    // Split median points into two strokes
    final firstStrokeEnd = medianPoints.length ~/ 2;
    final firstStrokePoints = medianPoints.sublist(0, firstStrokeEnd);
    final secondStrokePoints = medianPoints.sublist(firstStrokeEnd);
    
    // Check coverage of both strokes
    final tolerance = canvasSize.width * 0.2;
    bool coversFirstStroke = false;
    bool coversSecondStroke = false;
    
    // Check if user stroke covers key points from first stroke
    for (final medianPoint in firstStrokePoints) {
      for (final userPoint in userStroke) {
        if ((userPoint - medianPoint).distance < tolerance) {
          coversFirstStroke = true;
          break;
        }
      }
      if (coversFirstStroke) break;
    }
    
    // Check if user stroke covers key points from second stroke
    for (final medianPoint in secondStrokePoints) {
      for (final userPoint in userStroke) {
        if ((userPoint - medianPoint).distance < tolerance) {
          coversSecondStroke = true;
          break;
        }
      }
      if (coversSecondStroke) break;
    }
    
    // Must cover both strokes
    if (!coversFirstStroke || !coversSecondStroke) {
      return false;
    }
    
    // Additional check: start and end points
    final startDist = (userStroke.first - medianPoints.first).distance;
    final endDist = (userStroke.last - medianPoints.last).distance;
    
    // Both start and end should be reasonably close
    return startDist < tolerance * 1.5 && endDist < tolerance * 1.5;
  }
  
  /// Very strict matching for 子 character strokes 0+1 to prevent false positives
  static bool _matchesCombinedPathStrict(
    List<Offset> userStroke,
    List<List<double>> combinedMedians,
    Size canvasSize,
  ) {
    // Need very long stroke for combined - much longer than individual strokes
    if (userStroke.length < 40) return false;
    
    final padding = canvasSize.width * 0.1;
    final drawSize = canvasSize.width - (padding * 2);
    final scale = drawSize / 1024;
    
    // Convert median points
    final medianPoints = combinedMedians.map((median) => Offset(
      median[0] * scale + padding,
      (1024 - median[1]) * scale + padding,
    )).toList();
    
    if (medianPoints.length < 10) return false;
    
    // For 子, the combined stroke should have a clear horizontal then vertical pattern
    // Check that the stroke has the characteristic shape
    
    // Find the turning point (should be where horizontal meets vertical)
    double maxX = -double.infinity;
    int turningIndex = -1;
    
    for (int i = 0; i < userStroke.length ~/ 2; i++) {
      if (userStroke[i].dx > maxX) {
        maxX = userStroke[i].dx;
        turningIndex = i;
      }
    }
    
    if (turningIndex < 5 || turningIndex > userStroke.length - 5) {
      return false; // No clear turning point
    }
    
    // Check that first part is mostly horizontal
    final firstPart = userStroke.sublist(0, turningIndex);
    double totalDx = 0, totalDy = 0;
    
    for (int i = 1; i < firstPart.length; i++) {
      totalDx += (firstPart[i].dx - firstPart[i-1].dx).abs();
      totalDy += (firstPart[i].dy - firstPart[i-1].dy).abs();
    }
    
    // First part should be more horizontal than vertical
    if (totalDy > totalDx * 0.5) {
      return false;
    }
    
    // Check that second part is mostly vertical
    final secondPart = userStroke.sublist(turningIndex);
    totalDx = 0;
    totalDy = 0;
    
    for (int i = 1; i < secondPart.length; i++) {
      totalDx += (secondPart[i].dx - secondPart[i-1].dx).abs();
      totalDy += (secondPart[i].dy - secondPart[i-1].dy).abs();
    }
    
    // Second part should be more vertical than horizontal
    if (totalDx > totalDy * 0.7) {
      return false;
    }
    
    // Check that stroke actually covers both parts
    final firstStrokeEnd = medianPoints.length ~/ 2;
    final firstStrokeCoverage = _checkCoverage(userStroke, medianPoints.sublist(0, firstStrokeEnd), canvasSize);
    final secondStrokeCoverage = _checkCoverage(userStroke, medianPoints.sublist(firstStrokeEnd), canvasSize);
    
    // Both strokes must have good coverage
    if (firstStrokeCoverage < 0.6 || secondStrokeCoverage < 0.6) {
      return false;
    }
    
    // Check overall coverage with strict tolerance
    final tolerance = canvasSize.width * 0.08;
    int matched = 0;
    
    for (final medianPoint in medianPoints) {
      for (final userPoint in userStroke) {
        if ((userPoint - medianPoint).distance < tolerance) {
          matched++;
          break;
        }
      }
    }
    
    // Require very high coverage
    return matched >= medianPoints.length * 0.85;
  }
  
  static double _checkCoverage(List<Offset> userStroke, List<Offset> targetPoints, Size canvasSize) {
    if (targetPoints.isEmpty) return 0;
    
    final tolerance = canvasSize.width * 0.1;
    int matched = 0;
    
    for (final targetPoint in targetPoints) {
      for (final userPoint in userStroke) {
        if ((userPoint - targetPoint).distance < tolerance) {
          matched++;
          break;
        }
      }
    }
    
    return matched / targetPoints.length;
  }
}

class CombinationRule {
  final String character;
  final List<int> combinableStrokes;
  final String description;
  final bool ignoreDirection;
  
  CombinationRule({
    required this.character,
    required this.combinableStrokes,
    required this.description,
    this.ignoreDirection = false,
  });
}

class CombinedStrokeMatch {
  final List<int> matchedStrokes;
  final double confidence;
  
  CombinedStrokeMatch({
    required this.matchedStrokes,
    required this.confidence,
  });
}