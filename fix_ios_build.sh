#!/bin/bash

echo "Fixing iOS build configuration for Flutter project..."

# Remove generated files with incorrect paths
echo "Removing generated Flutter configuration files..."
rm -f ios/Flutter/Generated.xcconfig
rm -f ios/Flutter/flutter_export_environment.sh

# Create Podfile if it doesn't exist
if [ ! -f "ios/Podfile" ]; then
    echo "Creating Podfile..."
    cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
EOF
fi

echo "Script complete!"
echo ""
echo "Next steps:"
echo "1. Ensure Flutter is installed and in your PATH"
echo "2. Run: flutter clean"
echo "3. Run: flutter pub get"
echo "4. Run: cd ios && pod install"
echo "5. Try building again with: flutter build ios"
echo ""
echo "If Flutter is not in your PATH, add it with:"
echo "export PATH=\"\$PATH:[YOUR_FLUTTER_PATH]/flutter/bin\""