#!/bin/bash

echo "=== Flutter iOS Build Diagnostic ==="
echo ""

# Check Flutter installation
echo "1. Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    echo "✓ Flutter found at: $(which flutter)"
    flutter --version
else
    echo "✗ Flutter not found in PATH"
    echo "  Please ensure Flutter is installed and added to your PATH"
fi
echo ""

# Check Xcode installation
echo "2. Checking Xcode installation..."
if command -v xcodebuild &> /dev/null; then
    echo "✓ Xcode found"
    xcodebuild -version
else
    echo "✗ Xcode not found"
    echo "  Please install Xcode from the App Store"
fi
echo ""

# Check CocoaPods
echo "3. Checking CocoaPods installation..."
if command -v pod &> /dev/null; then
    echo "✓ CocoaPods found at: $(which pod)"
    pod --version
else
    echo "✗ CocoaPods not found"
    echo "  Install with: sudo gem install cocoapods"
fi
echo ""

# Check iOS configuration files
echo "4. Checking iOS configuration files..."
cd ios 2>/dev/null || { echo "✗ ios directory not found"; exit 1; }

if [ -f "Podfile" ]; then
    echo "✓ Podfile exists"
else
    echo "✗ Podfile missing"
fi

if [ -f "Flutter/Generated.xcconfig" ]; then
    echo "✓ Generated.xcconfig exists"
    # Check if it has Windows paths
    if grep -q "C:\\\\" "Flutter/Generated.xcconfig"; then
        echo "  ⚠️  WARNING: Generated.xcconfig contains Windows paths!"
    fi
else
    echo "✗ Generated.xcconfig missing"
fi

if [ -d "Pods" ]; then
    echo "✓ Pods directory exists"
else
    echo "✗ Pods directory missing (run 'pod install')"
fi

if [ -f "Podfile.lock" ]; then
    echo "✓ Podfile.lock exists"
else
    echo "✗ Podfile.lock missing"
fi
echo ""

# Check for common issues
echo "5. Identified Issues:"
echo "-------------------"

issues=0

# Issue 1: Windows paths
if [ -f "Flutter/Generated.xcconfig" ] && grep -q "C:\\\\" "Flutter/Generated.xcconfig"; then
    echo "• Generated.xcconfig contains Windows paths (project was likely created on Windows)"
    echo "  Fix: Delete ios/Flutter/Generated.xcconfig and ios/Flutter/flutter_export_environment.sh"
    echo "       Then run 'flutter pub get'"
    ((issues++))
fi

# Issue 2: Missing Podfile
if [ ! -f "Podfile" ]; then
    echo "• Podfile is missing"
    echo "  Fix: Run the fix_ios_build.sh script or create Podfile manually"
    ((issues++))
fi

# Issue 3: Missing Pods
if [ ! -d "Pods" ] && [ -f "Podfile" ]; then
    echo "• Pods not installed"
    echo "  Fix: Run 'pod install' in the ios directory"
    ((issues++))
fi

if [ $issues -eq 0 ]; then
    echo "✓ No obvious issues found"
fi

echo ""
echo "=== Diagnostic Complete ==="