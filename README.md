# Vocabular

Vocabular is a Flutter app for learning vocabulary through interactive scenes.
Select a scene, tap an object, and see its translations and pronunciation. The
sample content covers household objects in English, Spanish, and French.

## Features

- Interactive image scenes with vocabulary hotspots
- Multiple languages and translations
- Bundled pronunciation audio when generated content is available
- Web, Android, iOS, Linux, macOS, and Windows targets
- Custom vocabulary sets

## Get started

### With Nix (recommended on NixOS and Linux)

The repository includes a reproducible development shell:

```bash
nix develop
flutter pub get
flutter test
flutter run
```

### With an existing Flutter installation

Use Flutter 3 or newer with Dart 3 or newer:

```bash
git clone https://github.com/nulvox/vocabulars.git
cd vocabulars
flutter pub get
flutter run
```

Run the app in a browser with:

```bash
flutter run -d chrome
```

## Build

```bash
flutter build web --release
flutter build apk --release
```

The web output is written to `build/web`. Serve that directory with any static
web server. Platform-specific builds may require the corresponding SDK and
native build tools.

## Content and audio

The checked-in sample is in `assets/vocabulary.json`. To create scenes,
translations, images, and audio for a custom vocabulary set, see
[Content format](docs/content-format.md).

Audio is generated during content preparation rather than at runtime. The
no-login default uses the Google Translate TTS endpoint:

```bash
nix develop
python scripts/generate_audio.py --dry-run
python scripts/generate_audio.py --update-json
python scripts/validate_vocabulary.py --require-audio
```

Generated MP3 files are intentionally ignored by Git. See the
[pronunciation plan](docs/audio-pronunciation-plan.md) for provider details,
review guidance, and the optional authenticated Cloud TTS provider.

## Development

Run the full local checks with:

```bash
nix flake check --no-build
flutter analyze --no-fatal-infos
flutter test
```

See [Development workflow](docs/development.md) for the Nix environment,
content validation, audio generation, CI expectations, and data-model guidance.

If model classes change, regenerate the serializer:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project layout

- `lib/` — application code
- `assets/` — sample vocabulary and images
- `scripts/` — content and audio tooling
- `docs/` — detailed contributor and content documentation
- `test/` — unit and widget tests

## Contributing

Create a branch, run the checks above, and open a pull request. Changes to
content should include validation and, where appropriate, a review of generated
pronunciations.

## License

Vocabular is licensed under the [MIT License](LICENSE).
