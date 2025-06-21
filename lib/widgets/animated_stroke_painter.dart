import 'package:flutter/material.dart';
import '../services/character_stroke_service.dart';

class AnimatedStrokePainter extends StatefulWidget {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;
  final VoidCallback? onAnimationComplete;

  const AnimatedStrokePainter({
    super.key,
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedStrokePainter> createState() => _AnimatedStrokePainterState();
}

class _AnimatedStrokePainterState extends State<AnimatedStrokePainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
        // Reverse the animation for continuous effect
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Start again for continuous animation
        _controller.forward();
      }
    });
    
    _controller.forward();
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
        return SizedBox(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          child: CustomPaint(
            painter: AnimatedStrokeGuidePainter(
              characterStroke: widget.characterStroke,
              strokeIndex: widget.strokeIndex,
              canvasSize: widget.canvasSize,
              color: widget.color,
              progress: _animation.value,
            ),
            child: Container(),
          ),
        );
      },
    );
  }
}

class AnimatedStrokeGuidePainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;
  final double progress;

  AnimatedStrokeGuidePainter({
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeIndex >= characterStroke.strokes.length) return;
    
    try {
      // Parse the stroke path
      final path = SvgPathConverter.parsePath(
        characterStroke.strokes[strokeIndex],
        size,
      );
      
      // Create gradient colors for the animated effect
      final gradientColors = [
        color.withOpacity(0.2),
        color.withOpacity(0.5),
        color.withOpacity(1.0),
        color.withOpacity(0.5),
        color.withOpacity(0.2),
      ];
      
      // Calculate path metrics for animation
      final pathMetrics = path.computeMetrics();
      final pathMetricsList = pathMetrics.toList();
      if (pathMetricsList.isEmpty) return;
      
      final pathMetric = pathMetricsList.first;
      final pathLength = pathMetric.length;
      if (pathLength <= 0) return;
    
    // Draw the base stroke with higher opacity
    final basePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, basePaint);
    
    // Draw the animated portion
    final animatedPaint = Paint()
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Create a gradient effect along the stroke
    final gradientLength = pathLength * 0.4; // 40% of the path length
    final startDistance = pathLength * progress;
    
    // Draw multiple segments to create gradient effect
    const segments = 20;
    for (int i = 0; i < segments; i++) {
      final segmentProgress = i / segments;
      final distance = startDistance - (gradientLength * segmentProgress);
      
      if (distance >= 0 && distance <= pathLength) {
        // Calculate color opacity based on position in gradient
        final colorIndex = (segmentProgress * (gradientColors.length - 1)).round();
        final color = gradientColors[colorIndex];
        
        animatedPaint.color = color;
        
        // Extract segment
        final segmentStart = distance;
        final segmentEnd = distance + (pathLength / 200); // Small segment
        
        if (segmentEnd <= pathLength) {
          final segmentPath = pathMetric.extractPath(segmentStart, segmentEnd);
          canvas.drawPath(segmentPath, animatedPaint);
        }
      }
    }
    
    // Draw direction indicators at key points
    if (strokeIndex < characterStroke.medians.length &&
        characterStroke.medians[strokeIndex].isNotEmpty) {
      final medians = characterStroke.medians[strokeIndex];
      
      // Account for padding
      final padding = size.width * 0.1;
      final drawSize = size.width - (padding * 2);
      final scale = drawSize / 1024;
      
      // Draw start point
      final start = medians.first;
      final startPoint = Offset(
        start[0] * scale + padding,
        (1024 - start[1]) * scale + padding,
      );
      
      // Pulsing start indicator
      final pulseScale = 1.0 + (0.3 * (1 - progress).abs());
      final startPaint = Paint()
        ..color = Colors.green.withOpacity(0.8 - (0.4 * progress))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(startPoint, 8 * pulseScale, startPaint);
      
      // Draw arrow at animated position
      if (medians.length > 1) {
        final currentIndex = (progress * (medians.length - 1)).round();
        if (currentIndex < medians.length - 1) {
          final currentPoint = medians[currentIndex];
          final nextPoint = medians[currentIndex + 1];
          
          final arrowPos = Offset(
            currentPoint[0] * scale + padding,
            (1024 - currentPoint[1]) * scale + padding,
          );
          
          final nextPos = Offset(
            nextPoint[0] * scale + padding,
            (1024 - nextPoint[1]) * scale + padding,
          );
          
          // Calculate arrow direction
          final direction = nextPos - arrowPos;
          if (direction.distance > 0) {
            final angle = direction.direction;
            
            // Draw animated arrow
            canvas.save();
            canvas.translate(arrowPos.dx, arrowPos.dy);
            canvas.rotate(angle);
            
            final arrowPaint = Paint()
              ..color = color.withOpacity(0.8)
              ..style = PaintingStyle.fill;
            
            final arrowPath = Path()
              ..moveTo(0, -6)
              ..lineTo(15, 0)
              ..lineTo(0, 6)
              ..close();
            
            canvas.drawPath(arrowPath, arrowPaint);
            canvas.restore();
          }
        }
      }
    }
    } catch (e) {
      // Silently fail to avoid render errors
      // AnimatedStrokePainter error - will be handled by Flutter framework
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedStrokeGuidePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeIndex != strokeIndex;
  }
}