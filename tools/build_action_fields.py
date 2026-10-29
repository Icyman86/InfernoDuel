"""Build planted-foot, full-return attack interpolation data; artwork is read-only."""
import json
from pose_field_utils import ROOT, HEIGHT, config, rear_support, analysis_image, field
metadata = json.loads((ROOT/'data/sprite_atlases.json').read_text())
result = config()
result['compression'] = 'deflate'
result['provenance'] = 'Derived full action timelines and bidirectional fields from unchanged authored artwork; no new hand-drawn-frame claim.'
for fighter, data in metadata.items():
    clips, fields, images = {}, {}, {}
    idle = data['animations']['idle']
    idle_source, idle_index = idle.get('atlas','core'),idle['frames'][0]
    for name, animation in data['animations'].items():
        if name in ['idle','walk','jump','guard','hit','ko']: continue
        source = animation.get('atlas','core')
        unique = []
        for index in animation['frames']:
            if not unique or unique[-1] != index: unique.append(index)
        start = {'atlas':idle_source,'index':idle_index,'pivot':rear_support(data,idle_source,idle_index),'frame':0}
        norm = HEIGHT/data['base_height']*data[idle_source].get('scale',1)
        offset = [(start['pivot'][0]-data[idle_source]['frames'][idle_index]['pivot'][0])*norm,0]
        action = [{'atlas':source,'index':index,'pivot':rear_support(data,source,index),'frame':i} for i,index in enumerate(unique)]
        if len(action) >= 4:
            keys = [start,action[0],action[1],action[2],action[2],action[3],start]
            times = [0,.09,.28,.45,.65,.86,1]
        elif len(action) == 3:
            keys = [start,action[0],action[1],action[1],action[2],start]
            times = [0,.14,.45,.65,.84,1]
        else:
            keys = [start,action[0],action[-1],action[-1],action[0],start]
            times = [0,.18,.45,.65,.86,1]
        ids = []
        for key in keys:
            key_id = key['atlas']+':'+str(key['index'])
            if key_id not in images: images[key_id] = analysis_image(data,key)
            ids.append(key_id)
        pairs=[]
        for i in range(len(keys)-1):
            pair_id = ids[i]+'>'+ids[i+1]
            if pair_id not in fields: fields[pair_id] = field(images[ids[i]],images[ids[i+1]],True)
            pairs.append(pair_id)
        clips[name] = {'keys':keys,'times':times,'pairs':pairs,'root_offset':offset}
    result['profiles'][fighter] = {'clips':clips,'fields':fields}
    print('ACTION FIELDS',fighter,len(clips),'clips',len(fields),'transitions',flush=True)
(ROOT/'data/action_motion_fields.json').write_text(json.dumps(result,separators=(',',':'))+'\n')
