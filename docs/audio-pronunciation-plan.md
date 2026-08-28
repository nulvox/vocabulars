# Pronunciation audio plan

## Current behavior

The vocabulary JSON describes the expected audio files, but those files are not
necessarily present in `assets/audio/`. The app now checks the bundled asset
when a vocabulary card opens and shows **Pronunciation not available yet**
up-front instead of presenting a Listen button that fails only after being
pressed.

## Recommended generation pipeline

The default generator uses the Google Translate TTS endpoint, so it needs no
login or credentials. This is an unofficial endpoint and may be rate-limited or
changed by Google. For a more stable production pipeline, the generator also
supports Google Cloud Text-to-Speech with `--provider cloud`; that mode requires
credentials.

The implemented `scripts/generate_audio.py` does the following:

1. Read `assets/vocabulary.json`.
2. Collect each unique `(languageCode, translation)` pair.
3. Select a deliberate neural voice per language (for example `en-US`,
   `es-ES` or `es-MX`, and `fr-FR`) from a checked-in configuration file.
4. Call Google Translate TTS by default (or Google Cloud Text-to-Speech with
   `--provider cloud`) and write MP3 output to
   `assets/audio/<language>/<stable-id>.mp3` through a temporary file and
   atomic rename.
5. Write a small metadata manifest containing provider, voice, language,
   source text, generation timestamp, and API/model version. This makes voice
   changes auditable and avoids silently replacing good recordings.
6. Skip existing files unless `--force` is supplied, and support `--dry-run`
   and a single-language/single-word filter.
7. Run an audio validation step (file type, non-zero duration, and a playable
   header) before updating the manifest.

The JSON should eventually reference generated files by stable vocabulary item
ID rather than a translated spelling, so changing punctuation or accents does
not orphan old audio. A provider abstraction would also allow a local engine
such as Piper or manually recorded files as a fallback.

Usage:

```text
# Inspect what would be generated; this does not require credentials.
python scripts/generate_audio.py --dry-run

# Generate missing MP3 files, update vocabulary.json and pubspec.yaml;
# no login required.
python scripts/generate_audio.py --update-json

# Optional: use the authenticated Cloud API instead.
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json \
  python scripts/generate_audio.py --provider cloud --update-json
```

Use `--language en`, `--word layered_sofa`, or `--force` to narrow or repeat a
run. The optional Cloud provider uses Google Application Default Credentials;
`google-auth` is supplied by the Nix development shell.

Generated audio should be reviewed for pronunciation and licensing before it
is committed or distributed.
