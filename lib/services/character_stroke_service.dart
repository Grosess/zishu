import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'placeholder_characters.dart';

class CharacterStroke {
  final String character;
  final List<String> strokes; // SVG path data for each stroke
  final List<List<List<double>>> medians; // Median points for stroke matching
  
  CharacterStroke({
    required this.character,
    required this.strokes,
    required this.medians,
  });
  
  factory CharacterStroke.fromJson(Map<String, dynamic> json) {
    // Parse strokes
    final strokesList = List<String>.from(json['strokes'] ?? []);
    
    // Parse medians - handle nested arrays properly
    final mediansList = <List<List<double>>>[];
    if (json['medians'] != null) {
      for (final median in json['medians']) {
        final strokeMedian = <List<double>>[];
        for (final point in median) {
          strokeMedian.add([
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble()
          ]);
        }
        mediansList.add(strokeMedian);
      }
    }
    
    return CharacterStroke(
      character: json['character'] ?? '',
      strokes: strokesList,
      medians: mediansList,
    );
  }
  
  factory CharacterStroke.fromDatabaseFormat(Map<String, dynamic> data) {
    final strokesList = List<String>.from(data['strokes'] ?? []);
    
    // Parse medians - handle nested arrays properly
    final mediansList = <List<List<double>>>[];
    if (data['medians'] != null) {
      for (final median in data['medians']) {
        final strokeMedian = <List<double>>[];
        for (final point in median) {
          strokeMedian.add([
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble()
          ]);
        }
        mediansList.add(strokeMedian);
      }
    }
    
    return CharacterStroke(
      character: data['character'] ?? '',
      strokes: strokesList,
      medians: mediansList,
    );
  }
}

class CharacterStrokeService {
  static final CharacterStrokeService _instance = CharacterStrokeService._internal();
  factory CharacterStrokeService() => _instance;
  CharacterStrokeService._internal() {
    _instanceId = DateTime.now().millisecondsSinceEpoch;
  }
  
  late final int _instanceId;
  final Map<String, CharacterStroke> _strokeData = {};
  bool _loaded = false;
  
