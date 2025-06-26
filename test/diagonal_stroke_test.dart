import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zishu/services/character_stroke_service.dart';

void main() {
  test('Diagonal stroke validation', () {
    // Test diagonal stroke (pie stroke) going from top-right to bottom-left
    // Like the second stroke of 不
    // User stroke in canvas coordinates (with padding adjustment)
    final padding = 100.0 * 0.1; // 10% padding
    final drawSize = 100.0 - (padding * 2);
    final scale = drawSize / 1024.0 * 1.03;
    final scaledSize = 1024 * scale;
    final offsetX = (100.0 - scaledSize) / 2;
    final offsetY = (100.0 - scaledSize) / 2 - (100.0 * 0.07);
    
    // Create user stroke that matches the expected coordinate system
    final userStroke = [
      Offset(700 * scale + offsetX, (1024 - 300) * scale + offsetY),  // Top-right
      Offset(650 * scale + offsetX, (1024 - 350) * scale + offsetY),
      Offset(600 * scale + offsetX, (1024 - 400) * scale + offsetY),
      Offset(550 * scale + offsetX, (1024 - 450) * scale + offsetY),
      Offset(500 * scale + offsetX, (1024 - 500) * scale + offsetY),
      Offset(450 * scale + offsetX, (1024 - 550) * scale + offsetY),
      Offset(400 * scale + offsetX, (1024 - 600) * scale + offsetY),
      Offset(350 * scale + offsetX, (1024 - 650) * scale + offsetY),
      Offset(300 * scale + offsetX, (1024 - 700) * scale + offsetY),  // Bottom-left
    ];

    // Median points for a diagonal stroke
    final medianPoints = [
      [700.0, 300.0],  // Top-right (in original coordinates, Y not flipped)
      [650.0, 350.0],
      [600.0, 400.0],
      [550.0, 450.0],
      [500.0, 500.0],
      [450.0, 550.0],
      [400.0, 600.0],
      [350.0, 650.0],
      [300.0, 700.0],  // Bottom-left
    ];

    final canvasSize = const Size(100, 100);

    // Test with regular tolerance - should pass for diagonal strokes
    final result = StrokeValidator.validateStroke(
      userStroke,
      medianPoints,
      canvasSize,
      tolerance: 0.65,
      isMultiDirectional: false,
    );

    expect(result, true, reason: 'Diagonal stroke should be validated correctly');
  });

  test('Reversed diagonal stroke should fail', () {
    // Test diagonal stroke going the wrong way (bottom-left to top-right)
    final padding = 100.0 * 0.1; // 10% padding
    final drawSize = 100.0 - (padding * 2);
    final scale = drawSize / 1024.0 * 1.03;
    final scaledSize = 1024 * scale;
    final offsetX = (100.0 - scaledSize) / 2;
    final offsetY = (100.0 - scaledSize) / 2 - (100.0 * 0.07);
    
    // User stroke going in reverse direction
    final userStroke = [
      Offset(300 * scale + offsetX, (1024 - 700) * scale + offsetY),  // Bottom-left (wrong start)
      Offset(350 * scale + offsetX, (1024 - 650) * scale + offsetY),
      Offset(400 * scale + offsetX, (1024 - 600) * scale + offsetY),
      Offset(450 * scale + offsetX, (1024 - 550) * scale + offsetY),
      Offset(500 * scale + offsetX, (1024 - 500) * scale + offsetY),
      Offset(550 * scale + offsetX, (1024 - 450) * scale + offsetY),
      Offset(600 * scale + offsetX, (1024 - 400) * scale + offsetY),
      Offset(650 * scale + offsetX, (1024 - 350) * scale + offsetY),
      Offset(700 * scale + offsetX, (1024 - 300) * scale + offsetY),  // Top-right (wrong end)
    ];

    // Same median points as before
    final medianPoints = [
      [700.0, 300.0],  // Top-right (correct start)
      [600.0, 400.0],
      [500.0, 500.0],
      [400.0, 600.0],
      [300.0, 700.0],  // Bottom-left (correct end)
    ];

    final canvasSize = const Size(100, 100);

    final result = StrokeValidator.validateStroke(
      userStroke,
      medianPoints,
      canvasSize,
      tolerance: 0.65,
      isMultiDirectional: false,
    );

    expect(result, false, reason: 'Reversed diagonal stroke should fail validation');
  });
}