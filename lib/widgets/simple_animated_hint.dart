import 'package:flutter/material.dart';
import '../services/character_stroke_service.dart';

class SimpleAnimatedHint extends StatefulWidget {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;

  const SimpleAnimatedHint({
    super.key,
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
  });

  @override
  State<SimpleAnimatedHint> createState() => _SimpleAnimatedHintState();
}

class _SimpleAnimatedHintState extends State<SimpleAnimatedHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: widget.canvasSize,
          painter: SimpleHintPainter(
            characterStroke: widget.characterStroke,
            strokeIndex: widget.strokeIndex,
            canvasSize: widget.canvasSize,
            color: widget.color,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

class SimpleHintPainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;
  final double animationValue;

  SimpleHintPainter({
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeIndex >= characterStroke.strokes.length) return;
    
    // Parse the stroke path
    final path = SvgPathConverter.parsePath(
      characterStroke.strokes[strokeIndex],
      size,
    );
    
    // Draw the base stroke with a subtle color
    final basePaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, basePaint);
    
    // Create animated gradient effect using path metrics
    try {
      final pathMetrics = path.computeMetrics();
      if (pathMetrics.isEmpty) return;
      
      final pathMetric = pathMetrics.first;
      final pathLength = pathMetric.length;
      
      // Define the sweep parameters
      final sweepLength = pathLength * 0.3; // 30% of path length
      final sweepCenter = pathLength * animationValue;
      
      // Draw the gradient sweep in multiple passes for smooth effect
      const gradientSteps = 20;
      for (int i = 0; i < gradientSteps; i++) {
        final stepProgress = i / gradientSteps;
        final distance = sweepCenter - (sweepLength * stepProgress);
        
        if (distance >= 0 && distance <= pathLength) {
          // Calculate intensity for this step
          final intensity = 1.0 - stepProgress;
          final opacity = 0.1 + (0.7 * intensity * intensity);
          
          // Extract the portion of the path
          final start = (distance - 5).clamp(0.0, pathLength);
          final end = (distance + 5).clamp(0.0, pathLength);
          
          if (end > start) {
            final subPath = pathMetric.extractPath(start, end);
            
            final sweepPaint = Paint()
              ..color = color.withOpacity(opacity)
              ..strokeWidth = 10.0 + (6.0 * intensity)
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke;
            
            canvas.drawPath(subPath, sweepPaint);
          }
        }
      }
    } catch (e) {
      // Fallback to simple animated opacity if path metrics fail
      final animatedPaint = Paint()
        ..color = color.withOpacity(0.2 + (0.5 * animationValue))
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawPath(path, animatedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SimpleHintPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.strokeIndex != strokeIndex;
  }
}