  // Load character data from JSON file
  Future<void> loadSampleData() async {
    if (_loaded) return;
    
    // Load sample data
    
    try {
      // Try extended data first, then fall back to basic data
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/character_data_extended.json');
      } catch (e) {
        jsonString = await rootBundle.loadString('assets/character_data.json');
      }
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> characters = jsonData['characters'];
      
      // Parse each character
      for (final item in characters) {
        final stroke = CharacterStroke.fromJson(item);
        _strokeData[stroke.character] = stroke;
        // Loaded sample character
      }
      
      _loaded = true;
      // Sample characters loaded
    } catch (e) {
      // Error loading character data - will be handled by caller
      // Fallback to hardcoded data
      await _loadHardcodedData();
    }
  }
  
  // Fallback hardcoded data - using actual characters from the sample database
  Future<void> _loadHardcodedData() async {
    final sampleData = [
      {
        "character": "⺀",
        "strokes": [
          "M 323 706 Q 325 699 328 694 Q 334 686 367 671 Q 474 619 574 561 Q 600 545 617 543 Q 627 545 631 559 Q 641 576 613 621 Q 575 684 334 717 Q 321 719 323 706 Z",
          "M 312 541 Q 314 535 316 531 Q 320 524 347 512 Q 455 461 563 397 Q 588 380 606 380 Q 615 382 619 396 Q 629 414 602 457 Q 564 519 321 554 Q 320 555 319 555 Q 310 555 312 541 Z"
        ],
        "medians": [
          [[336, 704], [450, 666], [554, 620], [587, 595], [614, 558]],
          [[317, 548], [347, 531], [455, 496], [543, 456], [578, 430], [602, 395]]
        ]
      },
      {
        "character": "⺈",
        "strokes": [
          "M 441 666 Q 490 726 523 749 Q 525 750 526 751 Q 547 768 509 808 Q 486 830 469 833 Q 451 834 456 811 Q 461 792 441 757 Q 396 672 248 545 Q 232 535 232 528 Q 233 521 242 521 Q 288 521 423 651 L 441 666 Z",
          "M 527 467 L 604 554 Q 653 615 705 653 Q 723 664 710 678 Q 696 692 655 714 Q 647 717 596 703 Q 454 668 441 666 C 412 660 408 659 423 651 Q 427 647 433 645 Q 457 637 541 651 Q 596 661 600 657 Q 604 653 598 639 Q 568 583 496 462 Q 521 466 527 467 Z"
        ],
        "medians": [
          [[468, 819], [490, 772], [428, 689], [320, 583], [274, 547], [240, 529]],
          [[430, 652], [527, 665], [588, 681], [614, 681], [646, 664], [631, 632], [540, 504], [520, 478], [505, 469]]
        ]
      },
      {
        "character": "⺊",
        "strokes": [
          "M 519 53 Q 517 149 517 156 L 529 400 L 530 439 Q 531 469 533 518 Q 546 730 559 778 Q 563 793 539 808 Q 508 829 464 837 Q 445 841 433 830 Q 429 825 429 821 Q 428 812 443 790 Q 465 757 466 733 Q 470 664 470 600 L 465 397 Q 461 363 457 296 Q 455 262 443 216 Q 439 171 439 129 Q 437 25 447 -3 Q 462 -58 490 -75 Q 498 -76 502 -71 Q 517 -56 519 53 Z",
          "M 529 400 Q 570 394 663 410 Q 784 435 791 441 Q 797 447 798 453 Q 798 470 753 483 Q 725 489 622 457 L 530 439 C 501 433 499 403 529 400 Z"
        ],
        "medians": [
          [[444, 820], [486, 793], [502, 777], [508, 758], [497, 394], [477, 117], [481, 11], [492, -62]],
          [[535, 406], [556, 421], [630, 431], [712, 451], [755, 457], [784, 453]]
        ]
      }
    ];
    
    for (final item in sampleData) {
      final stroke = CharacterStroke.fromJson(item);
      _strokeData[stroke.character] = stroke;
    }
    
    _loaded = true;
  }
  
  // Load from graphics.txt file (for production)
  Future<void> loadFromFile(String path) async {
    try {
      final String content = await rootBundle.loadString(path);
      final lines = content.split('\n');
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          final stroke = CharacterStroke.fromJson(json);
          _strokeData[stroke.character] = stroke;
        } catch (e) {
          // Production: removed debug print
        }
      }
      
      _loaded = true;
    } catch (e) {
      // Production: removed debug print
    }
  }
  
  CharacterStroke? getCharacterStroke(String character) {
    // Looking for character
    // Production: removed debug print
    // Checking stroke data
    
    // Check if we have the character in our loaded data
    if (_strokeData.containsKey(character)) {
      final stroke = _strokeData[character]!;
      // Production: removed debug print
      // Debug output for problematic characters
      if (character == '出') {
        // Production: removed debug print
        for (int i = 0; i < stroke.strokes.length; i++) {
          // Stroke details
        }
        // Validated stroke commands
      }
      return stroke;
    }
    
    // Production: removed debug print
    // Production: removed debug print
    for (final key in _strokeData.keys.take(5)) {
      // Checking key match
    }
    
    // Try to get from placeholders as fallback
    final placeholderData = PlaceholderCharacters.getPlaceholder(character);
    if (placeholderData != null) {
      // Production: removed debug print
      // Add to stroke data so it's cached
      _strokeData[character] = placeholderData;
      return placeholderData;
    }
    
    // Production: removed debug print
    return null;
  }
  
  bool hasCharacter(String character) {
    return _strokeData.containsKey(character);
  }
  
  List<String> get availableCharacters => _strokeData.keys.toList();
  
  // Add a character stroke dynamically
  void addCharacterStroke(CharacterStroke stroke) {
    if (_strokeData.containsKey(stroke.character)) {
      // Check if existing data is from placeholder and new data is from database
      final existingStroke = _strokeData[stroke.character]!;
      final isExistingPlaceholder = PlaceholderCharacters.hasPlaceholder(stroke.character) &&
          _isPlaceholderData(existingStroke, stroke.character);
      
      // Always prefer database data over placeholder data
      if (isExistingPlaceholder || !_isPlaceholderData(stroke, stroke.character)) {
        _strokeData[stroke.character] = stroke;
      }
    } else {
      _strokeData[stroke.character] = stroke;
    }
  }
  
  // Helper method to check if stroke data matches placeholder data
  bool _isPlaceholderData(CharacterStroke stroke, String character) {
    final placeholder = PlaceholderCharacters.getPlaceholder(character);
    if (placeholder == null) return false;
    
    // Compare stroke counts and first stroke path to determine if it's placeholder data
    return stroke.strokes.length == placeholder.strokes.length &&
           stroke.strokes.isNotEmpty &&
           stroke.strokes.first == placeholder.strokes.first;
  }
  
  // Add multiple character strokes
  void addCharacterStrokes(List<CharacterStroke> strokes) {
    for (final stroke in strokes) {
      _strokeData[stroke.character] = stroke;
    }
  }
  
  // Clear all loaded data
  void clearData() {
    // Production: removed debug print
    // Production: removed debug print
    // Clearing characters
    _strokeData.clear();
    _loaded = false;
    // Clear the SVG path cache to prevent stale data
    SvgPathConverter.clearCache();
    // Production: removed debug print
  }
  
  // Clear specific character data
  void clearCharacter(String character) {
    if (_strokeData.containsKey(character)) {
      // Production: removed debug print
      _strokeData.remove(character);
    }
  }
  
  // Clear multiple characters
  void clearCharacters(List<String> characters) {
    for (final character in characters) {
      _strokeData.remove(character);
    }
    // Clear path cache to ensure fresh rendering
    SvgPathConverter.clearCache();
  }
  
  // Force refresh characters that might have placeholder data
  void refreshPlaceholderCharacters() {
    final charactersToRefresh = <String>[];
    
    // Check all loaded characters to see if they match placeholder data
    for (final entry in _strokeData.entries) {
      if (_isPlaceholderData(entry.value, entry.key)) {
        charactersToRefresh.add(entry.key);
      }
    }
    
    // Clear placeholder characters so they can be reloaded from database
    for (final character in charactersToRefresh) {
      _strokeData.remove(character);
    }
    
    // Clear the SVG path cache to ensure fresh rendering
    SvgPathConverter.clearCache();
  }
  
  // Check if data is loaded
  bool get isLoaded => _loaded;
}

