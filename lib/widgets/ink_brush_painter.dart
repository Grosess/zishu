import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class InkBrushStroke {
  final List<Offset> points;
  final List<double> pressures;
  final List<double> velocities;
  final List<double> angles;
  
  InkBrushStroke({
    required this.points,
    required this.pressures,
    required this.velocities,
    required this.angles,
  });
}

class InkBrushPainter extends CustomPainter {
  final InkBrushStroke stroke;
  final Color inkColor;
  final double baseWidth;
  final double inkDensity;
  final double wetness;
  final double bristleDetail;
  
  InkBrushPainter({
    required this.stroke,
    this.inkColor = const Color(0xFF1A1A1A),
    this.baseWidth = 20.0,
    this.inkDensity = 0.8,
    this.wetness = 0.6,
    this.bristleDetail = 0.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stroke.points.length < 2) return;
    
    // Draw the main stroke with varying width and opacity
    _drawMainStroke(canvas);
    
    // Add texture and bristle effects
    _drawBristleTexture(canvas);
    
    // Add ink pooling effects at slower points
    _drawInkPooling(canvas);
  }
  
  void _drawMainStroke(Canvas canvas) {
    final path = Path();
    final paint = Paint()
      ..color = inkColor.withOpacity(inkDensity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, wetness);
    
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final angle = stroke.angles[i];
      final pressure = stroke.pressures[i];
      final velocity = stroke.velocities[i];
      
      // Calculate brush width based on pressure and velocity
      // Faster strokes = thinner, more pressure = wider
      final speedFactor = 1.0 - (velocity.clamp(0.0, 1.0) * 0.6);
      final width = baseWidth * pressure * speedFactor;
      
      // Create rectangular brush shape oriented to stroke direction
      _drawBrushSegment(canvas, p1, p2, angle, width, paint);
    }
  }
  
  void _drawBrushSegment(
    Canvas canvas, 
    Offset p1, 
    Offset p2, 
    double angle,
    double width,
    Paint paint,
  ) {
    // Calculate perpendicular offset for rectangle width
    final perpAngle = angle + math.pi / 2;
    final halfWidth = width / 2;
    
    final dx = math.cos(perpAngle) * halfWidth;
    final dy = math.sin(perpAngle) * halfWidth;
    
    // Create rectangular segment
    final path = Path()
      ..moveTo(p1.dx - dx, p1.dy - dy)
      ..lineTo(p1.dx + dx, p1.dy + dy)
      ..lineTo(p2.dx + dx, p2.dy + dy)
      ..lineTo(p2.dx - dx, p2.dy - dy)
      ..close();
    
    // Add slight rotation variation for organic feel
    final rotationNoise = (math.Random().nextDouble() - 0.5) * 0.1;
    canvas.save();
    canvas.translate(p1.dx, p1.dy);
    canvas.rotate(rotationNoise);
    canvas.translate(-p1.dx, -p1.dy);
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }
  
  void _drawBristleTexture(Canvas canvas) {
    if (bristleDetail <= 0) return;
    
    final random = math.Random(42); // Fixed seed for consistent bristles
    final bristlePaint = Paint()
      ..color = inkColor.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final angle = stroke.angles[i];
      final pressure = stroke.pressures[i];
      final velocity = stroke.velocities[i];
      
      final speedFactor = 1.0 - (velocity.clamp(0.0, 1.0) * 0.6);
      final width = baseWidth * pressure * speedFactor;
      
      // Draw individual bristle lines
      final bristleCount = (width * bristleDetail * 2).round();
      for (int b = 0; b < bristleCount; b++) {
        final offset = (b / bristleCount - 0.5) * width;
        final perpAngle = angle + math.pi / 2;
        
        final bristleOffset = Offset(
          math.cos(perpAngle) * offset,
          math.sin(perpAngle) * offset,
        );
        
        // Add random variation to bristle
        final variation = random.nextDouble() * 0.2 - 0.1;
        final bristleP1 = p1 + bristleOffset + 
          Offset(
            random.nextDouble() * 2 - 1,
            random.nextDouble() * 2 - 1,
          ) * variation * width;
        final bristleP2 = p2 + bristleOffset +
          Offset(
            random.nextDouble() * 2 - 1,
            random.nextDouble() * 2 - 1,
          ) * variation * width;
        
        // Vary opacity based on position from center
        final distanceFromCenter = (offset / (width / 2)).abs();
        bristlePaint.color = inkColor.withOpacity(
          0.2 * (1.0 - distanceFromCenter) * inkDensity
        );
        
        canvas.drawLine(bristleP1, bristleP2, bristlePaint);
      }
    }
  }
  
  void _drawInkPooling(Canvas canvas) {
    final poolPaint = Paint()
      ..color = inkColor.withOpacity(inkDensity * 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, wetness * 2);
    
    // Add ink pooling at slow points and stroke ends
    for (int i = 0; i < stroke.points.length; i++) {
      final velocity = stroke.velocities[i];
      final pressure = stroke.pressures[i];
      
      // Pool more ink at slower points
      if (velocity < 0.3 || i == 0 || i == stroke.points.length - 1) {
        final poolRadius = baseWidth * pressure * 0.3 * (1.0 - velocity);
        canvas.drawCircle(stroke.points[i], poolRadius, poolPaint);
      }
    }
  }

  @override
  bool shouldRepaint(InkBrushPainter oldDelegate) {
    return oldDelegate.stroke != stroke ||
           oldDelegate.inkColor != inkColor ||
           oldDelegate.baseWidth != baseWidth ||
           oldDelegate.inkDensity != inkDensity ||
           oldDelegate.wetness != wetness ||
           oldDelegate.bristleDetail != bristleDetail;
  }
}

