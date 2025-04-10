#!/bin/bash
# Simple wrapper for the audio downloader script that can be integrated into the build process

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT" || { echo "Failed to change to project root directory"; exit 1; }

echo "Checking for required Python packages..."
python3 -m pip install --quiet requests beautifulsoup4 || { 
    echo "Failed to install required Python packages."; 
    echo "Please install manually: pip install requests beautifulsoup4"; 
    exit 1; 
}

echo "Starting audio download process..."
python3 "$SCRIPT_DIR/download_audio.py"
RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "Audio download process completed successfully."
    exit 0
else
    echo "Audio download process failed with exit code $RESULT."
    exit $RESULT
fi