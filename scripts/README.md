# Audio Downloader Script

This script automatically downloads pronunciation audio from Wiktionary for vocabulary words defined in your project's configuration.

## Purpose

The script reads through the vocabulary configuration JSON file, identifies the language and spelling of each word, then downloads the appropriate audio pronunciation from Wiktionary. It follows specific language preferences:

- English: American > Canadian > UK > Australian
- French: France > Canadian
- Spanish: Mexican > Spain

## Requirements

- Python 3.6+
- Required Python packages:
  - requests
  - beautifulsoup4

Install requirements with:
```
pip install requests beautifulsoup4
```

## Usage

To use the script manually:

```bash
./scripts/download_audio.py
```

To integrate with your build process, add it as a pre-build step or use the provided `download_audio.sh` wrapper script.

## Configuration

The script uses these constants that can be modified at the top of the file:

- `VOCABULARY_PATH`: Path to your vocabulary JSON file (default: 'assets/vocabulary.json')
- `AUDIO_DIR`: Directory where audio files will be saved (default: 'assets/audio')
- `LANGUAGE_PREFERENCES`: Priority order for language accents

## Behavior

- The script creates necessary directories if they don't exist
- By default, it will overwrite existing audio files
- It logs information about the download process to the console
- If no audio is found for a specific word, a warning is logged

## Troubleshooting

If the script fails to find audio for certain words:
1. Check if the word exists on Wiktionary in the specified language
2. Verify your internet connection
3. Check the logs for specific error messages