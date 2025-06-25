# Common Definitions Implementation

## Overview
I've implemented an automated system to ensure the most common definitions and pronunciations are used for all characters in the app. This system works beyond just the Skritter CSV by using rules and patterns.

## How It Works

### 1. Automated Import Tool
Created `tools/generate_common_definitions.dart` that:
- Imports the Skritter CSV automatically
- Processes 294 entries (139 single characters, 155 multi-character words)
- Adds pronunciation rules for common particles
- Generates `lib/data/common_definitions.dart`

### 2. Common Definitions Database
The generated file contains:
- Character/word
- Preferred pinyin pronunciation
- Curated definition
- Priority level (lower = more common)

### 3. CedictService Integration
Modified `CedictService` to:
- Check common definitions first when parsing CEDICT
- Use preferred pronunciations when available
- Fall back to CEDICT's first entry (usually most common) when no override exists

## Pronunciation Preference Handling

### Location
Pronunciation preferences are stored in `lib/data/common_definitions.dart` as part of the `CommonDefinition` structure. Each entry specifies both the preferred pinyin and definition together.

### How It Works for All Characters

1. **Skritter CSV Data**: 294 entries with learner-friendly definitions
2. **Pronunciation Rules**: Added for particles like:
   - 的 → de5 (possessive particle)
   - 得 → de5 (complement particle)
   - 着 → zhe5 (aspect particle)
   - 过 → guo5 (experiential particle)

3. **Fallback System**:
   - If character is in common_definitions → use that
   - Otherwise → use CEDICT's first entry (typically most common)
   - Skip unhelpful definitions (surnames, variants)

4. **Priority System**:
   - Single characters: priority 1-3
   - Multi-character words: priority 10+
   - HSK level correlates with priority

## Examples

- **了**: Always uses le5 (particle) instead of liao3/liao4
- **东西**: Always uses dong1xi5 (thing) instead of dong1xi1 (east-west)
- **好**: Uses hao3 (good) as primary, not hao4

## Extending the System

To add more common definitions:

1. Add entries to the Skritter CSV
2. Or modify `tools/generate_common_definitions.dart` to add rules
3. Run: `dart tools/generate_common_definitions.dart skritter.csv`

The system is designed to be extensible - you can add frequency data, HSK correlations, or linguistic research data in the future.

## Benefits

1. **Consistent**: Same definition/pronunciation everywhere
2. **Learner-friendly**: Uses definitions from actual learning materials
3. **Automated**: No manual data entry
4. **Extensible**: Easy to add more overrides
5. **Intelligent fallback**: Works for all 100,000+ CEDICT entries