// Stroke matching utilities
class StrokeValidator {
  static bool validateStroke(
    List<Offset> userStroke,
    List<List<double>> medianPoints,
    Size canvasSize,
    {double tolerance = 0.45, bool isMultiDirectional = false}  // Strict tolerance
  ) {
    print('\n\n=== STROKE VALIDATION START ===');
    print('Canvas size: $canvasSize');
    print('Base tolerance: $tolerance');
    print('Is multi-directional: $isMultiDirectional');
    
    if (userStroke.length < 2 || medianPoints.length < 2) {
      print('FAILED: Too few points - user: ${userStroke.length}, median: ${medianPoints.length}');
      return false;
    }
    
    // Check stroke size first
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    for (final point in userStroke) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    
    final strokeWidth = maxX - minX;
    final strokeHeight = maxY - minY;
    final minSize = canvasSize.width * 0.005; // 0.5% of canvas - extremely lenient for small strokes
    
    print('\nStroke bounds:');
    print('  Width: $strokeWidth, Height: $strokeHeight');
    print('  Min size threshold: $minSize');
    
    // Reject strokes that are too small in both dimensions
    if (strokeWidth < minSize && strokeHeight < minSize) {
      print('FAILED: Stroke too small in both dimensions');
      return false;
    }
    
    // Also reject if stroke has very few points (likely accidental tap)
    if (userStroke.length < 2) {
      print('FAILED: Too few stroke points');
      return false;
    }
    
    // Account for padding when normalizing (same as in parsePath)
    // Avoid excessive rounding to prevent distortion on real devices
    final padding = canvasSize.width * 0.1;
    final drawSize = canvasSize.width - (padding * 2);
    
    // For validation, we can't check the SVG path, but we can assume simpler scaling
    // This should match the most common case from parsePath
    final scale = drawSize / 1024.0 * 1.03;
    final scaledSize = 1024 * scale;
    final offsetX = (canvasSize.width - scaledSize) / 2;
    // Match parsePath's offset calculation with upward adjustment
    final offsetY = (canvasSize.height - scaledSize) / 2 - (canvasSize.height * 0.07);
    
    print('\nCoordinate transformation:');
    print('  Padding: $padding');
    print('  Draw size: $drawSize');
    print('  Scale: $scale');
    print('  Scaled size: $scaledSize');
    print('  Offset X: $offsetX');
    print('  Offset Y: $offsetY');
    
    // Normalize coordinates (accounting for the centered position)
    final normalizedUser = userStroke.map((p) => Offset(
      (p.dx - offsetX) / scaledSize,
      (p.dy - offsetY) / scaledSize,
    )).toList();
    
    // Flip Y coordinate for median points too
    final normalizedMedian = medianPoints.map((p) => 
      Offset(p[0] / 1024, (1024 - p[1]) / 1024) // Flip Y coordinate without clamping
    ).toList();
    
    print('\nFirst normalized points:');
    print('  User first: ${normalizedUser.first}');
    print('  User last: ${normalizedUser.last}');
    print('  Median first: ${normalizedMedian.first}');
    print('  Median last: ${normalizedMedian.last}');
    
    // Calculate stroke lengths for comparison
    double userLength = 0;
    for (int i = 1; i < normalizedUser.length; i++) {
      userLength += (normalizedUser[i] - normalizedUser[i-1]).distance;
    }
    
    double medianLength = 0;
    for (int i = 1; i < normalizedMedian.length; i++) {
      medianLength += (normalizedMedian[i] - normalizedMedian[i-1]).distance;
    }
    
    // Check if this is a long vertical stroke first
    final medianDirection = normalizedMedian.last - normalizedMedian.first;
    final isLongVertical = medianDirection.dy.abs() > medianDirection.dx.abs() * 1.5 && 
                          medianLength > 0.3; // Long vertical stroke (more lenient)
    
    // Check if stroke length is reasonable - EXTREMELY lenient
    final isSmallStroke = medianLength < 0.15; // Small stroke in normalized space
    final minRatio = 0.3; // Can be 70% shorter
    final maxRatio = 3.0; // Can be 3x longer
    
    final lengthRatio = userLength / medianLength;
    
    print('Length check: ratio=$lengthRatio, min=$minRatio, max=$maxRatio');
    
    if (lengthRatio < minRatio || lengthRatio > maxRatio) {
      print('FAILED: Stroke length ratio $lengthRatio out of range [$minRatio, $maxRatio]');
      return false; // Stroke is too short or too long
    }
    
    // Location tolerance - stricter for non-multidirectional strokes
    final strokeSize = math.max(strokeWidth, strokeHeight) / canvasSize.width;
    final sizeFactor = strokeSize > 0.3 ? 1.6 : 1.5;
    
    // Check if this is a diagonal stroke (reuse medianDirection from above)
    final isDiagonalStroke = (medianDirection.dx.abs() > medianDirection.distance * 0.3 && 
                             medianDirection.dy.abs() > medianDirection.distance * 0.3);
    
    // Location tolerance - stricter for better position accuracy
    final locationTolerance = tolerance * 0.6;  // 60% of base tolerance for all strokes
    
    // Check key points with appropriate tolerance
    final startDist = (normalizedUser.first - normalizedMedian.first).distance;
    final endDist = (normalizedUser.last - normalizedMedian.last).distance;
    
    // Stricter tolerance for start/end points location
    final pointTolerance = 1.0;  // Stricter for better location accuracy
    
    print('Location check: startDist=$startDist, endDist=$endDist, maxAllowed=${locationTolerance * pointTolerance}');
    
    if (startDist > locationTolerance * pointTolerance || endDist > locationTolerance * pointTolerance) {
      print('FAILED: Start/end points too far - start: $startDist, end: $endDist, max allowed: ${locationTolerance * pointTolerance}');
      return false;
    }
    
    // Direction validation - strict
    final directionTolerance = tolerance * 0.6;  // 60% of base tolerance for all strokes
    
    print('\nCalling direction validation:');
    print('  Direction tolerance: $directionTolerance');
    print('  Is small stroke: $isSmallStroke');
    
    if (!_validateStrokeDirection(normalizedUser, normalizedMedian, directionTolerance, isMultiDirectional)) {
      print('FAILED: Direction validation failed');
      return false;
    }
    print('Direction validation passed');
    
    // Check general path with stricter tolerance
    if (normalizedUser.length > 10 && normalizedMedian.length > 2) {
      // Sample more points along the path for better accuracy
      int matchedPoints = 0;
      int totalChecks = 0;
      
      for (int i = 0; i < 5; i++) { // Check 5 points along the path
        final progress = (i + 1) / 6.0;
        final userIndex = (normalizedUser.length * progress).round().clamp(0, normalizedUser.length - 1);
        final medianIndex = (normalizedMedian.length * progress).round().clamp(0, normalizedMedian.length - 1);
        
        final dist = (normalizedUser[userIndex] - normalizedMedian[medianIndex]).distance;
        totalChecks++;
        
        // Count how many points are within tolerance - stricter for non-multidirectional
        final pathTolerance = isMultiDirectional ? locationTolerance * sizeFactor * 1.5 : locationTolerance * sizeFactor;
        if (dist <= pathTolerance) {
          matchedPoints++;
        }
      }
      
      // Slightly stricter shape matching requirements
      final requiredMatch = 0.75; // Need 75% of points to match
      print('Path match: $matchedPoints/$totalChecks points within tolerance (${(matchedPoints.toDouble()/totalChecks*100).toStringAsFixed(1)}%), required: ${(requiredMatch*100).toStringAsFixed(0)}%');
      if (matchedPoints < totalChecks * requiredMatch) {
        print('FAILED: Not enough matched points in path check');
        return false;
      }
    }
    
    print('\n=== STROKE VALIDATION COMPLETE: PASSED ===\n');
    return true;
  }
  
