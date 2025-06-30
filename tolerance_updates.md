# Stroke Tolerance Updates - STRICT MODE

## Summary
Made stroke validation much STRICTER for more precise practice as requested.

## Changes Made

### 1. Character Stroke Service (character_stroke_service.dart)
- **Base tolerance**: 0.45 (down from 0.85)
- **Length ratio limits**: 0.7 to 1.5 (can be 30% shorter or 50% longer)
- **Location tolerance**: 70% of base tolerance for all strokes
- **Point tolerance**: 1.2 (strict for start/end points)
- **Direction tolerance**: 60% of base tolerance
- **Required path match**: 70% (up from 20%)

### 2. Writing Practice Page (writing_practice_page.dart)
Updated all character-specific tolerances to be much stricter:
- **Diagonal strokes (一, 人, etc)**: 0.55 (was 0.95)
- **Multi-directional characters (马, 七)**: 0.45 (was 0.85)
- **门 right vertical stroke**: 0.60 (was 0.95)
- **Long vertical strokes**: 0.50 (was 0.90)
- **Multi-directional strokes**: 0.45 (was 0.85)
- **Default for all other strokes**: 0.45 (was 0.85)

## Effect
The autograde system is now much stricter:
- Strokes must be within 30% shorter to 50% longer than expected
- Start and end points must be quite precise
- 70% of the stroke path must match the expected path
- Direction checking is strict
- Requires careful, accurate writing for validation to pass