import 'package:flutter/material.dart';
import '../widgets/ink_brush_painter.dart';

class InkBrushDemo extends StatefulWidget {
  const InkBrushDemo({super.key});

  @override
  State<InkBrushDemo> createState() => _InkBrushDemoState();
}

class _InkBrushDemoState extends State<InkBrushDemo> {
  double _brushSize = 20.0;
  double _inkDensity = 0.8;
  double _wetness = 0.6;
  double _bristleDetail = 0.3;
  Color _inkColor = const Color(0xFF1A1A1A);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ink Brush Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: InkBrushCanvas(
                inkColor: _inkColor,
                brushSize: _brushSize,
                inkDensity: _inkDensity,
                wetness: _wetness,
                bristleDetail: _bristleDetail,
                onStrokeComplete: (stroke) {
                  // Production: removed debug print
                },
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Brush Size
                Row(
                  children: [
                    const Icon(Icons.brush, size: 20),
                    const SizedBox(width: 8),
                    const Text('Size:'),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 5.0,
                        max: 50.0,
                        onChanged: (value) => setState(() => _brushSize = value),
                      ),
                    ),
                    Text('${_brushSize.round()}'),
                  ],
                ),
                
                // Ink Density
                Row(
                  children: [
                    const Icon(Icons.opacity, size: 20),
                    const SizedBox(width: 8),
                    const Text('Density:'),
                    Expanded(
                      child: Slider(
                        value: _inkDensity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (value) => setState(() => _inkDensity = value),
                      ),
                    ),
                    Text('${(_inkDensity * 100).round()}%'),
                  ],
                ),
                
                // Wetness
                Row(
                  children: [
                    const Icon(Icons.water_drop, size: 20),
                    const SizedBox(width: 8),
                    const Text('Wetness:'),
                    Expanded(
                      child: Slider(
                        value: _wetness,
                        min: 0.0,
                        max: 2.0,
                        onChanged: (value) => setState(() => _wetness = value),
                      ),
                    ),
                    Text('${(_wetness * 100).round()}%'),
                  ],
                ),
                
                // Bristle Detail
                Row(
                  children: [
                    const Icon(Icons.texture, size: 20),
                    const SizedBox(width: 8),
                    const Text('Bristles:'),
                    Expanded(
                      child: Slider(
                        value: _bristleDetail,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) => setState(() => _bristleDetail = value),
                      ),
                    ),
                    Text('${(_bristleDetail * 100).round()}%'),
                  ],
                ),
                
                // Color selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _colorButton(const Color(0xFF1A1A1A), 'Black'),
                    _colorButton(const Color(0xFF8B4513), 'Brown'),
                    _colorButton(const Color(0xFF2F4F4F), 'Dark Green'),
                    _colorButton(const Color(0xFF8B0000), 'Dark Red'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _colorButton(Color color, String name) {
    final isSelected = _inkColor == color;
    return InkWell(
      onTap: () => setState(() => _inkColor = color),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}