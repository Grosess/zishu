# Character Set System

The Zishu app now has a flexible system for managing character sets from the MakeMeAHanzi database.

## System Architecture

1. **CharacterSetManager** (`lib/services/character_set_manager.dart`)
   - Manages predefined and custom character sets
   - Handles loading characters from sets
   - Allows creation of custom sets from user input

2. **MakeMeAHanziProcessor** (`lib/services/makemeahanzi_processor.dart`)
   - Processes raw MakeMeAHanzi graphics.txt data
   - Builds an index for fast character lookup
   - Caches processed character data
   - Can work with both file system and Flutter assets

3. **CharacterStrokeService** (`lib/services/character_stroke_service.dart`)
   - Stores and provides access to character stroke data
   - Supports dynamic addition of characters
   - Handles SVG path parsing and stroke validation

## How It Works

### 1. Define Character Sets

Character sets are defined in `assets/character_sets.json`:

```json
{
  "sets": [
    {
      "id": "numbers",
      "name": "Numbers 1-10",
      "characters": "一二三四五六七八九十",
      "description": "Basic Chinese numbers",
      "difficulty": "beginner"
    }
  ]
}
```

### 2. Generate Character Data

Use the command-line tools to extract character data from MakeMeAHanzi:

```bash
# Generate a single set
dart tools/generate_character_set.dart "一二三" numbers.json

# Generate all predefined sets
bash scripts/generate_all_sets.sh
```

### 3. Load Characters in the App

When a user selects a character set:

1. The app loads the character list from the set definition
2. MakeMeAHanziProcessor looks up each character in the graphics.txt index
3. Character stroke data (SVG paths and medians) is extracted
4. Data is passed to CharacterStrokeService for use in practice

### 4. Practice Flow

1. User selects a character set
2. App loads stroke data for all characters in the set
3. Characters are displayed in a list
4. User can practice writing with stroke validation

## Adding New Character Sets

### Method 1: Predefined Sets

1. Edit `assets/character_sets.json`
2. Add your new set definition
3. Run `dart tools/generate_character_set.dart` with your characters
4. The set will appear in the app automatically

### Method 2: Custom Sets (User Created)

Users can create custom sets directly in the app:
1. Tap the "Custom Set" button
2. Enter a name and characters
3. The app processes them from MakeMeAHanzi data

### Method 3: Batch Processing

For large-scale character set generation:

```bash
# Create a file with characters
echo "你好世界学习汉字" > my_characters.txt

# Generate the set
dart tools/generate_character_set.dart @my_characters.txt my_set.json
```

## Performance Considerations

- The MakeMeAHanziProcessor builds an in-memory index on first load
- Character data is cached after first access
- For large databases, consider using pagination or lazy loading
- The system can handle thousands of characters efficiently

## File Structure

```
assets/
├── character_sets.json          # Set definitions
├── character_data.json          # Current active data
├── character_sets/              # Generated set data
│   ├── numbers.json
│   ├── nature.json
│   └── ...
└── character_database.json      # Master database (optional)

database-sample/                 # MakeMeAHanzi source
└── makemeahanzi-master/
    └── graphics.txt            # Raw stroke data
```

## Future Enhancements

1. **Cloud Sync**: Store custom sets in cloud
2. **Set Sharing**: Export/import character sets
3. **Progress Tracking**: Track completion per set
4. **Difficulty Levels**: Auto-organize by stroke count
5. **Spaced Repetition**: Smart practice scheduling