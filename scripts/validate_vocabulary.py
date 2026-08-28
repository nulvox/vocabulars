#!/usr/bin/env python3
"""Validate vocabulary structure and audio references without network access."""

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vocabulary", type=Path, default=Path("assets/vocabulary.json"))
    parser.add_argument("--audio-dir", type=Path, default=Path("assets/audio"))
    parser.add_argument("--require-audio", action="store_true", help="Require every referenced MP3 to exist")
    args = parser.parse_args()

    data = json.loads(args.vocabulary.read_text(encoding="utf-8"))
    languages = set(data.get("supportedLanguages", []))
    if not languages:
        raise SystemExit("No supported languages configured")

    ids = set()
    errors = []
    references = set()
    for scene in data.get("scenes", []):
        for point in scene.get("interactionPoints", []):
            point_id = point.get("id")
            if not point_id or point_id in ids:
                errors.append(f"duplicate or missing interaction-point ID: {point_id!r}")
            ids.add(point_id)
            translations = {item.get("languageCode"): item.get("text", "") for item in point.get("translations", [])}
            for language in languages:
                if not translations.get(language, "").strip():
                    errors.append(f"{point_id}: missing translation for {language}")
            for audio in point.get("audioFiles", []):
                language = audio.get("languageCode")
                path = audio.get("filePath", "")
                if language not in languages:
                    errors.append(f"{point_id}: audio uses unsupported language {language!r}")
                if not path or Path(path).name != f"{point_id}.mp3":
                    errors.append(f"{point_id}: audio path should end in {point_id}.mp3")
                references.add(path)
                if args.require_audio and not (args.audio_dir / path).is_file():
                    errors.append(f"{point_id}: missing audio file {args.audio_dir / path}")

    if errors:
        raise SystemExit("\n".join(errors))
    print(f"vocabulary valid: {len(ids)} interaction points, {len(references)} audio references")


if __name__ == "__main__":
    main()
