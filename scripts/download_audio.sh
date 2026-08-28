#!/bin/bash
# Simple wrapper for the audio downloader script that can be integrated into the build process

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT" || { echo "Failed to change to project root directory"; exit 1; }

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to download audio." >&2
    exit 1
fi

if ! python3 -c 'import requests, bs4' >/dev/null 2>&1; then
    echo "Missing Python dependencies: requests and beautifulsoup4." >&2
    echo "Install them in a project virtual environment (or use your system/Nix environment);" >&2
    echo "this script intentionally does not modify your global Python installation." >&2
    exit 1
fi

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