// Widget to capture and render ink brush strokes
class InkBrushCanvas extends StatefulWidget {
  final Color inkColor;
  final double brushSize;
  final double inkDensity;
  final double wetness;
  final double bristleDetail;
  final Function(InkBrushStroke)? onStrokeComplete;
  
  const InkBrushCanvas({
    super.key,
    this.inkColor = const Color(0xFF1A1A1A),
    this.brushSize = 20.0,
    this.inkDensity = 0.8,
    this.wetness = 0.6,
    this.bristleDetail = 0.3,
    this.onStrokeComplete,
  });
  
  @override
  State<InkBrushCanvas> createState() => _InkBrushCanvasState();
}

class _InkBrushCanvasState extends State<InkBrushCanvas> {
  final List<InkBrushStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  List<double> _currentPressures = [];
  List<double> _currentVelocities = [];
  List<double> _currentAngles = [];
  Offset? _previousPoint;
  DateTime? _previousTime;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _currentPoints = [details.localPosition];
          _currentPressures = [details.pressure ?? 1.0];
          _currentVelocities = [0.0];
          _currentAngles = [0.0];
          _previousPoint = details.localPosition;
          _previousTime = DateTime.now();
        });
      },
      onPanUpdate: (details) {
        setState(() {
          final currentPoint = details.localPosition;
          final currentTime = DateTime.now();
          
          // Calculate velocity
          double velocity = 0.0;
          if (_previousPoint != null && _previousTime != null) {
            final distance = (currentPoint - _previousPoint!).distance;
            final timeDelta = currentTime.difference(_previousTime!).inMilliseconds;
            velocity = (distance / timeDelta).clamp(0.0, 1.0);
          }
          
          // Calculate angle
          double angle = 0.0;
          if (_previousPoint != null) {
            final delta = currentPoint - _previousPoint!;
            angle = math.atan2(delta.dy, delta.dx);
          }
          
          _currentPoints.add(currentPoint);
          _currentPressures.add(details.pressure ?? 1.0);
          _currentVelocities.add(velocity);
          _currentAngles.add(angle);
          
          _previousPoint = currentPoint;
          _previousTime = currentTime;
        });
      },
      onPanEnd: (details) {
        if (_currentPoints.isNotEmpty) {
          final stroke = InkBrushStroke(
            points: List.from(_currentPoints),
            pressures: List.from(_currentPressures),
            velocities: List.from(_currentVelocities),
            angles: List.from(_currentAngles),
          );
          
          setState(() {
            _strokes.add(stroke);
            _currentPoints.clear();
            _currentPressures.clear();
            _currentVelocities.clear();
            _currentAngles.clear();
            _previousPoint = null;
            _previousTime = null;
          });
          
          widget.onStrokeComplete?.call(stroke);
        }
      },
      child: CustomPaint(
        painter: _InkBrushMultiStrokePainter(
          strokes: _strokes,
          currentStroke: _currentPoints.isNotEmpty ? InkBrushStroke(
            points: _currentPoints,
            pressures: _currentPressures,
            velocities: _currentVelocities,
            angles: _currentAngles,
          ) : null,
          inkColor: widget.inkColor,
          baseWidth: widget.brushSize,
          inkDensity: widget.inkDensity,
          wetness: widget.wetness,
          bristleDetail: widget.bristleDetail,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _InkBrushMultiStrokePainter extends CustomPainter {
  final List<InkBrushStroke> strokes;
  final InkBrushStroke? currentStroke;
  final Color inkColor;
  final double baseWidth;
  final double inkDensity;
  final double wetness;
  final double bristleDetail;
  
  _InkBrushMultiStrokePainter({
    required this.strokes,
    this.currentStroke,
    required this.inkColor,
    required this.baseWidth,
    required this.inkDensity,
    required this.wetness,
    required this.bristleDetail,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (final stroke in strokes) {
      final painter = InkBrushPainter(
        stroke: stroke,
        inkColor: inkColor,
        baseWidth: baseWidth,
        inkDensity: inkDensity,
        wetness: wetness,
        bristleDetail: bristleDetail,
      );
      painter.paint(canvas, size);
    }
    
    // Draw current stroke
    if (currentStroke != null) {
      final painter = InkBrushPainter(
        stroke: currentStroke!,
        inkColor: inkColor,
        baseWidth: baseWidth,
        inkDensity: inkDensity,
        wetness: wetness,
        bristleDetail: bristleDetail,
      );
      painter.paint(canvas, size);
    }
  }
  
  @override
  bool shouldRepaint(_InkBrushMultiStrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
           oldDelegate.currentStroke != currentStroke ||
           oldDelegate.inkColor != inkColor ||
           oldDelegate.baseWidth != baseWidth ||
           oldDelegate.inkDensity != inkDensity ||
           oldDelegate.wetness != wetness ||
           oldDelegate.bristleDetail != bristleDetail;
  }
}