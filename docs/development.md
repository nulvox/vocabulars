# Development workflow

Enter the reproducible shell before using Flutter or the audio tools:

```bash
nix develop
flutter pub get
flutter test
flutter build web --release
```

The Nix flake pins the nixpkgs revision through `flake.lock` and supplies the
Flutter SDK, Python, audio-generation dependencies, and Linux desktop build
libraries. Update the lock file deliberately with `nix flake update` and verify
that the selected Flutter version still satisfies `pubspec.yaml`.

## Vocabulary and audio

Validate the content without making network requests:

```bash
python scripts/validate_vocabulary.py
```

Generate or refresh bundled audio with the no-login provider:

```bash
python scripts/generate_audio.py --dry-run
python scripts/generate_audio.py --update-json
python scripts/validate_vocabulary.py --require-audio
```

Audio is generated content and is intentionally ignored by Git. A release
pipeline or local build must generate it before building a distributable app.
The manifest is retained as provenance, while MP3 files are build artifacts.
The generator uses stable interaction-point IDs for filenames and updates the
asset list automatically.

## CI expectations

Pull requests run vocabulary validation, Flutter tests, static analysis, a web
release build, and Nix flake evaluation. CI does not call the public TTS
endpoint. Release jobs should run the generation step separately, review the
result, and then run validation with `--require-audio`.

## Data model direction

Interaction-point IDs are the canonical identity for translations and audio.
Audio paths should remain derived as `<language>/<id>.mp3`; translated text may
change without orphaning old files. A future schema migration can represent
translations as a language-keyed map, but the current JSON shape remains
supported to avoid a needless content-only migration.
