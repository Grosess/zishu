# Claude.md - Project Reference

## Zishu - Hanzi Writing Practice App

A Flutter app for practicing Chinese character writing with stroke validation using MakeMeAHanzi data.

## Running the App

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Architecture

### Character Stroke System

The app uses SVG stroke data from MakeMeAHanzi to validate character writing:

1. **CharacterStrokeService** (`lib/services/character_stroke_service.dart`)
   - Loads character stroke data (SVG paths and median points)
   - Provides stroke validation using median point matching
   - Parses SVG paths for rendering

2. **MakeMeAHanziProcessor** (`lib/services/makemeahanzi_processor.dart`)
   - Processes raw graphics.txt data from MakeMeAHanzi
   - Builds index for fast character lookup
   - Caches processed data

3. **CharacterSetManager** (`lib/services/character_set_manager.dart`)
   - Manages predefined and custom character sets
   - Handles dynamic loading from MakeMeAHanzi database

### Current Test Characters

The app currently uses sample radicals from MakeMeAHanzi:
- ⺀ (ice radical) - 2 strokes
- ⺈ (divination radical) - 2 strokes  
- ⺊ (vertical line radical) - 2 strokes

These are loaded from `/assets/character_data.json`.

### Key Features

1. **Stroke Validation**: Uses median points from MakeMeAHanzi to validate stroke accuracy
2. **Visual Feedback**: Completed strokes appear as filled white shapes
3. **Hints**: After 2 wrong attempts, shows stroke path as hint
4. **Square Practice Area**: Always maintains 1:1 aspect ratio
5. **SVG Rendering**: Uses actual SVG paths for accurate character representation

## Adding More Characters

To add characters from MakeMeAHanzi:

```bash
# Generate character set from string
dart tools/generate_character_set.dart "你好世界" hello_world.json

# Generate from file
dart tools/generate_character_set.dart @characters.txt output.json
```

## Character Database System

The app now includes a proper database loading system:

1. **CharacterDatabase** (`lib/services/character_database.dart`)
   - Loads characters on-demand from graphics.txt
   - Builds an index for fast lookup
   - Caches loaded characters
   - Supports both file system and asset loading

2. **Character Loading Process**:
   - When entering practice mode, only the needed characters are loaded
   - Characters are cached after first load
   - Y-axis is properly flipped (MakeMeAHanzi uses bottom-left origin)

3. **Generate Character Index** (for performance):
   ```bash
   dart tools/generate_character_index.dart
   ```
   This creates an index file for instant character lookup.

## Known Issues Fixed

1. ✓ Characters were upside down - Fixed by flipping Y-axis
2. ✓ Only first 3 characters loaded - Now loads on demand
3. ✓ No proper database system - Created CharacterDatabase service

## Debugging

Check console for:
- "Built index with X characters" - Database initialization
- "Character data not found for: X" - Missing characters
- "Stroke end: ..." - Stroke detection messages
- "Stroke validation result: true/false" - Validation results

## Dependencies

Key packages:
- shared_preferences: Local storage
- uuid: Unique identifiers
- sqflite: Database support (not currently used)
- path/path_provider: File system access

NEVER alter the database
NEVER manually add definitions
NEVER create specific solutions for general problems. ie, problem with 1 term, put an if statement instead of addressing the logic issue

DO NOT EDIT THE CHARACTER WRITING/DEFINITION UNLESS EXPLICITLY ASKED TO

NEVER manually create chinese data