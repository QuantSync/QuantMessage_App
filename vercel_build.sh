#!/bin/bash
# Clone the Flutter repository (stable channel)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Get project dependencies
flutter pub get

# Ensure .env exists to prevent asset errors if referenced in pubspec.yaml
touch .env

# Build the Flutter web application
flutter build web --release
