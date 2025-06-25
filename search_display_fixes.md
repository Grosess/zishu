# Search Display Fixes

## Issues Fixed

### 1. Multi-character display in the box (leading widget)
- Used `FittedBox` with `BoxFit.scaleDown` to automatically scale text to fit
- Adjusted font sizes: 2 chars = 20px, 3 chars = 14px, 4+ chars = 12px
- For entries longer than 4 characters, show first 3 + "..." (e.g., "新加坡..." instead of trying to squeeze all characters)

### 2. Pinyin tone numbers → tone marks
- Now using `PinyinUtils.convertToneNumbersToMarks()` to convert pinyin
- Example: "wu1 hei1 se4" → "wū hēi sè"

### 3. Long pinyin causing overflow
- Wrapped pinyin text in `Expanded` widget
- Added `overflow: TextOverflow.ellipsis` and `maxLines: 1`
- This prevents long pinyin from overflowing and breaking the layout

### 4. Long character entries (7+ characters)
- In the title, entries longer than 7 characters show first 6 + "..."
- Example: "中华人民共和国" → "中华人民共和..."

### 5. Long definitions
- Added `overflow: TextOverflow.ellipsis` and `maxLines: 2` to subtitle
- Definitions will now wrap to 2 lines max, then show "..."

## Visual Improvements
- Better scaling for multi-character entries in the preview box
- Consistent text truncation with "..." for long content
- Proper tone marks instead of numbers for better readability
- No more text overflow issues

## To Test
1. Hot reload the app (press 'r' in terminal)
2. Search for:
   - "toilet" - should show proper tone marks
   - "singapore" - should handle 3-character display nicely
   - "africa" - test multi-pronunciation handling
   - Long entries should truncate properly with "..."