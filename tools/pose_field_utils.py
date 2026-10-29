"""Read-only artwork analysis shared by movement/action authoring tools."""
from pathlib import Path
import base64
import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
CANVAS = (640, 448)
FOOT = np.array([256.0, 396.0])
HEIGHT = 256.0
GRID = (96, 72)
RANGE = 144.0
cv2.setNumThreads(2)


def masked_frame(data, source, index):
    atlas = data[source]
    frame = atlas['frames'][index]
    x, y, width, height = frame['rect']
    rgba = np.asarray(Image.open(ROOT / atlas['path']).convert('RGBA'))[y:y+height, x:x+width]
    mask = Image.new('L', (width, height))
    ImageDraw.Draw(mask).polygon([tuple(p) for p in frame['polygon']], fill=255)
    alpha = rgba[:, :, 3].astype(np.float32) / 255 * np.asarray(mask) / 255
    return rgba, alpha


def rear_support(data, source, index):
    frame = data[source]['frames'][index]
    _, alpha = masked_frame(data, source, index)
    height = data['base_height'] / data[source].get('scale', 1)
    low = max(0, int(frame['pivot'][1] - height*.035))
    columns = np.sum(alpha[low:], axis=0) > .8
    spans = []
    start = None
    for x, on in enumerate(np.r_[columns, False]):
        if on and start is None: start = x
        if not on and start is not None:
            if x-start >= max(3, height*.025): spans.append((start, x))
            start = None
    valid = [s for s in spans if abs((s[0]+s[1])*.5-frame['pivot'][0]) < height*.55]
    support = (valid[0][0]+valid[0][1])*.5 if valid else frame['pivot'][0]
    return [float(support), float(frame['pivot'][1])]


def torso_anchor(data, source, index):
    frame = data[source]['frames'][index]
    _, alpha = masked_frame(data, source, index)
    height = data['base_height'] / data[source].get('scale', 1)
    yy, xx = np.indices(alpha.shape)
    head = alpha * (yy < frame['pivot'][1]-height*.75)
    head_x = float((head*xx).sum()/max(head.sum(), 1))
    band = (yy > frame['pivot'][1]-height*.74) & (yy < frame['pivot'][1]-height*.47)
    weights = alpha*band*np.exp(-((xx-head_x)/(height*.18))**2)
    root_x = float((weights*xx).sum()/max(weights.sum(), 1))
    return [root_x, float(frame['pivot'][1])]


def analysis_image(data, descriptor):
    source, index = descriptor['atlas'], descriptor['index']
    rgba, alpha = masked_frame(data, source, index)
    gray = cv2.cvtColor(rgba[:, :, :3], cv2.COLOR_RGB2GRAY).astype(np.float32)
    luminance = ((gray*.5+120)*alpha).clip(0, 255).astype(np.uint8)
    norm = HEIGHT/data['base_height']*data[source].get('scale', 1)*descriptor.get('scale', 1)
    pivot = descriptor['pivot']
    matrix = np.array([[norm,0,FOOT[0]-pivot[0]*norm], [0,norm,FOOT[1]-pivot[1]*norm]],dtype=np.float32)
    return cv2.warpAffine(luminance,matrix,CANVAS,flags=cv2.INTER_LINEAR)


def field(a, b, compressed=False):
    import zlib
    if np.array_equal(a,b):
        packed = np.full((GRID[1],GRID[0],4),128,dtype=np.uint8)
    else:
        algorithm = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
        forward = algorithm.calc(a,b,None)
        backward = algorithm.calc(b,a,None)
        vectors = cv2.resize(np.dstack((forward,backward)),GRID,interpolation=cv2.INTER_AREA)
        packed = np.rint(np.clip(vectors/RANGE,-1,1)*127+128).astype(np.uint8)
    raw = packed.tobytes()
    return base64.b64encode(zlib.compress(raw,9) if compressed else raw).decode('ascii')


def config():
    return {'schema_version':2,'canvas':CANVAS,'grid':GRID,'foot':FOOT.tolist(),
            'body_height':HEIGHT,'range':RANGE,'profiles':{}}
