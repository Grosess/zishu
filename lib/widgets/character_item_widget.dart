import 'package:flutter/material.dart';
import '../services/cedict_service.dart';
import '../utils/pinyin_utils.dart';

/// Widget that displays a character or word with its definition from CEDICT
class CharacterItemWidget extends StatelessWidget {
  final String item;
  final bool isLearned;
  final VoidCallback? onTap;
  final CedictService? cedictService;
  
  const CharacterItemWidget({
    super.key,
    required this.item,
    this.isLearned = false,
    this.onTap,
    this.cedictService,
  });
  
  /// Extract the character/word from item that may contain definition in parentheses
  String _extractTerm(String item) {
    // If item contains parentheses, extract the part before them
    final parenIndex = item.indexOf('(');
    if (parenIndex > 0) {
      return item.substring(0, parenIndex).trim();
    }
    return item.trim();
  }
  
  /// Extract existing definition from item if it has one
  String? _extractExistingDefinition(String item) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(item);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    final term = _extractTerm(item);
    final existingDef = _extractExistingDefinition(item);
    
    // Try to get definition from CEDICT for all terms (single or multi-character)
    String? definition;
    String? pinyin;
    
    if (existingDef != null) {
      // Use existing definition
      definition = existingDef;
    } else if (cedictService != null) {
      // Look up in CEDICT if service is provided
      final entry = cedictService!.lookup(term);
      if (entry != null) {
        definition = entry.definition;
        pinyin = PinyinUtils.convertToneNumbersToMarks(entry.pinyin);
      }
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLearned 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLearned 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main character/word
              Text(
                term,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: isLearned 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Definition and pinyin if available
              if (definition != null || pinyin != null) ...[
                const SizedBox(height: 4),
                Column(
                  children: [
                    if (pinyin != null)
                      Text(
                        pinyin,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (definition != null)
                      Text(
                        definition,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}