  // Validate stroke direction by checking the sequence of points
  static bool _validateStrokeDirection(
    List<Offset> userStroke,
    List<Offset> medianPoints,
    double tolerance,
    bool isMultiDirectional,
  ) {
    if (userStroke.length < 3 || medianPoints.length < 2) return true;
    
    print('\n=== STROKE DIRECTION VALIDATION DEBUG ===');
    print('User stroke points: ${userStroke.length}');
    print('Median points: ${medianPoints.length}');
    print('Tolerance: $tolerance');
    print('isMultiDirectional: $isMultiDirectional');
    
    // If not already marked as multi-directional, check if this stroke has curves
    bool actuallyMultiDirectional = isMultiDirectional;
    if (!actuallyMultiDirectional && medianPoints.length >= 3) {
      // Check for significant direction changes in the median
      for (int i = 1; i < medianPoints.length - 1; i++) {
        final dir1 = medianPoints[i] - medianPoints[i - 1];
        final dir2 = medianPoints[i + 1] - medianPoints[i];
        if (dir1.distance > 0 && dir2.distance > 0) {
          final dot = (dir1.dx * dir2.dx + dir1.dy * dir2.dy) / (dir1.distance * dir2.distance);
          // Only consider it multi-directional for sharp turns (> 90 degrees)
          // This prevents diagonal strokes from being misclassified
          if (dot < 0.0) { // Significant direction change (> 90 degrees)
            actuallyMultiDirectional = true;
            print('Detected as multi-directional at segment $i, dot product: $dot');
            break;
          }
        }
      }
    }
    
    // Calculate overall direction vectors
    final medianDirection = medianPoints.last - medianPoints.first;
    final userDirection = userStroke.last - userStroke.first;
    
    print('\nMedian stroke:');
    print('  Start: ${medianPoints.first}');
    print('  End: ${medianPoints.last}');
    print('  Direction vector: $medianDirection');
    print('  Length: ${medianDirection.distance}');
    
    print('\nUser stroke:');
    print('  Start: ${userStroke.first}');
    print('  End: ${userStroke.last}');
    print('  Direction vector: $userDirection');
    print('  Length: ${userDirection.distance}');
    
    // For diagonal strokes, use vector angle comparison instead of separate X/Y checks
    if (medianDirection.distance > 0 && userDirection.distance > 0) {
      // Normalize the direction vectors
      final normalizedMedian = medianDirection / medianDirection.distance;
      final normalizedUser = userDirection / userDirection.distance;
      
      print('\nNormalized directions:');
      print('  Median: $normalizedMedian');
      print('  User: $normalizedUser');
      
      // Calculate dot product (cosine of angle between vectors)
      final dotProduct = normalizedMedian.dx * normalizedUser.dx + 
                        normalizedMedian.dy * normalizedUser.dy;
      
      print('\nDot product: $dotProduct');
      
      // For diagonal strokes (pie strokes), we need to be more lenient
      // Check if this is a diagonal stroke
      final isDiagonal = (medianDirection.dx.abs() > medianDirection.distance * 0.3 && 
                         medianDirection.dy.abs() > medianDirection.distance * 0.3);
      
      print('Is diagonal stroke: $isDiagonal');
      print('  X component ratio: ${medianDirection.dx.abs() / medianDirection.distance}');
      print('  Y component ratio: ${medianDirection.dy.abs() / medianDirection.distance}');
      
      // Check if stroke is going in wrong direction
      if (dotProduct < 0) {
        print('FAILED: Stroke is going in opposite direction (dot product < 0)');
        return false; // Stroke is going in opposite direction
      }
      
      // Allow up to 75 degrees deviation for diagonal strokes, 45 degrees for others
      final minDotProduct = isDiagonal ? 0.259 : 0.707; // cos(75°) vs cos(45°)
      
      print('Required min dot product: $minDotProduct (${isDiagonal ? "diagonal" : "straight"})');
      
      if (dotProduct < minDotProduct) {
        print('FAILED: Direction is too far off (dot product $dotProduct < $minDotProduct)');
        return false; // Direction is too far off
      }
      
      print('Direction validation PASSED');
    }
    
    // For multi-directional strokes, we need STRICT path checking
    if (actuallyMultiDirectional) {
      // First verify that the median stroke actually has a significant curve/hook
      if (medianPoints.length >= 3) {
        // Check the expected curve in the median
        final medianStart = medianPoints.first;
        final medianMid = medianPoints[medianPoints.length ~/ 2];
        final medianEnd = medianPoints.last;
        
        // Calculate if the median has a curve by checking if middle point deviates from straight line
        final straightLine = medianEnd - medianStart;
        final toMidpoint = medianMid - medianStart;
        
        // Project midpoint onto the straight line
        double t = 0;
        if (straightLine.distance > 0) {
          t = (toMidpoint.dx * straightLine.dx + toMidpoint.dy * straightLine.dy) / 
              (straightLine.distance * straightLine.distance);
          t = t.clamp(0.0, 1.0);
        }
        
        final projectedPoint = medianStart + straightLine * t;
        final deviation = (medianMid - projectedPoint).distance;
        
        // If median doesn't have significant curve, this isn't really multidirectional
        if (deviation < 0.05) {
          actuallyMultiDirectional = false;
        }
      }
      
      // Check that the stroke actually follows the curve/hook pattern
      if (actuallyMultiDirectional && medianPoints.length >= 3 && userStroke.length >= 10) {
        // Sample fewer points along the stroke to ensure it follows the curve
        final numCheckPoints = 3;
        for (int i = 0; i < numCheckPoints; i++) {
          final progress = i / (numCheckPoints - 1);
          final medianIdx = (progress * (medianPoints.length - 1)).round();
          final userIdx = (progress * (userStroke.length - 1)).round();
          
          if (medianIdx < medianPoints.length && userIdx < userStroke.length) {
            // Check that user stroke point is near the corresponding median point
            final dist = (userStroke[userIdx] - medianPoints[medianIdx]).distance;
            if (dist > tolerance * 0.8) { // More lenient distance check for curve following
              return false;
            }
          }
        }
        
        // Check for required direction changes in user stroke
        // For strokes like 与's second stroke, we need to detect the hook at the end
        bool userHasDirectionChange = false;
        double maxAngleChange = 0.0;
        
        // Check the overall path curvature
        final startToMid = userStroke[userStroke.length ~/ 2] - userStroke.first;
        final midToEnd = userStroke.last - userStroke[userStroke.length ~/ 2];
        
        if (startToMid.distance > 0.01 && midToEnd.distance > 0.01) {
          // Normalize vectors
          final normStartToMid = startToMid / startToMid.distance;
          final normMidToEnd = midToEnd / midToEnd.distance;
          
          // Calculate angle change
          final dot = normStartToMid.dx * normMidToEnd.dx + normStartToMid.dy * normMidToEnd.dy;
          maxAngleChange = 1.0 - dot; // Convert to angle measure
          
          // For hooks and curves, we need significant angle change
          if (maxAngleChange > 0.3) { // About 35 degrees minimum
            userHasDirectionChange = true;
          }
        }
        
        // Also check for hooks specifically (sharp turns near the end)
        if (!userHasDirectionChange && userStroke.length >= 10) {
          final lastQuarter = userStroke.length * 3 ~/ 4;
          final beforeHook = userStroke[lastQuarter] - userStroke[lastQuarter - 2];
          final afterHook = userStroke.last - userStroke[lastQuarter];
          
          if (beforeHook.distance > 0.01 && afterHook.distance > 0.01) {
            final hookDot = (beforeHook.dx * afterHook.dx + beforeHook.dy * afterHook.dy) / 
                           (beforeHook.distance * afterHook.distance);
            if (hookDot < 0.7) { // Detect hook at end
              userHasDirectionChange = true;
            }
          }
        }
        
        // Special check for strokes like 与's second stroke - vertical with hook
        // Check if this is primarily a vertical stroke that should have a horizontal hook
        if (!userHasDirectionChange) {
          final overallDir = userStroke.last - userStroke.first;
          final isPrimarilyVertical = overallDir.dy.abs() > overallDir.dx.abs() * 2;
          
          if (isPrimarilyVertical && medianPoints.length >= 3) {
            // Check if median has a horizontal component at the end
            final medianEndDir = medianPoints.last - medianPoints[medianPoints.length - 2];
            final hasHorizontalEnd = medianEndDir.dx.abs() > medianEndDir.dy.abs() * 0.5;
            
            if (hasHorizontalEnd) {
              // User stroke must also have horizontal component at end
              final userEndDir = userStroke.last - userStroke[userStroke.length - 3];
              final userHasHorizontalEnd = userEndDir.dx.abs() > userEndDir.dy.abs() * 0.3;
              
              if (!userHasHorizontalEnd) {
                return false; // Straight down stroke when hook is required
              }
            }
          }
        }
        
        if (!userHasDirectionChange) {
          // User drew a straight line instead of a curve/hook
          print('FAILED: Multi-directional stroke requires direction change, but user stroke is straight');
          return false;
        }
      }
      
      // Continue with existing endpoint checks
      final startDist = (userStroke.first - medianPoints.first).distance;
      final endDist = (userStroke.last - medianPoints.last).distance;
      
      if (startDist > 0.45 || endDist > 0.45) {
        return false;
      }
      
      return true;
    }
    
    return true;
  }
  
