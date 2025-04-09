# Vocabular: Interactive Vocabulary Learning App

A Flutter application designed to teach vocabulary through interactive scenes. This app allows users to explore images with interactive hotspots that provide vocabulary words in multiple languages, complete with audio pronunciation.

## Features

- **Cross-Platform**: Works on Android, desktop (Windows, macOS, Linux), and web browsers
- **Landscape Orientation**: Optimized for tablet and landscape device layouts (forced on mobile)
- **Interactive Scenes**: Tap on objects in images to learn vocabulary
- **Multilingual Support**: Learn vocabulary in multiple languages with translations
- **Audio Pronunciation**: Hear correct pronunciation of words in different languages
- **Custom Content**: Load your own vocabulary sets with custom images, audio, and JSON configuration
- **Unit Testing**: Comprehensive test suite for long-term maintainability

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- An IDE (e.g., VS Code, Android Studio)
- For Android development: Android SDK
- For desktop development: OS-specific dependencies (see platform-specific sections below)

### Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/vocabular.git
   cd vocabular
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Generate the necessary JSON serialization code:
   ```
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```
   flutter run --release
   ```

## Creating Custom Vocabulary Sets

The app loads vocabulary data from a JSON file along with associated images and audio files. You can create your own custom vocabulary sets by following this guide.

### Directory Structure

Create a directory with the following structure:

```
vocabulary_set/
├── vocabulary.json       # Main configuration file
├── images/               # Scene images
│   ├── scene1.jpg
│   ├── scene2.jpg
│   └── ...
└── audio/                # Audio pronunciation files
    ├── en/               # English audio files
    │   ├── word1.mp3
    │   └── ...
    ├── es/               # Spanish audio files
    │   ├── word1.mp3
    │   └── ...
    └── ...               # Other languages
```

### JSON Configuration Format

The `vocabulary.json` file should follow this format:

```json
{
  "title": "Your Vocabulary Set Title",
  "description": "Description of your vocabulary set",
  "supportedLanguages": ["en", "es", "fr"],
  "scenes": [
    {
      "id": "scene1",
      "name": "Scene 1 Name",
      "imagePath": "scene1.jpg",
      "interactionPoints": [
        {
          "id": "item1",
          "label": "Primary Label",
          "x": 0.5,  // X-coordinate (0.0 to 1.0, relative to image width)
          "y": 0.3,  // Y-coordinate (0.0 to 1.0, relative to image height)
          "audioFiles": [
            {
              "languageCode": "en",
              "filePath": "en/item1.mp3"
            },
            {
              "languageCode": "es",
              "filePath": "es/item1.mp3"
            }
          ],
          "translations": [
            {
              "languageCode": "en",
              "text": "English Word"
            },
            {
              "languageCode": "es",
              "text": "Spanish Word"
            },
            {
              "languageCode": "fr",
              "text": "French Word"
            }
          ]
        }
      ]
    }
  ]
}
```

### Image Requirements

- Images should be in JPG or PNG format
- Recommended resolution: 1920x1080 (16:9 aspect ratio)
- Keep file sizes reasonable (under 1MB per image if possible)

### Audio Requirements

- Audio files should be in MP3 format
- Keep recordings clear and concise
- Recommended length: 1-2 seconds per word
- File naming should match the vocabulary item ID

## Building for Different Platforms

### Android

1. Ensure you have the Android SDK installed and configured.
2. Connect an Android device or start an emulator.
3. Build and install the APK:
   ```
   flutter build apk --release
   flutter install
   ```

### Web

1. Build the web version:
   ```
   flutter build web --release
   ```
2. The built files will be in `build/web` directory.
3. Deploy these files to any web server or use Firebase Hosting, GitHub Pages, etc.

### Windows

1. Ensure you have the Windows development dependencies:
   ```
   flutter config --enable-windows-desktop
   ```
2. Build the Windows app:
   ```
   flutter build windows --release
   ```
3. The executable will be in `build/windows/runner/Release/`.

### macOS

1. Ensure you have the macOS development dependencies:
   ```
   flutter config --enable-macos-desktop
   ```
2. Build the macOS app:
   ```
   flutter build macos --release
   ```
3. The application will be in `build/macos/Build/Products/Release/`.

### Linux

1. Ensure you have the Linux development dependencies:
   ```
   flutter config --enable-linux-desktop
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
   ```
2. Build the Linux app:
   ```
   flutter build linux --release
   ```
3. The executable will be in `build/linux/x64/release/bundle/`.

## Building from Source

To generate the necessary JSON serialization code, run:

```
flutter pub run build_runner build --delete-conflicting-outputs
```

This step is required before running the app for the first time or after making changes to the model classes.

This will create the `scenes_model.g.dart` file which is needed for JSON parsing.

## Running Tests

To run all tests:

```
flutter test
```

To run tests with coverage:

```
flutter test --coverage
```

This will generate a coverage report in the `coverage/` directory. You can use tools like `lcov` to view the report:

```
# Install lcov if needed
# For Ubuntu/Debian: sudo apt-get install lcov
# For macOS: brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open the report
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

## Project Structure

- `/lib/models/` - Data models
- `/lib/screens/` - UI screens
- `/lib/widgets/` - Reusable UI components
- `/lib/services/` - Business logic and services
- `/lib/utils/` - Utility functions and constants
- `/assets/` - Static assets (images, audio, JSON)
- `/test/` - Unit and widget tests

## Technical Details

### State Management

The app uses Provider for state management, with the main state contained in the `VocabularyModel` class.

### Data Flow

1. The `VocabularyService` loads and parses the JSON configuration file
2. The parsed data is stored in the `VocabularyModel`
3. The UI components observe the model and update accordingly

### Customization Points

- `AppConstants` in `lib/utils/app_constants.dart` contains customizable values
- Theme colors can be adjusted in the `VocabularApp` class in `main.dart`
- Supported languages can be extended in the `languageNames` map in `app_constants.dart`

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Contributors to the packages used in this project

## Platform-Specific Notes

### Android
- The app is forced to landscape orientation on Android
- File picker is used to load vocabulary sets from device storage
- Android permissions required: storage access for loading custom vocabulary sets

### Web
- All assets are bundled and served from the web server
- Custom vocabulary loading is more limited on web due to browser security restrictions
- Performance may vary depending on the browser used

### Desktop (Windows, macOS, Linux)
- Full filesystem access for loading custom vocabulary sets
- Adaptive UI that works well at different window sizes
- Keyboard shortcuts for navigation (arrow keys)