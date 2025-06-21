# Database Setup Guide

This app uses character stroke data from the MakeMeAHanzi project.

## Current Implementation

The app currently includes stroke data for three characters (一, 人, 大) in `/assets/character_data.json`.

## Adding More Characters

To add more characters from the MakeMeAHanzi database:

1. **Download MakeMeAHanzi data**:
   - Clone or download the MakeMeAHanzi repository
   - You need the `graphics.txt` file which contains SVG stroke paths and median points

2. **Process the data**:
   ```bash
   # From the project root directory
   dart tools/process_makemeahanzi.dart
   ```
   
   This will extract characters listed in the script and save them to `assets/character_data.json`.

3. **Customize character selection**:
   - Edit `tools/process_makemeahanzi.dart`
   - Modify the `targetCharacters` list to include the characters you want
   - Re-run the script

## Data Format

The character data is stored in JSON format:
```json
{
  "characters": [
    {
      "character": "一",
      "strokes": ["M 128 512 Q 182 518..."],  // SVG path data
      "medians": [[[136, 519], [709, 546]]]   // Key points for stroke validation
    }
  ]
}
```

## Performance Considerations

- The full MakeMeAHanzi database contains data for over 9,000 characters
- Loading all characters at once may impact app startup time
- Consider implementing lazy loading or pagination for large character sets
- You might want to create separate JSON files for different character sets (e.g., HSK levels)

## Alternative Approaches

For production apps with thousands of characters, consider:
1. Using SQLite database with the sqflite package
2. Implementing on-demand loading from server
3. Creating compressed binary format for faster loading
4. Pre-processing data into smaller chunks by difficulty level or category