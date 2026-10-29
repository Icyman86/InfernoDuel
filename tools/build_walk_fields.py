"""Analyze existing pose pixels into GPU motion-vector data; never writes artwork.
Optional authoring dependencies: NumPy, Pillow and opencv-python-headless 4.11.0.86.
"""
from pathlib import Path
import base64
import json
import cv2
import numpy as np
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent
metadata = json.loads((root / 'data/sprite_atlases.json').read_text())
canvas = (512, 384)
foot = np.array([256.0, 340.0])
body_height = 256.0
grid = (96, 72)
flow_range = 96.0
cv2.setNumThreads(2)
output = {'schema_version': 1, 'canvas': canvas, 'grid': grid, 'foot': foot.tolist(),
          'body_height': body_height, 'range': flow_range, 'profiles': {},
          'provenance': 'Bidirectional motion vectors analyzed from existing indexed pose artwork. No artwork pixels or originals changed.'}
for fighter, data in metadata.items():
    animation = data['animations']['walk']
    atlas = data[animation.get('atlas', 'core')]
    rgba = np.asarray(Image.open(root / atlas['path']).convert('RGBA'))
    images = []
    norm = body_height / data['base_height'] * atlas.get('scale', 1.0)
    for index in animation['frames']:
        frame = atlas['frames'][index]
        x, y, width, height = frame['rect']
        crop = rgba[y:y+height, x:x+width]
        mask = Image.new('L', (width, height))
        ImageDraw.Draw(mask).polygon([tuple(p) for p in frame['polygon']], fill=255)
        alpha = crop[:, :, 3].astype(np.float32) / 255 * np.asarray(mask) / 255
        gray = cv2.cvtColor(crop[:, :, :3], cv2.COLOR_RGB2GRAY).astype(np.float32)
        # Alpha makes black clothing distinguishable from transparent background.
        luminance = ((gray * .5 + 120) * alpha).clip(0, 255).astype(np.uint8)
        matrix = np.array([[norm, 0, foot[0]-frame['pivot'][0]*norm],
                           [0, norm, foot[1]-frame['pivot'][1]*norm]], dtype=np.float32)
        images.append(cv2.warpAffine(luminance, matrix, canvas, flags=cv2.INTER_LINEAR))
    fields = []
    algorithm = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    for i, a in enumerate(images):
        b = images[(i+1) % len(images)]
        forward = algorithm.calc(a, b, None)
        backward = algorithm.calc(b, a, None)
        vectors = cv2.resize(np.dstack((forward, backward)), grid, interpolation=cv2.INTER_AREA)
        packed = np.rint(np.clip(vectors/flow_range, -1, 1)*127+128).astype(np.uint8)
        fields.append(base64.b64encode(packed.tobytes()).decode('ascii'))
    output['profiles'][fighter] = fields
    print('WALK FIELD', fighter, len(fields), 'bidirectional pose pairs', flush=True)
(root / 'data/walk_motion_fields.json').write_text(json.dumps(output, separators=(',', ':'))+'\n')
