#!/usr/bin/env python3
"""Safely copy original files into categorized reference folders. Never modifies source."""
from pathlib import Path
import json, shutil, hashlib
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'data/asset_manifest.json').read_text(encoding='utf8'))
upload=json.loads((ROOT/'data/uploaded_character_sheets.json').read_text(encoding='utf8'))
inputdir=ROOT/'assets/originals/_drop_files_here'
report=ROOT/'docs/ASSET_REPORT.md'
rows=[]
for uploaded in upload['items']:
    path=ROOT/uploaded['path']
    rows.append((uploaded['source_filename'], 'BUNDLED_VERIFIED_ORIGINAL' if path.is_file() else 'MISSING_BUNDLED', uploaded['path']))
for item in manifest['verified_library_items']:
    name=item['filename']; src=inputdir/name
    if item.get('included') and (ROOT/item.get('path','')).is_file():
        continue
    if not src.is_file():
        rows.append((name,'OPTIONAL_NOT_PROVIDED',''))
        continue
    cat=item['category']; fighter=item['fighter']
    if cat.startswith('ui') or cat.startswith('promo'):
        folder=ROOT/'assets/reference/ui'
    elif cat.startswith('gameplay'):
        folder=ROOT/'assets/reference/arenas'
    else:
        folder=ROOT/'assets/reference/characters'/fighter.lower().replace(' ','_')
    folder.mkdir(parents=True,exist_ok=True)
    dst=folder/name
    if dst.exists() and hashlib.sha256(dst.read_bytes()).digest()!=hashlib.sha256(src.read_bytes()).digest():
        rows.append((name,'CONFLICT_NOT_OVERWRITTEN',str(dst.relative_to(ROOT))))
    else:
        if not dst.exists(): shutil.copy2(src,dst)
        rows.append((name,'IMPORTED',str(dst.relative_to(ROOT))))
for item in manifest['extra_archives']:
    name=item['filename'];src=inputdir/name
    if src.exists():
        out=ROOT/'assets/originals/legacy'/name;out.parent.mkdir(parents=True,exist_ok=True)
        if not out.exists():shutil.copy2(src,out)
        rows.append((name,'LEGACY_IMPORTED',str(out.relative_to(ROOT))))
lines=['# Asset import report','','Status: source files are **never modified**.','','| Name | Status | Destination |','|---|---|---|']
lines += [f'| {n} | {s} | {d} |' for n,s,d in rows]
report.write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'Imported: {sum(s=="IMPORTED" for _,s,_ in rows)}; Missing: {sum(s=="OPTIONAL_NOT_PROVIDED" for _,s,_ in rows)}; Report: {report}')
