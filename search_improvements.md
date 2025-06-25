# Search Improvements

## Changes Made

### 1. Offensive Content Filtering
- Added filter in `CedictService._shouldFilterDefinition()` to exclude entries containing offensive terms
- Specifically filters out entries with "nigger" or "negro" in the definition

### 2. HSK Level Prioritization
Search results are now sorted by priority:

**Priority Order:**
1. HSK 1 characters (priority: 1)
2. HSK 2 characters (priority: 2)
3. HSK 3 characters (priority: 3)
4. HSK 4 characters (priority: 4)
5. HSK 5 characters (priority: 5)
6. HSK 6 characters (priority: 6)
7. Common sets:
   - Radicals (priority: 20)
   - Numbers (priority: 25)
   - Colors (priority: 30)
   - Common characters (priority: 35)
8. Other predefined sets (priority: 100)
9. Characters not in any set (priority: 999)

### 3. Improved Search Flow
1. Searches entire CEDICT dictionary (100 results max)
2. Loads all predefined character sets
3. Assigns priority to each character based on which sets it appears in
4. Sorts results by:
   - Priority (HSK level, common sets, etc.)
   - Character length (single characters before compounds)
   - Pinyin (alphabetical)
5. Returns top 50 results after sorting

## Benefits
- **Easier learning progression**: HSK 1 characters appear first, making it easier for beginners
- **Relevant results**: Common, practical characters are prioritized over obscure ones
- **Clean results**: Offensive content is filtered out
- **Better organization**: Results are sorted in a logical learning order

## Example
When searching for "water":
- 水 (shuǐ) - HSK 1 - will appear first
- 河 (hé) - HSK 2 - will appear next
- More advanced water-related terms will appear later

This makes the search much more useful for learners at all levels!