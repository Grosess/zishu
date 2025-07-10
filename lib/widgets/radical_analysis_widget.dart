import 'package:flutter/material.dart';
import '../services/radical_service.dart';
import '../main.dart' show DuotoneThemeExtension;

class RadicalAnalysisWidget extends StatelessWidget {
  final CharacterRadicalAnalysis analysis;
  final bool isCompact;

  const RadicalAnalysisWidget({
    super.key,
    required this.analysis,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme ?? false;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isCompact) {
      return _buildCompactView(context, isDuotone, isDarkMode);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDuotone 
          ? Colors.transparent
          : isDarkMode 
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDuotone
            ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.schema_outlined,
                size: 18,
                color: isDuotone 
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Radical Analysis',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDuotone ? Theme.of(context).colorScheme.onSurface : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Radicals grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: analysis.radicals.map((radical) => 
              _buildRadicalCard(context, radical, isDuotone, isDarkMode)
            ).toList(),
          ),
          
          // Hints section
          if (analysis.semanticHint != null || analysis.phoneticHint != null) ...[
            const SizedBox(height: 16),
            if (analysis.semanticHint != null)
              _buildHint(
                context, 
                Icons.lightbulb_outline, 
                analysis.semanticHint!,
                isDuotone,
              ),
            if (analysis.phoneticHint != null) ...[
              const SizedBox(height: 8),
              _buildHint(
                context, 
                Icons.volume_up_outlined, 
                analysis.phoneticHint!,
                isDuotone,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context, bool isDuotone, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDuotone 
          ? Colors.transparent
          : isDarkMode 
            ? Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDuotone
            ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
            : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schema_outlined,
            size: 14,
            color: isDuotone 
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          ...analysis.radicals.map((radical) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  radical.radical,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDuotone ? Theme.of(context).colorScheme.onSurface : null,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${radical.meaning})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDuotone 
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRadicalCard(BuildContext context, RadicalInfo radical, bool isDuotone, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDuotone
          ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
          : isDarkMode
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDuotone
            ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            radical.radical,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDuotone 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            radical.meaning,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDuotone
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(BuildContext context, IconData icon, String hint, bool isDuotone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDuotone
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
            : Theme.of(context).colorScheme.primary.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: isDuotone
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}