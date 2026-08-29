#!/usr/bin/env python3
"""Generate platform display metadata from the selected vocabulary JSON."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCABULARY = ROOT / "assets/vocabulary.json"


def replace(path: Path, pattern: str, replacement: str) -> None:
    text = path.read_text()
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise RuntimeError(f"Could not update {path}: pattern not found exactly once")
    path.write_text(updated)


def main() -> None:
    data = json.loads(VOCABULARY.read_text())
    title = data["title"]
    app_name = f"Vocabulars: {title}"

    # Web metadata is source-controlled as a template and refreshed per build.
    manifest = json.loads((ROOT / "web/manifest.json").read_text())
    manifest["name"] = app_name
    manifest["short_name"] = "Vocabulars"
    (ROOT / "web/manifest.json").write_text(json.dumps(manifest, indent=4) + "\n")
    replace(ROOT / "web/index.html", r"<meta name=\"description\" content=\"[^\"]*\">",
            f'<meta name="description" content="{app_name} - Interactive Vocabulary Learning App">')
    replace(ROOT / "web/index.html", r'<meta name="apple-mobile-web-app-title" content="[^"]*">',
            f'<meta name="apple-mobile-web-app-title" content="{app_name}">')
    replace(ROOT / "web/index.html", r"<title>[^<]*</title>", f"<title>{app_name}</title>")
    replace(ROOT / "web/index.html", r"Loading [^<]*\.\.\.", f"Loading {app_name}...")

    # Native targets consume their platform-native metadata, but its value is
    # generated from the same vocabulary document before every build.
    replace(ROOT / "macos/Runner/Configs/AppInfo.xcconfig",
            r"PRODUCT_NAME = .*", f"PRODUCT_NAME = {app_name}")
    replace(ROOT / "android/app/src/main/AndroidManifest.xml",
            r'android:label="[^"]*"', 'android:label="@string/app_name"')
    values = ROOT / "android/app/src/main/res/values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "app_name.xml").write_text(
        f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <string name="app_name">{app_name}</string>\n</resources>\n'
    )
    replace(ROOT / "ios/Runner/Info.plist",
            r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
            rf"\g<1>{app_name}\g<2>")
    replace(ROOT / "linux/runner/my_application.cc",
            r'(gtk_header_bar_set_title\(header_bar, )"[^"]*"',
            rf'\1"{app_name}"')
    replace(ROOT / "linux/runner/my_application.cc",
            r'(gtk_window_set_title\(window, )"[^"]*"',
            rf'\1"{app_name}"')
    replace(ROOT / "windows/runner/main.cpp",
            r'(window\.Create\(L")[^"]*"', rf'\1{app_name}"')

    # The Dart runtime title follows the vocabulary title as well; native
    # metadata is intentionally English and stable before Flutter starts.
    replace(ROOT / "lib/main.dart", r"title: '[^']*',",
            "title: 'Vocabulars: ${vocabularyModel.vocabularyData.title}',")
    print(f"generated app metadata for {app_name}")


if __name__ == "__main__":
    main()
