"""Index generated 4x6 RGBA combat atlases without changing image pixels.

Optional authoring dependencies: Pillow, NumPy and SciPy. Transparent cell
silhouettes are isolated into mesh metadata; original reference sheets are never
read as animation frames or written by this tool.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import ConvexHull

roster = json.loads(Path('data/fighters.json').read_text())['fighters']
metadata_path = Path('data/sprite_atlases.json')
metadata = json.loads(metadata_path.read_text())
provenance_path = Path('data/visual_asset_provenance.json')
provenance = json.loads(provenance_path.read_text())
provenance['roster_update_date'] = '2026-10-29'
for id in ['nachtelf', 'spinegrin', 'lava_stone', 'crystal_fang', 'phoenix_reign']:
    path = Path('assets/sprites') / id / 'atlas.png'
    image = np.asarray(Image.open(path))
    assert image.shape[2] == 4 and image[:, :, 3].min() == 0, (id, 'missing alpha')
    height, width = image.shape[:2]
    frames = []
    body_heights = []
    for index in range(24):
        x0, x1 = (index % 4) * width // 4, (index % 4 + 1) * width // 4
        y0, y1 = (index // 4) * height // 6, (index // 4 + 1) * height // 6
        alpha = image[y0:y1, x0:x1, 3]
        labels, count = ndimage.label(alpha > 160)
        areas = np.bincount(labels.ravel())
        areas[0] = 0
        assert count and areas.max() > 2000, (id, index, 'missing body')
        body = labels == areas.argmax()
        yy, xx = np.nonzero(body)
        points = np.column_stack((xx, yy))
        hull = points[ConvexHull(points).vertices].astype(float)
        center = hull.mean(axis=0)
        delta = hull - center
        hull += delta / np.maximum(np.linalg.norm(delta, axis=1)[:, None], 1) * 1.2
        hull[:, 0] = np.clip(hull[:, 0], 0, x1 - x0 - 1)
        hull[:, 1] = np.clip(hull[:, 1], 0, y1 - y0 - 1)
        frames.append({'rect': [x0, y0, x1-x0, y1-y0],
                       'pivot': [(x1-x0)/2, int(yy.max())],
                       'polygon': np.round(hull, 2).tolist()})
        if index < 2:
            body_heights.append(int(yy.max()-yy.min()+1))
    animations = {
        'idle': {'frames': [0, 1, 0], 'fps': 5},
        'walk': {'atlas': 'walk', 'frames': list(range(6)), 'fps': 11},
        'light': {'frames': [8, 9, 10, 11], 'fps': 14},
        'heavy': {'frames': [12, 13, 14, 15], 'fps': 12},
        'guard': {'atlas': 'actions', 'frames': [0]},
        'jump': {'atlas': 'actions', 'frames': [1]},
        'special': {'atlas': 'actions', 'frames': [2, 2, 3, 3, 2]},
        'ultimate': {'atlas': 'actions', 'frames': [4, 4, 5, 5, 5]},
        'hit': {'atlas': 'actions', 'frames': [6]},
        'ko': {'atlas': 'actions', 'frames': [7]},
    }
    metadata[id] = {
        'core': {'path': str(path), 'frames': frames[:16]},
        'actions': {'path': str(path), 'frames': frames[16:]},
        'walk': {'path': str(path), 'frames': frames[2:8]},
        'base_height': sum(body_heights)/len(body_heights),
        'animations': animations, 'unique_frame_count': 24,
    }
    profile = next(f for f in roster if f['id'] == id)
    provenance['derived_assets'] = [p for p in provenance['derived_assets'] if p['path'] != str(path)]
    provenance['derived_assets'].append({
        'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'kind': 'reference_guided_generated_combat_animation_atlas',
        'reference': profile['reference_art_path'], 'original_user_file': False,
        'grid': [4, 6], 'unique_poses': 24,
        'notes': 'New illustrated keys, not extracted original animation. Meshes isolate alpha silhouettes within grid cells; six-key gait and short pose blending supply motion.',
    })
    print(id, '24 indexed alpha poses, six-key gait, base height', metadata[id]['base_height'])
for id in ['spinegrin', 'lava_stone', 'crystal_fang', 'phoenix_reign']:
    path = Path('assets/sprites') / id / 'extra.png'
    image = np.asarray(Image.open(path))
    height, width = image.shape[:2]
    mask = image[:, :, 3] > 160
    # Spinegrin's two unused low-swipe keys touch at the soles. Separate their
    # metadata ownership at that contact, without changing any source pixels.
    if id == 'spinegrin':
        mask[height//2:, int(width*.234)] = False
    labels, _ = ndimage.label(mask)
    areas = np.bincount(labels.ravel())
    frames = [None] * 8
    heights = []
    for label, box in enumerate(ndimage.find_objects(labels), 1):
        if box is None or areas[label] < 5000:
            continue
        ys, xs = box
        yy, xx = np.nonzero(labels[ys, xs] == label)
        xx, yy = xx + xs.start, yy + ys.start
        group = min(3, int(xx.mean() * 4 / width)) + (4 if yy.mean() > height/2 else 0)
        assert frames[group] is None, (id, group, 'ambiguous sprite')
        points = np.column_stack((xx, yy))
        left, top = points.min(axis=0)
        right, bottom = points.max(axis=0) + 1
        hull = points[ConvexHull(points).vertices].astype(float)
        center = hull.mean(axis=0)
        delta = hull-center
        hull += delta / np.maximum(np.linalg.norm(delta, axis=1)[:, None], 1) * 1.0
        hull[:, 0] = np.clip(hull[:, 0], left, right-1)
        hull[:, 1] = np.clip(hull[:, 1], top, bottom-1)
        foot_x = float(np.median(xx[yy >= bottom-7]))
        frames[group] = {'rect': [int(left), int(top), int(right-left), int(bottom-top)],
                         'pivot': [round(foot_x-left, 2), int(bottom-top-1)],
                         'polygon': np.round(hull - [left, top], 2).tolist()}
        if group < 2:
            heights.append(int(bottom-top))
    assert all(frames), (id, 'missing supplemental animation key')
    metadata[id]['extra'] = {'path': str(path), 'frames': frames,
                             'scale': metadata[id]['base_height'] / (sum(heights)/len(heights))}
    metadata[id]['animations']['heavy'] = {'atlas': 'extra', 'frames': [0, 1, 2, 3]}
    metadata[id]['unique_frame_count'] = 32
    if id in ['lava_stone', 'crystal_fang']:
        metadata[id]['animations']['strike'] = {'frames': [12, 13, 14, 15]}
        metadata[id]['animations']['slam'] = {'atlas': 'extra', 'frames': [4, 5, 5, 4]}
        metadata[id]['animations']['power'] = {'atlas': 'extra', 'frames': [6, 6, 7, 7]}
    if id == 'phoenix_reign':
        metadata[id]['animations']['peck'] = {'frames': [0, 1, 1, 0]}
        metadata[id]['animations']['wing_beat'] = {'atlas': 'extra', 'frames': [4, 5, 5, 4]}
        metadata[id]['animations']['rebirth'] = {'atlas': 'extra', 'frames': [6, 6, 7, 7]}
    if id == 'spinegrin':
        metadata[id]['animations']['special'] = {'atlas': 'extra', 'frames': [6, 6, 7, 7, 6]}
    profile = next(f for f in roster if f['id'] == id)
    provenance['derived_assets'] = [p for p in provenance['derived_assets'] if p['path'] != str(path)]
    provenance['derived_assets'].append({
        'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'kind': 'reference_guided_generated_supplemental_combat_keys',
        'reference': profile['reference_art_path'], 'original_user_file': False,
        'unique_poses': 8,
        'notes': 'Full-silhouette meshes retain extended kick feet outside nominal grid cells. Heavy attacks depict actual kicks or a wolf bite; additional slam/wing/buff keys are shared by appropriate abilities.',
    })
    print(id, 'eight supplemental keys indexed with full extended limbs')
metadata_path.write_text(json.dumps(metadata, indent=2)+'\n')
provenance_path.write_text(json.dumps(provenance, indent=2)+'\n')
