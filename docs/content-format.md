# Vocabulary content format

Vocabular loads a JSON document plus images and audio from the Flutter asset
bundle. The sample document is `assets/vocabulary.json` and is the best
starting point for a new content set.

## Directory layout

```text
assets/
├── vocabulary.json
├── images/
│   ├── living_room.jpg
│   └── optional.svg
└── audio/
    ├── en/<id>.mp3
    ├── es/<id>.mp3
    └── fr/<id>.mp3
```

Image files may be JPG, PNG, WEBP, or SVG. Use reasonably sized images; a
1920×1080 source is a good default for scene backgrounds. Audio is MP3 and is
referenced by language and stable interaction-point ID.

## Document shape

At the top level provide a title, description, optional localized title
translations, supported language codes, and scenes:

```json
{
  "title": "The House",
  "description": "Common objects around the home",
  "titleTranslations": [
    {"languageCode": "en", "text": "The House"},
    {"languageCode": "es", "text": "La Casa"},
    {"languageCode": "fr", "text": "La Maison"}
  ],
  "supportedLanguages": ["en", "es", "fr"],
  "scenes": []
}
```

Each scene has an ID, name, and either one `imagePath` or multiple
`imageLayers`. Interaction points use normalized coordinates (`x` and `y` from
0.0 to 1.0), a stable ID, translations, and optional audio entries:

```json
{
  "id": "bedroom",
  "name": "Bedroom",
  "imagePath": "bedroom.jpg",
  "interactionPoints": [
    {
      "id": "bed",
      "label": "Bed",
      "x": 0.5,
      "y": 0.6,
      "audioFiles": [
        {"languageCode": "en", "filePath": "en/bed.mp3"},
        {"languageCode": "es", "filePath": "es/bed.mp3"},
        {"languageCode": "fr", "filePath": "fr/bed.mp3"}
      ],
      "translations": [
        {"languageCode": "en", "text": "Bed", "ipa": "bɛd"},
        {"languageCode": "es", "text": "Cama"},
        {"languageCode": "fr", "text": "Lit"}
      ]
    }
  ]
}
```

Every interaction-point ID must be unique across the document. Keep IDs stable:
they are used to name generated audio files. Each supported language should
have a translation. The optional `ipa` field is shown in the hotspot card as
an International Phonetic Alphabet pronunciation. Audio may be absent, in
which case the app displays an explicit unavailable state.

## Layered scenes

For scenes assembled from multiple images, use `imageLayers` instead of
`imagePath`:

```json
{
  "id": "kitchen",
  "name": "Kitchen",
  "imageLayers": [
    {
      "id": "background",
      "imagePath": "kitchen.jpg",
      "opacity": 1.0,
      "x": 0.0,
      "y": 0.0,
      "scale": 1.0,
      "zIndex": 1
    }
  ],
  "interactionPoints": []
}
```

Layer offsets use normalized coordinates. `opacity` ranges from 0.0 to 1.0,
`scale` defaults to 1.0, and larger `zIndex` values render on top.

## Validate and generate

From the repository root:

```bash
nix develop
python scripts/validate_vocabulary.py
python scripts/generate_audio.py --dry-run
python scripts/generate_audio.py --update-json
python scripts/validate_vocabulary.py --require-audio
```

The generator updates the JSON paths and local Flutter asset list. Generated
MP3s are ignored by Git, so release or deployment builds must generate them
before building. See [Development workflow](development.md) and the
[pronunciation plan](audio-pronunciation-plan.md) for the complete workflow.