  // Find the index of the closest point in the user stroke to a median point
  static int _findClosestPointIndex(Offset target, List<Offset> points) {
    if (points.isEmpty) return -1;
    
    double minDist = double.infinity;
    int minIndex = -1;
    
    for (int i = 0; i < points.length; i++) {
      final dist = (points[i] - target).distance;
      if (dist < minDist) {
        minDist = dist;
        minIndex = i;
      }
    }
    
    return minDist < 0.45 ? minIndex : -1; // More lenient location matching
  }
  
  static List<Offset> _normalizePoints(List<Offset> points, Size canvasSize) {
    return points.map((p) => Offset(
      p.dx / canvasSize.width,
      p.dy / canvasSize.height,
    )).toList();
  }
}

// SVG path parser
class SvgPathConverter {
  // Cache for parsed paths to avoid repeated parsing and numerical errors
  static final Map<String, Path> _pathCache = {};
  static const int _maxCacheSize = 100;
  
  static Path parsePath(String svgPath, Size targetSize) {
    // Create cache key from path length and first/last commands to avoid hash collisions
    final pathStart = svgPath.length > 50 ? svgPath.substring(0, 50) : svgPath;
    final pathEnd = svgPath.length > 50 ? svgPath.substring(svgPath.length - 50) : '';
    final cacheKey = '${svgPath.length}_${pathStart.hashCode}_${pathEnd.hashCode}_${targetSize.width.toStringAsFixed(2)}_${targetSize.height.toStringAsFixed(2)}';
    
    // Check cache first
    if (_pathCache.containsKey(cacheKey)) {
      // Return a copy of the cached path to avoid mutations
      final cachedPath = _pathCache[cacheKey]!;
      final pathCopy = Path();
      pathCopy.addPath(cachedPath, Offset.zero);
      return pathCopy;
    }
    final path = Path();
    final commands = _tokenize(svgPath);
    
    double currentX = 0;
    double currentY = 0;
    
    // MakeMeAHanzi uses 1024x1024, scale to fit target with padding
    // Avoid excessive rounding to prevent distortion on real devices
    final padding = targetSize.width * 0.1; // Increased padding to accommodate overflow
    final drawSize = targetSize.width - (padding * 2);
    
    // Check if this might be a complex enclosed character (like 国, 圆, etc)
    // by looking for multiple Z (close path) commands which indicate multiple strokes
    final closeCount = svgPath.split('Z').length - 1;
    final isComplexCharacter = closeCount > 3;
    
    // Use slightly larger scale for better visibility
    final scaleFactor = isComplexCharacter ? 1.0 : 1.03;
    final scale = drawSize / 1024.0 * scaleFactor;
    
    // Center the character properly with slight upward adjustment
    // Use direct calculations without premature rounding
    final scaledSize = 1024 * scale;
    final offsetX = (targetSize.width - scaledSize) / 2; // Center horizontally
    // Move up by 7% for better visual balance while still accommodating negative Y
    final offsetY = (targetSize.height - scaledSize) / 2 - (targetSize.height * 0.07);
    
    // Validate offsets to prevent rendering issues
    if (offsetX.isNaN || offsetY.isNaN || offsetX.isInfinite || offsetY.isInfinite) {
      // Return empty path if calculations are invalid
      return Path();
    }
    
    // Debug logging disabled for production
    
    // Y-axis needs to be flipped (1024 - y) because SVG origin is top-left
    // but MakeMeAHanzi coordinates seem to be bottom-left
    
    // Helper function to flip Y coordinate
    // Don't clamp - let the rendering handle coordinates outside bounds
    double flipY(double y) {
      return 1024.0 - y;
    }
    
    for (int i = 0; i < commands.length; i++) {
      switch (commands[i]) {
        case 'M': // Move to
          if (i + 2 < commands.length) {
            final x = double.parse(commands[++i]);
            final y = double.parse(commands[++i]);
            currentX = x * scale + offsetX;
            // Flip Y coordinate
            currentY = flipY(y) * scale + offsetY;
            path.moveTo(currentX, currentY);
          }
          break;
          
        case 'L': // Line to
          if (i + 2 < commands.length) {
            final x = double.parse(commands[++i]);
            final y = double.parse(commands[++i]);
            currentX = x * scale + offsetX;
            // Flip Y coordinate
            currentY = flipY(y) * scale + offsetY;
            path.lineTo(currentX, currentY);
          }
          break;
          
        case 'Q': // Quadratic bezier
          if (i + 4 < commands.length) {
            final cx1 = double.parse(commands[++i]);
            final cy1 = double.parse(commands[++i]);
            final cx = cx1 * scale + offsetX;
            // Flip Y coordinate for control point
            final cy = flipY(cy1) * scale + offsetY;
            
            final x = double.parse(commands[++i]);
            final y = double.parse(commands[++i]);
            currentX = x * scale + offsetX;
            // Flip Y coordinate for end point
            currentY = flipY(y) * scale + offsetY;
            path.quadraticBezierTo(cx, cy, currentX, currentY);
          }
          break;
          
        case 'C': // Cubic bezier (or continuation marker in this data)
          // Check how many numeric parameters follow
          int numCount = 0;
          for (int j = i + 1; j < commands.length && !RegExp(r'[A-Z]').hasMatch(commands[j]); j++) {
            numCount++;
          }
          
          if (numCount == 6 && i + 6 < commands.length) {
            // Standard cubic bezier: C x1 y1 x2 y2 x y
            final cx1 = double.parse(commands[++i]) * scale + offsetX;
            final cy1 = flipY(double.parse(commands[++i])) * scale + offsetY;
            final cx2 = double.parse(commands[++i]) * scale + offsetX;
            final cy2 = flipY(double.parse(commands[++i])) * scale + offsetY;
            currentX = double.parse(commands[++i]) * scale + offsetX;
            currentY = flipY(double.parse(commands[++i])) * scale + offsetY;
            path.cubicTo(cx1, cy1, cx2, cy2, currentX, currentY);
          } else if (numCount >= 2) {
            // Sometimes C is used as a line continuation
            // Just draw a line to the next point
            currentX = double.parse(commands[++i]) * scale + offsetX;
            currentY = flipY(double.parse(commands[++i])) * scale + offsetY;
            path.lineTo(currentX, currentY);
            
            // Skip any remaining coordinates
            for (int j = 2; j < numCount; j++) {
              i++;
            }
          }
          break;
          
        case 'Z': // Close path
          path.close();
          break;
      }
    }
    
    // Cache the path before returning
    _pathCache[cacheKey] = path;
    
    // Implement LRU eviction with proper ordering
    if (_pathCache.length > _maxCacheSize) {
      // Since Dart's Map maintains insertion order, we need to track access order separately
      // For now, just remove the first entry (oldest insertion)
      final firstKey = _pathCache.keys.first;
      _pathCache.remove(firstKey);
    }
    
    // Return a copy to avoid mutations
    final pathCopy = Path();
    pathCopy.addPath(path, Offset.zero);
    return pathCopy;
  }
  
  // Clear the cache when needed (e.g., when switching databases)
  static void clearCache() {
    _pathCache.clear();
  }
  
  // Clear cache entries for paths matching a pattern
  static void clearCacheForPaths(String pathPattern) {
    final keysToRemove = <String>[];
    for (final key in _pathCache.keys) {
      if (key.contains(pathPattern)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _pathCache.remove(key);
    }
  }
  
  static List<String> _tokenize(String svgPath) {
    final tokens = <String>[];
    final regex = RegExp(r'([MLHVCSQTAZ])|(-?\d*\.?\d+)');
    
    for (final match in regex.allMatches(svgPath)) {
      tokens.add(match.group(0)!);
    }
    
    return tokens;
  }
}