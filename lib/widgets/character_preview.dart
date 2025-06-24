import 'package:flutter/material.dart';
import '../services/character_stroke_service.dart';
import '../services/character_preview_cache.dart';

class CharacterPreview extends StatefulWidget {
  final String character;
  final bool showStrokeOrder;
  final Color? color;
  final bool forceText; // Option to force text rendering

  const CharacterPreview({
    super.key,
    required this.character,
    this.showStrokeOrder = false,
    this.color,
    this.forceText = false,
  });

  @override
  State<CharacterPreview> createState() => _CharacterPreviewState();
}

class _CharacterPreviewState extends State<CharacterPreview> {
  CharacterStroke? _characterStroke;
  bool _isLoading = true;
  final CharacterPreviewCache _cache = CharacterPreviewCache();

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  @override
  void didUpdateWidget(CharacterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _loadCharacterData();
    }
  }

  Future<void> _loadCharacterData() async {
    // Skip loading if forcing text
    if (widget.forceText) {
      setState(() {
        _isLoading = false;
        _characterStroke = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final characterStroke = await _cache.getCharacterStroke(widget.character);
      
      if (mounted) {
        setState(() {
          _characterStroke = characterStroke;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a subtle loading state
      return Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            widget.character,
            style: TextStyle(
              fontSize: 120,
              color: (widget.color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.3),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }
    
    if (_characterStroke == null) {
      // Fallback to text if no stroke data available
      return Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            widget.character,
            style: TextStyle(
              fontSize: 120,
              color: widget.color ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: constraints.biggest,
          painter: CharacterPreviewPainter(
            characterStroke: _characterStroke!,
            color: widget.color ?? Theme.of(context).colorScheme.onSurface,
            showStrokeOrder: widget.showStrokeOrder,
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