"""Analyze stable torso/ground anchors and walking vectors without changing artwork."""
import json
from pose_field_utils import ROOT, config, torso_anchor, analysis_image, field
metadata = json.loads((ROOT/'data/sprite_atlases.json').read_text())
output = config()
output['anchors'] = {}
output['provenance'] = 'Torso-stabilized bidirectional motion vectors from unchanged indexed poses.'
for fighter,data in metadata.items():
    animation = data['animations']['walk']
    source = animation.get('atlas','core')
    descriptors = [{'atlas':source,'index':index,'pivot':torso_anchor(data,source,index)} for index in animation['frames']]
    images = [analysis_image(data,d) for d in descriptors]
    output['profiles'][fighter] = [field(a,images[(i+1)%len(images)]) for i,a in enumerate(images)]
    output['anchors'][fighter] = {str(d['index']):d['pivot'] for d in descriptors}
    print('WALK FIELDS',fighter,len(images),'stable torso anchors',flush=True)
(ROOT/'data/walk_motion_fields.json').write_text(json.dumps(output,separators=(',',':'))+'\n')
