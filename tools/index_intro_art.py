"""Index cinematic reference-derived artwork; reads PNGs and writes metadata only.
Optional authoring dependencies: Pillow, numpy, scipy. Not needed to play/build.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import ConvexHull

metadata_path = Path("data/intro_atlases.json")
result = json.loads(metadata_path.read_text()) if metadata_path.exists() else {}
for path in sorted(Path('assets/intros').glob('*_poses.png')):
    image = np.asarray(Image.open(path))
    height, width = image.shape[:2]
    mask = image[:, :, 3] > 40
    labels, _ = ndimage.label(mask)
    objects = ndimage.find_objects(labels)
    # Some rendered atlases contain a one-pixel bridge between two camera shots.
    # Disconnect that bridge in the metadata analysis, leaving the PNG untouched.
    for identity, box in enumerate(objects, 1):
        if box is None:
            continue
        ys, xs = box
        if ys.stop - ys.start > height * .70:
            start, stop = int(height * .44), int(height * .54)
            band = (labels[start:stop, xs] == identity).sum(axis=1)
            cut = start + int(band.argmin())
            mask[cut, xs] = False
    labels, _ = ndimage.label(mask)
    areas = np.bincount(labels.ravel())
    objects = ndimage.find_objects(labels)
    groups = [[] for _ in range(4)]
    for identity in range(1, len(areas)):
        if areas[identity] < 10000:
            continue
        ys, xs = objects[identity - 1]
        yy, xx = np.nonzero(labels[ys, xs] == identity)
        points = np.column_stack((xx + xs.start, yy + ys.start))
        center = points.mean(axis=0)
        group = int(center[1] >= height / 2) * 2 + int(center[0] >= width / 2)
        groups[group].append(points)
    frames = []
    for group, components in enumerate(groups):
        assert components, (path, 'missing cinematic view', group)
        points = np.concatenate(components)
        left, top = points.min(axis=0)
        right, bottom = points.max(axis=0) + 1
        polygons = []
        for component in components:
            hull = ConvexHull(component)
            poly = component[hull.vertices].astype(float)
            center = poly.mean(axis=0)
            delta = poly - center
            poly += delta / np.linalg.norm(delta, axis=1)[:, None] * 1.2
            polygons.append(np.round(poly - np.array([left, top]), 2).tolist())
        frames.append({'rect': [int(left), int(top), int(right-left), int(bottom-top)], 'polygons': polygons})
    result[path.stem.removesuffix('_poses')] = {'path': str(path), 'frames': frames}
    print(path.stem, 'four indexed cinematic views', [frame['rect'][2:] for frame in frames])
Path('data/intro_atlases.json').write_text(json.dumps(result, indent=2) + '\n')
