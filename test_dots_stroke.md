# Testing Dots Stroke Type

## Steps to test:
1. Open the app in Chrome (✓ Already running)
2. Navigate to Settings page
3. Find "Stroke type" setting
4. Select "Dots - Circles that vary with speed"
5. Return to practice page
6. Try writing strokes with varying speeds:
   - Write slowly to see larger dots
   - Write quickly to see smaller dots
   - Check color fade from white (newest) to blue (oldest)

## Expected behavior:
- Dots should be circles, not lines
- Size should vary dramatically with speed (0.1x to 2.0x stroke width)
- Slower movement = much larger dots
- Faster movement = much smaller dots
- Color should fade from white at the front to blue at the back
- Smooth, non-choppy appearance with 15% smoothing factor

## Current implementation details:
- Stroke width default for dots: 15.0
- Size range: 0.1x to 2.0x stroke width (1.5 to 30 pixels)
- Speed normalization: 0-5 pixels per frame
- Size calculation: exponential curve (1 - normalizedSpeed)²
- Color: white (newest) to blue (oldest) with exponential fade
- Smoothing: 15% factor for position and speed
- Dot spacing: 0.3x stroke width