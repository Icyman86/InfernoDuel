"""Validate the authored GLB files independently of the Blender generator."""
from pathlib import Path
import hashlib
import json
import math
import struct

root=Path(__file__).resolve().parent.parent
catalog=json.loads((root/'data/character_models.json').read_text())['fighters']
roster=json.loads((root/'data/fighters.json').read_text())['fighters']
assert set(catalog) <= {f['id'] for f in roster}, 'Legacy models must reference known fighters'
seen=set()
for fighter in roster:
    if fighter['id'] not in catalog: continue  # V16 gallery uses 2D art; retained V13 models are optional.
    meta=catalog[fighter['id']]
    path=root/meta['path']; raw=path.read_bytes()
    magic,version,length=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and length==len(raw), path
    n,kind=struct.unpack_from('<II',raw,12)
    assert kind==0x4e4f534a,path
    gltf=json.loads(raw[20:20+n]);binary_offset=20+n+8
    binary=raw[binary_offset:]
    digest=hashlib.sha256(raw).hexdigest()
    assert digest==meta['sha256'] and digest not in seen,path
    seen.add(digest)
    assert len(gltf['skins'])==1 and len(gltf['skins'][0]['joints'])>=16,path
    assert gltf['animations'] and gltf['animations'][0]['channels'],path
    assert not any('KHR_draco_mesh_compression' in p.get('extensions',{}) for m in gltf['meshes'] for p in m['primitives']),path
    triangles=0
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            assert primitive.get('mode',4)==4,path
            assert {'POSITION','NORMAL','JOINTS_0','WEIGHTS_0'} <= primitive['attributes'].keys(),path
            triangles+=gltf['accessors'][primitive['indices']]['count']//3
            accessor=gltf['accessors'][primitive['attributes']['WEIGHTS_0']]
            assert accessor['componentType']==5126 and accessor['type']=='VEC4',path
            view=gltf['bufferViews'][accessor['bufferView']]
            offset=view.get('byteOffset',0)+accessor.get('byteOffset',0)
            stride=view.get('byteStride',16)
            for i in range(accessor['count']):
                weights=struct.unpack_from('<4f',binary,offset+i*stride)
                assert all(math.isfinite(v) and 0<=v<=1 for v in weights),path
                assert abs(sum(weights)-1)<.002,(path,weights)
    assert triangles>=30000 and len(gltf['materials'])>=8,path
    assert all(image.get('bufferView') is not None for image in gltf['images']), 'Self-contained GLB images required'
    print(f"PASS {fighter['id']}: {triangles:,} triangles, 16+ bones, normalized weights, PBR materials, packed textures, animation and SHA-256")
print(f'MODEL RESULT: {len(seen)} distinct skinned models validated')
