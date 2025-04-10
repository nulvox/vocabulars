#!/bin/bash

# Clean build artifacts
echo "Cleaning previous build artifacts..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build with skip validation flag
echo "Building Android release with dependency validation skipped..."
flutter build apk --release --android-skip-build-dependency-validation

echo "Build completed. Check for any errors above."