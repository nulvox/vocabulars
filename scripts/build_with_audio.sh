#!/bin/bash
# Script to run the audio downloader before building the Flutter app
# Usage: ./scripts/build_with_audio.sh [flutter_build_arguments]
# Example: ./scripts/build_with_audio.sh build apk

# Stop on first error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT" || { echo "Failed to change to project root directory"; exit 1; }

echo "=== Starting audio download process ==="
"$SCRIPT_DIR/download_audio.sh"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Error: Audio download failed. Aborting build."
    exit 1
fi
echo "=== Audio download completed successfully ==="

# If any arguments were passed, use them to run flutter build
if [ $# -gt 0 ]; then
    echo "=== Starting Flutter build process ==="
    flutter "$@"
    echo "=== Flutter build completed ==="
else
    echo "No Flutter build commands provided."
    echo "To build the app, you can pass Flutter build arguments:"
    echo "Example: ./scripts/build_with_audio.sh build apk"
fi