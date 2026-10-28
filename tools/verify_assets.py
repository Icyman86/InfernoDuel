#!/usr/bin/env python3
"""Verify all 8 unedited originals extracted from the user's Character sheets.zip. No external packages."""
from pathlib import Path
import hashlib, json, sys
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'data/uploaded_character_sheets.json').read_text(encoding='utf-8'))
passed=0
for item in manifest['items']:
    path=(root/item['path']).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        print('MISSING:',item['source_filename'])
        continue
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    if digest!=item['sha256']:
        print('HASH MISMATCH:',item['source_filename'])
        continue
    print('OK:',item['source_filename'])
    passed+=1
print(f'{passed}/{len(manifest["items"])} OK')
sys.exit(0 if passed==len(manifest['items']) else 1)
