import 'package:flutter/material.dart';
import '../services/character_stroke_service.dart';

class CharacterPreview extends StatelessWidget {
  final String character;
  final bool showStrokeOrder;
  final Color? color;

  const CharacterPreview({
    super.key,
    required this.character,
    this.showStrokeOrder = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final strokeService = CharacterStrokeService();
    final characterStroke = strokeService.getCharacterStroke(character);
    
    if (characterStroke == null) {
      return Center(
        child: Text(
          character,
          style: TextStyle(
            fontSize: 48,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: constraints.biggest,
          painter: CharacterPreviewPainter(
            characterStroke: characterStroke,
            color: color ?? Theme.of(context).colorScheme.onSurface,
            showStrokeOrder: showStrokeOrder,
          ),
        );
      },
    );
  }
}

class CharacterPreviewPainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final Color color;
  final bool showStrokeOrder;

  CharacterPreviewPainter({
    required this.characterStroke,
    required this.color,
    this.showStrokeOrder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw all strokes
    for (int i = 0; i < characterStroke.strokes.length; i++) {
      final strokePath = characterStroke.strokes[i];
      final path = SvgPathConverter.parsePath(strokePath, size);
      canvas.drawPath(path, paint);
      
      // Draw stroke numbers if requested
      if (showStrokeOrder && i < characterStroke.medians.length) {
        final medians = characterStroke.medians[i];
        if (medians.isNotEmpty) {
          final firstPoint = medians[0];
          final padding = size.width * 0.1;
          final drawSize = size.width - (padding * 2);
          final scale = drawSize / 1024;
          
          final numberPos = Offset(
            firstPoint[0] * scale + padding,
            (1024 - firstPoint[1]) * scale + padding,
          );
          
          // White background for number
          final bgPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawCircle(numberPos, 10, bgPaint);
          
          // Number text
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${i + 1}',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            numberPos - Offset(textPainter.width / 2, textPainter.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}