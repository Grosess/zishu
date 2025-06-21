import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/character_stroke_service.dart';

class SmoothStrokeHint extends StatefulWidget {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;

  const SmoothStrokeHint({
    super.key,
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
  });

  @override
  State<SmoothStrokeHint> createState() => _SmoothStrokeHintState();
}

class _SmoothStrokeHintState extends State<SmoothStrokeHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _strokeLength = 1.0;

  @override
  void initState() {
    super.initState();
    _calculateStrokeLength();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }
  
  void _calculateStrokeLength() {
    // Calculate approximate stroke length from medians
    if (widget.strokeIndex < widget.characterStroke.medians.length &&
        widget.characterStroke.medians[widget.strokeIndex].length >= 2) {
      final medians = widget.characterStroke.medians[widget.strokeIndex];
      final start = medians.first;
      final end = medians.last;
      
      final dx = end[0] - start[0];
      final dy = end[1] - start[1];
      _strokeLength = math.sqrt(dx * dx + dy * dy) / 1024; // Normalize to 0-1
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Adjust animation based on stroke length
        double easedProgress;
        
        // For short strokes (< 30% of max), add pause at end
        final isShortStroke = _strokeLength < 0.3;
        final pauseDuration = isShortStroke ? 0.2 : 0.0; // 20% pause for short strokes
        
        if (_controller.value < (1.0 - pauseDuration)) {
          // Normal animation phase
          final normalizedValue = _controller.value / (1.0 - pauseDuration);
          
          if (normalizedValue < 0.05) {
            // Brief slow start
            easedProgress = normalizedValue * 3.0;
          } else if (normalizedValue < 0.9) {
            // Constant speed middle section
            final t = (normalizedValue - 0.05) / 0.85;
            easedProgress = 0.15 + (t * 0.85); // Linear progression
          } else {
            // Slight slowdown at end
            final t = (normalizedValue - 0.9) / 0.1;
            easedProgress = 1.0 - (0.05 * (1.0 - t));
          }
        } else {
          // Pause phase for short strokes
          easedProgress = 1.0;
        }
        
        easedProgress = easedProgress.clamp(0.0, 1.0);
        
        return CustomPaint(
          size: widget.canvasSize,
          painter: SmoothHintPainter(
            characterStroke: widget.characterStroke,
            strokeIndex: widget.strokeIndex,
            canvasSize: widget.canvasSize,
            color: widget.color,
            progress: easedProgress,
          ),
        );
      },
    );
  }
}

class SmoothHintPainter extends CustomPainter {
  final CharacterStroke characterStroke;
  final int strokeIndex;
  final Size canvasSize;
  final Color color;
  final double progress;

  SmoothHintPainter({
    required this.characterStroke,
    required this.strokeIndex,
    required this.canvasSize,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeIndex >= characterStroke.strokes.length) return;
    
    // Parse the stroke path
    final path = SvgPathConverter.parsePath(
      characterStroke.strokes[strokeIndex],
      size,
    );
    
    // Draw the full stroke outline first
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(path, outlinePaint);
    
    // Calculate gradient position based on stroke direction
    Offset gradientStart = Offset.zero;
    Offset gradientEnd = Offset(size.width, size.height);
    
    // Use medians to determine stroke direction if available
    if (strokeIndex < characterStroke.medians.length &&
        characterStroke.medians[strokeIndex].length >= 2) {
      final medians = characterStroke.medians[strokeIndex];
      final padding = size.width * 0.1;
      final drawSize = size.width - (padding * 2);
      final scale = drawSize / 1024;
      
      final start = medians.first;
      final end = medians.last;
      
      gradientStart = Offset(
        start[0] * scale + padding,
        (1024 - start[1]) * scale + padding,
      );
      
      gradientEnd = Offset(
        end[0] * scale + padding,
        (1024 - end[1]) * scale + padding,
      );
    }
    
    // Calculate wave animation
    final direction = gradientEnd - gradientStart;
    final strokeLength = direction.distance;
    
    // Normalize direction
    final normalizedDirection = direction / strokeLength;
    
    // Create seamless loop with smaller wave
    final waveWidth = 0.3; // 30% of stroke length
    
    // Progress that goes from 0 to 1 for direct mapping
    final waveProgress = progress;
    
    // Create gradient: full opacity trailing, light blue ahead
    final waveColors = [
      color.withOpacity(1.0),  // Full opacity (behind)
      color.withOpacity(1.0),  // Full opacity
      color.withOpacity(0.8),  // Slightly less
      color.withOpacity(0.5),  // Medium
      color.withOpacity(0.3),  // Light blue (ahead)
    ];
    
    final waveStops = [0.0, 0.15, 0.4, 0.7, 1.0];
    
    // Calculate positions - wave stays within stroke bounds
    final waveCenter = gradientStart + direction * waveProgress;
    final waveStart = waveCenter - normalizedDirection * (strokeLength * waveWidth);
    final waveEnd = waveCenter + normalizedDirection * (strokeLength * 0.05); // Small forward extension
    
    // Only draw if wave is in visible range
    final wavePaint = Paint()
      ..shader = ui.Gradient.linear(
        waveStart,
        waveEnd,
        waveColors,
        waveStops,
      )
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;
    
    // Clip to prevent drawing outside stroke bounds
    canvas.save();
    canvas.clipPath(path);
    
    // Draw the gradient as a filled rect that covers the whole stroke area
    final bounds = path.getBounds();
    final expandedBounds = bounds.inflate(100); // Ensure gradient covers entire stroke
    
    canvas.drawRect(
      expandedBounds,
      wavePaint,
    );
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SmoothHintPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeIndex != strokeIndex;
  }
}