#!/usr/bin/env python3
"""Generate bundled pronunciations with Google Cloud Text-to-Speech.

Authentication uses Application Default Credentials. Set
GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON file (or configure
ADC with gcloud) before running this script. Credentials are never read by the
Flutter app and must not be committed.
"""

import argparse
import base64
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

import requests

CLOUD_API_URL = "https://texttospeech.googleapis.com/v1/text:synthesize"
TRANSLATE_API_URL = "https://translate.google.com/translate_tts"
SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]
DEFAULT_VOICES = {
    "en": {"languageCode": "en-US", "name": "en-US-Neural2-F"},
    "es": {"languageCode": "es-ES", "name": "es-ES-Neural2-A"},
    "fr": {"languageCode": "fr-FR", "name": "fr-FR-Neural2-A"},
}


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vocabulary", type=Path, default=Path("assets/vocabulary.json"))
    parser.add_argument("--output-dir", type=Path, default=Path("assets/audio"))
    parser.add_argument("--metadata", type=Path, default=Path("assets/audio/manifest.json"))
    parser.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    parser.add_argument("--language", action="append", dest="languages")
    parser.add_argument("--word", help="Only generate the interaction-point ID")
    parser.add_argument("--force", action="store_true", help="Regenerate existing files")
    parser.add_argument("--dry-run", action="store_true", help="List work without calling Google")
    parser.add_argument(
        "--provider",
        choices=["translate", "cloud"],
        default="translate",
        help="TTS provider (translate needs no login; cloud uses Google ADC)",
    )
    parser.add_argument(
        "--update-json",
        action="store_true",
        help="Update audio file paths to stable language/interaction-point filenames",
    )
    return parser.parse_args()


def stable_path(point_id, language):
    safe_id = re.sub(r"[^A-Za-z0-9_.-]+", "_", point_id).strip("._")
    if not safe_id:
        raise ValueError(f"Interaction point has an unusable ID: {point_id!r}")
    return f"{language}/{safe_id}.mp3"


def collect_items(data, languages=None, word=None):
    allowed = set(languages or data["supportedLanguages"])
    items = []
    for scene in data.get("scenes", []):
        for point in scene.get("interactionPoints", []):
            if word and point["id"] != word:
                continue
            translations = {t["languageCode"]: t["text"] for t in point.get("translations", [])}
            for language in data["supportedLanguages"]:
                if language in allowed and language in translations and translations[language].strip():
                    items.append((point, language, translations[language].strip()))
    return items


def validate_mp3(audio, relative):
    # Google normally returns an ID3 header, but some encoders begin directly
    # with an MPEG frame. Reject empty/truncated responses before replacing a
    # previously valid pronunciation.
    if len(audio) < 128 or not (audio.startswith(b"ID3") or audio[0] == 0xFF):
        raise RuntimeError(f"Google returned invalid MP3 data for {relative}")


def write_atomic(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("wb", dir=path.parent, delete=False) as tmp:
        tmp.write(content)
        temporary = Path(tmp.name)
    temporary.replace(path)


def update_pubspec(pubspec, paths):
    # The recursive assets/audio/ entry already includes generated files.
    # Do not add individual MP3 paths: generated audio is intentionally
    # ignored by Git, and explicit paths make CI fail on a clean checkout.
    return


def main():
    args = parse_args()
    data = json.loads(args.vocabulary.read_text(encoding="utf-8"))
    items = collect_items(data, args.languages, args.word)
    unknown = sorted({language for _, language, _ in items} - DEFAULT_VOICES.keys())
    if unknown:
        raise SystemExit(f"No default voice configured for: {', '.join(unknown)}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    metadata = {}
    if args.metadata.exists():
        metadata = json.loads(args.metadata.read_text(encoding="utf-8"))

    session = None
    if not args.dry_run and any(args.force or not (args.output_dir / stable_path(p["id"], lang)).exists() for p, lang, _ in items):
        if args.provider == "cloud":
            # Import only when requested so the no-login provider stays simple.
            import google.auth
            from google.auth.transport.requests import AuthorizedSession
            credentials, _ = google.auth.default(scopes=SCOPES)
            session = AuthorizedSession(credentials)
        else:
            session = requests.Session()

    generated = 0
    skipped = 0
    generated_paths = set()
    for point, language, text in items:
        relative = stable_path(point["id"], language)
        output = args.output_dir / relative
        generated_paths.add(f"assets/audio/{relative}")
        voice = DEFAULT_VOICES[language]
        voice_label = voice["name"] if args.provider == "cloud" else "Google Translate default voice"
        if output.exists() and not args.force:
            skipped += 1
        elif args.dry_run:
            print(f"would generate {relative}: {text!r} ({voice_label})")
        else:
            if args.provider == "translate":
                response = session.get(
                    TRANSLATE_API_URL,
                    params={"ie": "UTF-8", "client": "tw-ob", "tl": voice["languageCode"].split("-")[0], "q": text},
                    headers={"User-Agent": "Mozilla/5.0"},
                    timeout=60,
                )
                response.raise_for_status()
                decoded_audio = response.content
            else:
                response = session.post(CLOUD_API_URL, json={
                    "input": {"text": text},
                    "voice": voice,
                    "audioConfig": {"audioEncoding": "MP3", "speakingRate": 0.9},
                }, timeout=60)
                response.raise_for_status()
                audio = response.json().get("audioContent")
                if not audio:
                    raise RuntimeError(f"Google returned no audio for {point['id']} ({language})")
                decoded_audio = base64.b64decode(audio)
            validate_mp3(decoded_audio, relative)
            write_atomic(output, decoded_audio)
            print(f"generated {relative}: {text!r} ({voice_label})")
            generated += 1

        metadata[relative] = {
            "provider": "Google Translate TTS" if args.provider == "translate" else "Google Cloud Text-to-Speech",
            "voice": voice_label,
            "languageCode": voice["languageCode"],
            "text": text,
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "format": "MP3",
            "api": "Google Cloud Text-to-Speech v1",
        }
        if args.update_json:
            for audio in point.setdefault("audioFiles", []):
                if audio.get("languageCode") == language:
                    audio["filePath"] = relative
                    break
            else:
                point.setdefault("audioFiles", []).append({"languageCode": language, "filePath": relative})

    if not args.dry_run:
        write_atomic(args.metadata, json.dumps(metadata, indent=2, ensure_ascii=False).encode() + b"\n")
        if args.update_json:
            write_atomic(args.vocabulary, json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
            update_pubspec(args.pubspec, generated_paths)
    print(f"done: {generated} generated, {skipped} skipped, {len(items)} requested")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        if error.__class__.__name__ == "DefaultCredentialsError":
            print(f"Google credentials unavailable: {error}", file=sys.stderr)
            print("Use the default translate provider, or configure GOOGLE_APPLICATION_CREDENTIALS for --provider cloud.", file=sys.stderr)
            sys.exit(2)
        raise
