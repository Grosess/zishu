import 'package:flutter/material.dart';
import '../services/radical_service.dart';

class SimpleRadicalDisplay extends StatelessWidget {
  final CharacterRadicalAnalysis analysis;
  
  const SimpleRadicalDisplay({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out radicals that only have "component" as meaning
    final meaningfulRadicals = analysis.radicals
        .where((radical) => radical.meaning != 'component' && radical.meaning.isNotEmpty)
        .toList();
    
    // If no meaningful radicals, don't display anything
    if (meaningfulRadicals.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 16,
      children: meaningfulRadicals.map((radical) {
        // Remove direction indicators from meaning - handle both with and without spaces
        String cleanMeaning = radical.meaning
            .replaceAll(RegExp(r'\s*\(left\)'), '')
            .replaceAll(RegExp(r'\s*\(right\)'), '')
            .replaceAll(RegExp(r'\s*\(top\)'), '')
            .replaceAll(RegExp(r'\s*\(bottom\)'), '')
            .replaceAll('(left)', '')
            .replaceAll('(right)', '')
            .replaceAll('(top)', '')
            .replaceAll('(bottom)', '')
            .trim();
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              radical.radical,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '- $cleanMeaning',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}