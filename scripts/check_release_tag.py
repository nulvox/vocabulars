#!/usr/bin/env python3
"""Validate a release tag and derive Flutter's Android version values."""

import argparse
import json
import re
import sys

TAG_RE = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")


def version(value):
    match = TAG_RE.fullmatch(value)
    if not match:
        raise ValueError(f"release tag must match vMAJOR.MINOR.PATCH, got {value!r}")
    return tuple(map(int, match.groups()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--existing-json", required=True, help="JSON array from gh release list")
    parser.add_argument("--write-pubspec", help="Update the pubspec version in this workspace")
    args = parser.parse_args()

    selected = version(args.tag)
    releases = json.loads(open(args.existing_json, encoding="utf-8").read())
    for release in releases:
        tag = release.get("tagName", "")
        if not tag:
            continue
        try:
            existing = version(tag)
        except ValueError:
            continue
        if selected <= existing:
            raise SystemExit(f"{args.tag} is not higher than existing release {tag}")

    # Android versionCode must be a positive integer. This monotonic mapping
    # leaves room for patch releases and is deterministic from the tag.
    major, minor, patch = selected
    build_number = major * 1_000_000 + minor * 1_000 + patch + 1
    version_string = f"{major}.{minor}.{patch}"
    if args.write_pubspec:
        path = open(args.write_pubspec, encoding="utf-8")
        content = path.read()
        path.close()
        updated = re.sub(r"^version: .*?$", f"version: {version_string}+{build_number}", content, count=1, flags=re.MULTILINE)
        if updated == content:
            raise SystemExit(f"could not find version in {args.write_pubspec}")
        with open(args.write_pubspec, "w", encoding="utf-8") as output:
            output.write(updated)
    print(f"version={version_string}")
    print(f"build_number={build_number}")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        print(error, file=sys.stderr)
        sys.exit(2)
