#!/usr/bin/env python3
"""Select a vocabulary config for the next build."""
import argparse, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('config', type=Path, help='Config JSON, e.g. configs/bestiary.json')
a = p.parse_args()
source = a.config if a.config.is_absolute() else ROOT / a.config
if not source.exists():
    raise SystemExit(f'Config not found: {source}')
data = json.loads(source.read_text(encoding='utf-8'))
if not isinstance(data.get('title'), str) or not data['title'].strip():
    raise SystemExit('Config must contain a non-empty title')
(ROOT / 'assets/vocabulary.json').write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
print(f'selected {source.relative_to(ROOT)}: {data["title"]}')
