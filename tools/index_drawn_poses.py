"""Index generated drawings; read PNG pixels only, never modify any artwork."""
from pathlib import Path
import hashlib
import json
import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

root = Path(__file__).resolve().parent.parent
path = root/'data/sprite_atlases.json'
metadata = json.loads(path.read_text())
sources = json.loads((root/'data/drawn_animation_sources.json').read_text())
provenance_path = root/'data/visual_asset_provenance.json'
provenance = json.loads(provenance_path.read_text())
for fighter, slots in sources['profiles'].items():
    data = metadata[fighter]
    # Re-running authoring replaces only the V10 metadata, never adds duplicates.
    for key in ['drawn', 'drawn_heavy']:
        data.pop(key, None)
    for slot in slots:
        image = np.asarray(Image.open(root/slot['path']).convert('RGBA'))
        alpha = image[:, :, 3]
        assert alpha.min() == 0 and alpha.max() > 200
        labels, _ = ndimage.label(alpha > 128)
        areas = np.bincount(labels.ravel())
        height, width = alpha.shape
        columns, rows = slot['grid']
        candidates = {}
        # Find complete connected characters, allowing small cell overhangs.
        # Fixed grid crops would slice off feet that cross a nominal row line.
        for label, box in enumerate(ndimage.find_objects(labels), 1):
            if box is None or areas[label] < 1800:
                continue
            ys, xs = box
            yy, xx = np.nonzero(labels[ys, xs] == label)
            gx, gy = xx+xs.start, yy+ys.start
            cell = min(rows-1, int(gy.mean()*rows/height))*columns+min(columns-1, int(gx.mean()*columns/width))
            if cell not in candidates or areas[label] > candidates[cell][0]:
                candidates[cell] = (areas[label], box, label)
        frames, body_heights = [], []
        for cell in slot['use']:
            assert cell in candidates, (fighter, slot['atlas'], cell, 'missing full body')
            _, box, label = candidates[cell]
            ys, xs = box
            assert ys.start > 0 and ys.stop < height, (fighter, cell, 'body clipped at image edge')
            x0, x1 = max(0, xs.start-2), min(width, xs.stop+2)
            y0, y1 = max(0, ys.start-2), min(height, ys.stop+2)
            body = (labels[y0:y1, x0:x1] == label).astype(np.uint8)
            contours, _ = cv2.findContours(body, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            contour = max(contours, key=cv2.contourArea)
            # Thin hair/chain branches can touch themselves in an alpha contour.
            # A convex envelope always triangulates; transparent atlas pixels
            # preserve the painted silhouette without changing the artwork.
            polygon = cv2.convexHull(contour)[:, 0, :]
            yy, xx = np.nonzero(body)
            ground = int(yy.max())
            body_height = int(yy.max()-yy.min()+1)
            torso = (yy > ground-body_height*.72) & (yy < ground-body_height*.47)
            center = float(np.mean(xx[torso])) if torso.any() else float(np.mean(xx))
            heavy = slot['atlas'] == 'drawn_heavy' or cell >= 12
            if heavy:
                columns_at_floor = np.any(body[max(0, ground-4):ground+1], axis=0)
                starts = np.flatnonzero(np.diff(np.r_[False, columns_at_floor].astype(int)) == 1)
                ends = np.flatnonzero(np.diff(np.r_[columns_at_floor, False].astype(int)) == -1)
                feet = [(a+b)*.5 for a, b in zip(starts, ends) if b-a >= 3]
                if feet: center = min(feet, key=lambda x: abs(x-(center-body_height*.1)))
            frames.append({'rect':[x0,y0,x1-x0,y1-y0], 'pivot':[round(center,2),ground],
                           'polygon':polygon.astype(int).tolist(), 'drawn_cell':cell})
            if (slot['atlas'] == 'drawn_heavy' and cell in [0,11]) or (slot['atlas'] == 'drawn' and cell in [0,11,12,23]):
                body_heights.append(body_height)
        reference_height = float(np.median(body_heights))
        data[slot['atlas']] = {'path':slot['path'], 'frames':frames, 'scale':data['base_height']/reference_height,
                               'provenance':'new separately illustrated action steps; no raster or vector warping'}
        provenance['derived_assets'] = [p for p in provenance['derived_assets'] if p['path'] != slot['path']]
        provenance['derived_assets'].append({'path':slot['path'], 'sha256':hashlib.sha256((root/slot['path']).read_bytes()).hexdigest(),
            'kind':'reference_guided_generated_discrete_animation_drawings', 'original_user_file':False,
            'reference':data['core']['path'], 'grid':slot['grid'], 'indexed_poses':len(frames),
            'notes':'ImageGen draws individual anatomy/limb positions. Indexer reads alpha and writes mesh metadata only. Rejected/unselected cells never enter runtime.'})
        print('DRAWN',fighter,slot['atlas'],len(frames),'complete indexed bodies',flush=True)
    heavy_source = 'drawn_heavy' if fighter == 'poisonboy' else 'drawn'
    heavy_first = 0 if fighter == 'poisonboy' else 12
    data['animations']['walk'] = {'atlas':'drawn','frames':list(range(12)),'fps':12}
    data['animations']['heavy'] = {'atlas':heavy_source,'frames':list(range(heavy_first,heavy_first+12)),
        'times':[0,.05,.10,.16,.24,.34,.45,.68,.75,.83,.91,.97], 'contact_frame':6,'fps':20}
    for name in ['idle','guard']:
        data['animations'][name] = {'atlas':heavy_source,'frames':[heavy_first],'fps':6}
    unique = {(v['path'],tuple(f['rect'])) for v in data.values() if isinstance(v,dict) and 'path' in v for f in v['frames']}
    data['unique_frame_count'] = len(unique)
path.write_text(json.dumps(metadata,indent=2)+'\n')
provenance_path.write_text(json.dumps(provenance,indent=2)+'\n')
