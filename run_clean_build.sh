#!/bin/bash
echo "Running flutter clean..."
flutter clean

echo "Getting packages..."
flutter pub get

echo "Build complete. Now run 'flutter run' to start the app."