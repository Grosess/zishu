# App Icon and Splash Screen Setup Guide

## Prerequisites

Before generating icons, install the flutter_launcher_icons package:

```bash
flutter pub add --dev flutter_launcher_icons
```

## Generating App Icons

1. **Run the icon generator**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

   This will:
   - Generate all required icon sizes for iOS and Android
   - Create adaptive icons for Android
   - Set up the app icon for all platforms

2. **Verify icon generation**:
   - Check `android/app/src/main/res/mipmap-*` directories for Android icons
   - Check `ios/Runner/Assets.xcassets/AppIcon.appiconset` for iOS icons

## Setting Up Splash Screen

### For Android

1. **Edit the launch background** at `android/app/src/main/res/drawable/launch_background.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Background color -->
    <item android:drawable="@color/splash_background" />
    
    <!-- Logo -->
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo" />
    </item>
</layer-list>
```

2. **Add colors** to `android/app/src/main/res/values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_background">#FFD700</color>
</resources>
```

3. **Copy the logo** to `android/app/src/main/res/drawable/splash_logo.png`

### For iOS

1. **Update LaunchScreen.storyboard** in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select `LaunchScreen.storyboard`
   - Add an Image View with the Zishu logo
   - Set background color to match the app theme

2. **Alternative: Use flutter_native_splash package**:

```bash
flutter pub add --dev flutter_native_splash
```

Create `flutter_native_splash.yaml`:

```yaml
flutter_native_splash:
  color: "#FFD700"
  image: assets/icons/zishu_logo.png
  
  android_12:
    color: "#FFD700"
    image: assets/icons/zishu_logo.png
    
  ios_content_mode: center
```

Then run:
```bash
flutter pub run flutter_native_splash:create
```

## Manual Icon Requirements

If you need to create icons manually, here are the required sizes:

### Android
- mdpi (48x48)
- hdpi (72x72)
- xhdpi (96x96)
- xxhdpi (144x144)
- xxxhdpi (192x192)

### iOS
- 20pt (20x20, 40x40, 60x60)
- 29pt (29x29, 58x58, 87x87)
- 40pt (40x40, 80x80, 120x120)
- 60pt (120x120, 180x180)
- 76pt (76x76, 152x152)
- 83.5pt (167x167)
- 1024pt (1024x1024) - App Store

## Icon Design Guidelines

1. **Keep it simple**: The icon should be recognizable at small sizes
2. **Use consistent colors**: Match the app's branding (yellow background, red character)
3. **Avoid text**: Icons should be visual only
4. **Test at multiple sizes**: Ensure the icon looks good from 20x20 to 1024x1024

## Troubleshooting

1. **Icons not updating**: 
   - Clean build: `flutter clean`
   - Delete app from device/simulator
   - Rebuild: `flutter run`

2. **Android adaptive icons not working**:
   - Ensure your device runs Android 8.0+
   - Check that both foreground and background are specified

3. **iOS icons have black background**:
   - Set `remove_alpha_ios: true` in flutter_launcher_icons.yaml
   - iOS doesn't support transparency in app icons