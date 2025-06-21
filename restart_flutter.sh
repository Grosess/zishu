#!/bin/bash
# Kill any existing flutter processes
pkill -f flutter

# Clean the build
cd /home/archer/zishu
flutter clean

# Run the app
flutter run -d web-server --web-port 5050