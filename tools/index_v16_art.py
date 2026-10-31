"""Index V16 generated animation keys without editing image pixels.

The two user JPEGs remain byte-for-byte originals. PNGs are separately generated
reference-guided artwork, with alpha silhouettes indexed for Godot Polygon2D.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import ConvexHull

ROOT = Path(__file__).resolve().parent.parent
path = ROOT / 'data/sprite_atlases.json'
metadata = json.loads(path.read_text())
provenance_path = ROOT / 'data/visual_asset_provenance.json'
provenance = json.loads(provenance_path.read_text())
provenance['roster_update_date'] = '2026-10-31'
bust_path = ROOT / 'data/select_busts.json'
busts = json.loads(bust_path.read_text())
ultimate_path = 'assets/sprites/v16_ultimates.png'
ultimate_rgba = np.asarray(Image.open(ROOT / ultimate_path))
ultimate_labels, _ = ndimage.label(ultimate_rgba[:, :, 3] > 128)
ultimate_areas = np.bincount(ultimate_labels.ravel())
ultimate_areas[0] = 0
ultimate_keys = {}
for label in np.argsort(ultimate_areas)[-4:]:
    yy, xx = np.nonzero(ultimate_labels == label)
    group = int(yy.mean() > ultimate_rgba.shape[0]/2)*2 + int(xx.mean() > ultimate_rgba.shape[1]/2)
    assert group not in ultimate_keys
    points = np.column_stack((xx, yy))
    hull = points[ConvexHull(points).vertices].astype(float)
    left, top = points.min(axis=0)
    right, bottom = points.max(axis=0)+1
    body_height = int(bottom-top)
    torso = (yy > bottom-body_height*.72) & (yy < bottom-body_height*.47)
    center = float(np.median(xx[torso])) if torso.any() else float(np.median(xx))
    ultimate_keys[group] = {'rect': [int(left),int(top),int(right-left),body_height],
                            'pivot': [round(center-left,2),body_height-1],
                            'polygon': np.round(hull-[left,top],2).tolist()}
assert len(ultimate_keys) == 4

for identity, name in [('bamboo_blade', 'Bamboo Blade'), ('sawtina', 'Sawtina')]:
    relative = f'assets/sprites/{identity}/atlas.png'
    rgba = np.asarray(Image.open(ROOT / relative))
    assert rgba.shape[2] == 4 and (rgba[:, :, 3] == 0).mean() > .2
    height, width = rgba.shape[:2]
    frames, body_heights = [], []
    for cell in range(24):
        x0, x1 = cell % 4 * width // 4, (cell % 4 + 1) * width // 4
        y0, y1 = cell // 4 * height // 6, (cell // 4 + 1) * height // 6
        alpha = rgba[y0:y1, x0:x1, 3]
        labels, count = ndimage.label(alpha > 160)
        areas = np.bincount(labels.ravel())
        areas[0] = 0
        assert count > 0 and areas.max() > 2000, (identity, cell, 'missing body')
        yy, xx = np.nonzero(labels == areas.argmax())
        ground = int(yy.max())
        body_height = int(yy.max() - yy.min() + 1)
        torso = (yy > ground - body_height * .72) & (yy < ground - body_height * .47)
        center = float(np.median(xx[torso])) if torso.any() else float(np.median(xx))
        # The opaque body defines the anchor; translucent blade/fruit effects
        # stay visible inside a convex alpha envelope of the complete cell.
        py, px = np.nonzero(alpha > 32)
        points = np.column_stack((px, py))
        hull = points[ConvexHull(points).vertices].astype(float)
        delta = hull - hull.mean(axis=0)
        hull += delta / np.maximum(np.linalg.norm(delta, axis=1)[:, None], 1) * 1.0
        hull[:, 0] = np.clip(hull[:, 0], 0, x1-x0-1)
        hull[:, 1] = np.clip(hull[:, 1], 0, y1-y0-1)
        frames.append({'rect': [x0, y0, x1-x0, y1-y0],
                       'pivot': [round(center, 2), ground],
                       'polygon': np.round(hull, 2).tolist()})
        if cell < 2:
            body_heights.append(body_height)
    animations = {
        'idle': {'frames': [0, 1], 'fps': 3},
        'walk': {'frames': list(range(2, 8)), 'fps': 10},
        'light': {'frames': [8, 9, 10, 11], 'fps': 14},
        'heavy': {'frames': [12, 13, 14, 15],
                  'times': [0, .30, .45, .76], 'contact_frame': 2, 'fps': 12},
        'guard': {'frames': [16]}, 'jump': {'frames': [17]},
        'special': {'frames': [18, 19], 'times': [0, .45], 'fps': 8},
        'ultimate': {'frames': [20, 21], 'times': [0, .45], 'fps': 8},
        'hit': {'frames': [22]}, 'ko': {'frames': [23]},
    }
    metadata[identity] = {'core': {'path': relative, 'frames': frames},
                          'base_height': sum(body_heights)/2,
                          'animations': animations, 'unique_frame_count': 26}
    first = 0 if identity == 'bamboo_blade' else 2
    ultimate_frames = [ultimate_keys[first],ultimate_keys[first+1]]
    metadata[identity]['ultimate_keys'] = {'path':ultimate_path,'frames':ultimate_frames,
        'scale':metadata[identity]['base_height'] / np.mean([f['rect'][3] for f in ultimate_frames])}
    metadata[identity]['animations']['ultimate'] = {'atlas':'ultimate_keys','frames':[0,1],'times':[0,.45],'fps':8}
    intro = f'assets/intros/{identity}_poses.png'
    w, h = Image.open(ROOT / intro).size
    busts['profiles'][identity] = {'path': intro, 'rect': [0, 0, w//2, h//2],
                                  'kind': 'reference-guided cinematic half-body painting'}
    for asset, kind in [(relative, 'reference_guided_generated_combat_animation_atlas'),
                        (intro, 'reference_guided_generated_cinematic_views')]:
        provenance['derived_assets'] = [p for p in provenance['derived_assets'] if p['path'] != asset]
        provenance['derived_assets'].append({
            'path': asset, 'sha256': hashlib.sha256((ROOT/asset).read_bytes()).hexdigest(),
            'kind': kind, 'reference': f'assets/originals/character_sheets_2026-10-31/{name}.jpg',
            'original_user_file': False, 'date': '2026-10-31',
            'notes': 'Separate generated artwork. Original user JPEG preserved; PNG pixels unchanged by indexer.'})
    print(identity, '24 core keys + 2 unclipped ultimate keys; all ten animation states')

provenance['derived_assets'] = [p for p in provenance['derived_assets'] if p['path'] != ultimate_path]
provenance['derived_assets'].append({'path':ultimate_path,
    'sha256':hashlib.sha256((ROOT/ultimate_path).read_bytes()).hexdigest(),
    'kind':'reference_guided_generated_supplemental_ultimate_keys',
    'references':['assets/originals/character_sheets_2026-10-31/Bamboo Blade.jpg','assets/originals/character_sheets_2026-10-31/Sawtina.jpg'],
    'original_user_file':False,'date':'2026-10-31',
    'notes':'Four complete high-resolution silhouettes without baked energy borders; alpha components indexed across nominal cell boundaries, PNG pixels unchanged.'})
path.write_text(json.dumps(metadata, indent=2)+'\n')
bust_path.write_text(json.dumps(busts, indent=2)+'\n')
provenance_path.write_text(json.dumps(provenance, indent=2)+'\n')
