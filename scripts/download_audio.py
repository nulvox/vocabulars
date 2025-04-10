#!/usr/bin/env python3
import json
import os
import sys
import argparse
import requests
from bs4 import BeautifulSoup
import re
from urllib.parse import quote
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Default constants
DEFAULT_VOCABULARY_PATH = 'assets/vocabulary.json'
DEFAULT_AUDIO_DIR = 'assets/audio'
USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36'

# Language preferences
LANGUAGE_PREFERENCES = {
    'en': ['us', 'ca', 'uk', 'au'],     # American, Canadian, UK, Australian
    'es': ['mx', 'es'],                 # Mexican, Spain
    'fr': ['fr', 'ca']                  # France, Canadian
}

# Language codes for Wiktionary
WIKTIONARY_LANG_CODES = {
    'en': 'en',
    'es': 'es',
    'fr': 'fr'
}

def ensure_directory_exists(directory):
    """Ensure that a directory exists, creating it if necessary."""
    if not os.path.exists(directory):
        os.makedirs(directory)
        logger.info(f"Created directory: {directory}")

def load_vocabulary(vocabulary_path):
    """Load vocabulary from the JSON file."""
    try:
        with open(vocabulary_path, 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        logger.error(f"Error loading vocabulary file: {e}")
        sys.exit(1)

def get_wiktionary_page_url(word, lang_code):
    """Get the Wiktionary page URL for a word in a specific language."""
    encoded_word = quote(word.lower())
    return f"https://{WIKTIONARY_LANG_CODES[lang_code]}.wiktionary.org/wiki/{encoded_word}"

def get_audio_urls(word, lang_code):
    """
    Get audio URLs from Wiktionary for a word in a specific language.
    Returns a list of tuples (audio_url, accent) sorted by preference.
    """
    page_url = get_wiktionary_page_url(word, lang_code)
    logger.info(f"Fetching Wiktionary page: {page_url}")
    
    headers = {'User-Agent': USER_AGENT}
    try:
        response = requests.get(page_url, headers=headers)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        logger.warning(f"Error fetching Wiktionary page for {word}: {e}")
        return []
    
    # Parse HTML
    soup = BeautifulSoup(response.text, 'html.parser')
    audio_elements = soup.select('audio source')
    
    if not audio_elements:
        logger.warning(f"No audio found for {word} in {lang_code}")
        return []
    
    audio_urls = []
    for element in audio_elements:
        src = element.get('src', '')
        if not src.startswith('http'):
            src = 'https:' + src if src.startswith('//') else src
        
        # Extract accent information from the URL
        url_parts = src.split('/')
        filename = url_parts[-1]
        accent_match = re.search(f'{lang_code}-([a-z]{{2}})-{word.lower()}', filename, re.IGNORECASE)
        
        if accent_match:
            accent = accent_match.group(1)
        else:
            # If no specific accent found, assume it's the default
            accent = WIKTIONARY_LANG_CODES[lang_code]
        
        audio_urls.append((src, accent))
    
    # Sort by language preference
    preferences = LANGUAGE_PREFERENCES.get(lang_code, [])
    
    def preference_key(item):
        url, accent = item
        try:
            return preferences.index(accent)
        except ValueError:
            return len(preferences)  # Put at the end if not in preferences
    
    return sorted(audio_urls, key=preference_key)

def download_audio(url, output_path):
    """Download audio file from URL and save it to output_path."""
    headers = {'User-Agent': USER_AGENT}
    try:
        response = requests.get(url, headers=headers, stream=True)
        response.raise_for_status()
        
        with open(output_path, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        
        logger.info(f"Downloaded audio to {output_path}")
        return True
    except requests.exceptions.RequestException as e:
        logger.warning(f"Error downloading audio: {e}")
        return False

def process_vocabulary(vocabulary_path, audio_dir, test_mode=False, force_update=False):
    """Process vocabulary and download audio files."""
    vocabulary = load_vocabulary(vocabulary_path)
    supported_languages = vocabulary.get('supportedLanguages', [])
    
    if test_mode:
        logger.info("Running in TEST MODE - will only process one item per language")
    # Track words for which we've already downloaded audio
    processed_words = {}
    
    # Track how many words were processed in test mode
    test_words_processed = {lang: 0 for lang in supported_languages}
    
    # Process each scene
    for scene in vocabulary.get('scenes', []):
        for item in scene.get('interactionPoints', []):
            # Process each translation
            for translation in item.get('translations', []):
                lang_code = translation.get('languageCode', '')
                word_text = translation.get('text', '')
                
                # In test mode, skip if we've already processed one word for this language
                if test_mode and test_words_processed.get(lang_code, 0) > 0:
                    continue
                    
                if not lang_code or not word_text or lang_code not in supported_languages:
                    continue
                
                # Skip if we've already processed this word in this language
                key = f"{lang_code}:{word_text.lower()}"
                if key in processed_words:
                    continue
                
                processed_words[key] = True
                
                # Get audio file path from the item
                audio_path = None
                for audio_file in item.get('audioFiles', []):
                    if audio_file.get('languageCode') == lang_code:
                        audio_path = audio_file.get('filePath')
                        break
                
                if not audio_path:
                    continue
                
                # In test mode, mark this language as processed
                if test_mode:
                    test_words_processed[lang_code] = 1
                    logger.info(f"TEST MODE: Processing {word_text} in {lang_code}")
                
                # Ensure directory exists
                full_audio_dir = os.path.join(audio_dir, lang_code)
                ensure_directory_exists(full_audio_dir)
                
                # Full path to save the audio file
                full_audio_path = os.path.join(audio_dir, audio_path)
                
                # Skip if the file already exists and we're not forcing an update
                if os.path.exists(full_audio_path) and not force_update:
                    logger.info(f"Audio file already exists for {word_text} in {lang_code} (use --force to update)")
                    continue
                
                # Get audio URLs
                audio_urls = get_audio_urls(word_text, lang_code)
                
                if audio_urls:
                    # Use the highest priority URL (first in the sorted list)
                    best_url, accent = audio_urls[0]
                    logger.info(f"Selected {accent} pronunciation for {word_text} in {lang_code}")
                    
                    # Download the audio file
                    success = download_audio(best_url, full_audio_path)
                    if not success:
                        logger.warning(f"Failed to download audio for {word_text} in {lang_code}")
                else:
                    logger.warning(f"No suitable audio found for {word_text} in {lang_code}")

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Download audio pronunciation files from Wiktionary based on vocabulary configuration.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument('-v', '--vocabulary',
                        default=DEFAULT_VOCABULARY_PATH,
                        help='Path to the vocabulary JSON file')
    
    parser.add_argument('-o', '--output-dir',
                        default=DEFAULT_AUDIO_DIR,
                        help='Directory to save audio files')
    
    parser.add_argument('-t', '--test',
                        action='store_true',
                        help='Test mode - only process one word per language')
    
    parser.add_argument('-f', '--force',
                        action='store_true',
                        help='Force update - redownload audio even if files exist')
    
    parser.add_argument('-d', '--debug',
                        action='store_true',
                        help='Enable debug logging')
    
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    # Set logging level
    if args.debug:
        logger.setLevel(logging.DEBUG)
    
    logger.info("Starting audio download script")
    logger.info(f"Vocabulary file: {args.vocabulary}")
    logger.info(f"Output directory: {args.output_dir}")
    
    if args.test:
        logger.info("Running in TEST MODE")
    
    if args.force:
        logger.info("Force update enabled - will redownload existing files")
    
    ensure_directory_exists(args.output_dir)
    process_vocabulary(args.vocabulary, args.output_dir, args.test, args.force)
    logger.info("Audio download complete")

if __name__ == "__main__":
    main()