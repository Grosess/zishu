# Build and Release Guide for Zishu

## Pre-Release Checklist

### 1. Update Version Numbers

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version: major.minor.patch+buildnumber
```

### 2. Test Thoroughly

```bash
# Run all tests
flutter test

# Test on different devices
flutter run --release
```

### 3. Optimize Assets

```bash
# Analyze app size
flutter build apk --analyze-size
flutter build ios --analyze-size
```

## Android Release Build

### 1. Create Keystore (First Time Only)

```bash
keytool -genkey -v -keystore ~/zishu-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias zishu
```

### 2. Configure Signing

Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=zishu
storeFile=<path-to-your-keystore>
```

Update `android/app/build.gradle.kts`:
```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 3. Build Release APK

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

## iOS Release Build

### 1. Configure in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner in the navigator
3. In the Signing & Capabilities tab:
   - Select your team
   - Set bundle identifier (e.g., `com.yourcompany.zishu`)

### 2. Update Build Settings

In Xcode:
1. Product > Scheme > Edit Scheme
2. Set Build Configuration to Release
3. Close scheme editor

### 3. Build Archive

```bash
# Build iOS app
flutter build ios --release

# Or use Xcode:
# Product > Archive
```

### 4. Upload to App Store Connect

1. In Xcode: Window > Organizer
2. Select your archive
3. Click "Distribute App"
4. Follow the upload wizard

## Platform-Specific Optimizations

### Android Optimizations

Add to `android/app/build.gradle.kts`:
```kotlin
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            ndk {
                abiFilters 'armeabi-v7a', 'arm64-v8a'
            }
        }
    }
}
```

### iOS Optimizations

In Xcode build settings:
- Enable "Strip Swift Symbols"
- Set "Optimization Level" to "Optimize for Size [-Os]"
- Enable "Dead Code Stripping"

## App Store Submission

### Google Play Store

1. **Create app in Play Console**
2. **Upload app bundle** (`.aab` file)
3. **Fill in store listing**:
   - App name and description
   - Screenshots (phone and tablet)
   - App icon (512x512)
   - Feature graphic (1024x500)
   - Privacy policy URL
4. **Set up pricing and distribution**
5. **Complete content rating questionnaire**
6. **Submit for review**

### Apple App Store

1. **Create app in App Store Connect**
2. **Fill in app information**:
   - App name and subtitle
   - Description
   - Keywords
   - Screenshots (all required sizes)
   - App icon
3. **Set pricing and availability**
4. **Upload build via Xcode**
5. **Submit for review**

## Post-Release

### Monitor Performance

- Check crash reports
- Monitor user reviews
- Track download statistics

### Update Process

1. Increment version in `pubspec.yaml`
2. Add release notes
3. Build and test
4. Upload new version
5. Submit for review

## Troubleshooting

### Android Issues

**Build fails with "Duplicate class"**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Large APK size**:
- Use app bundle instead of APK
- Enable ProGuard/R8
- Split APKs by ABI

### iOS Issues

**Code signing errors**:
- Check provisioning profiles in Xcode
- Ensure certificates are valid
- Clean build folder (Cmd+Shift+K in Xcode)

**Archive not appearing**:
- Ensure scheme is set to Release
- Check that version and build numbers are unique

## Security Reminders

1. **Never commit**:
   - `android/key.properties`
   - Keystore files
   - iOS certificates
   
2. **Add to `.gitignore`**:
   ```
   **/android/key.properties
   **/android/**/*.jks
   **/android/**/*.keystore
   ```

3. **Store securely**:
   - Keep keystore backups
   - Document passwords in password manager
   - Store iOS certificates in Keychain