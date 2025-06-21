# Debugging Definition Lookups

## Current Flow

1. **Character List Page** receives items like:
   - "一起(together)"
   - "北京 (Beijing municipality, capital of the People's Republic of China)"

2. **Term Extraction**:
   - `_extractTerm("一起(together)")` → "一起"
   - `_extractExistingDefinition("一起(together)")` → "together"

3. **When Item is Clicked**, `_showCharacterInfo` is called:
   - First checks for existing definition in parentheses
   - Then tries CharacterDictionary (very limited entries)
   - Finally tries CEDICT (should have all HSK words)

## Debugging Steps Added

1. **CEDICT Service**:
   - Logs initialization status
   - Logs file size when loaded
   - Logs number of entries parsed
   - Logs each lookup attempt and result

2. **Character List Page**:
   - Logs CEDICT initialization
   - Logs each step of definition lookup
   - Shows which source provided the definition

## Expected Console Output

When you click on "一起":
```
_showCharacterInfo: term=一起, originalItem=一起(together), isWord=true
Found existing definition: together
Trying CEDICT lookup for: 一起
CEDICT: Found entry for 一起: yi1 qi3 - the same place
Final result: pronunciation=yi1 qi3, definition=together
```

## To Test

1. Run the app
2. Navigate to HSK 1
3. Click on "一起" (or any multi-character term)
4. Check the console output
5. Verify the dialog shows pronunciation and definition

## Common Issues

1. **CEDICT not loading**: Check asset path in pubspec.yaml
2. **No definitions found**: Check console for "CEDICT not initialized"
3. **Wrong definitions**: Check if existing definition is overriding CEDICT