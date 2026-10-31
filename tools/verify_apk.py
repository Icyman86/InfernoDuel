"""Inspect the actual APK payload; apksigner and zipalign validate it separately."""
from pathlib import Path
import sys
import zipfile
import re

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None, "Corrupt APK entry"
    names = set(archive.namelist())
    for abi in ("arm64-v8a", "x86_64"):
        assert f"lib/{abi}/libgodot_android.so" in names, f"Missing {abi} engine"
    for fighter in ("sharkbyte", "bullet", "nachtelf", "poisonboy", "chainveil",
                    "spinegrin", "cheese_rat", "lava_stone", "crystal_fang", "phoenix_reign", "bamboo_blade", "sawtina"):
        assert f"assets/assets/intros/{fighter}.ogv" in names, f"Missing {fighter} intro"
    for script in ("scripts/core/story_catalog", "scripts/ui/story_select", "scripts/core/progression", "scripts/core/input_router", "scripts/ui/game", "scripts/ui/touch_controls"):
        assert f"assets/{script}.gdc" in names, f"Missing compiled {script}"
    for script in ("scripts/ui/fighter_illustration", "scripts/ui/gallery", "scripts/ui/fighter_presentation", "scripts/combat/move_catalog", "scripts/combat/fighter_motion", "scripts/combat/walk_pose_fields", "scripts/combat/action_pose_fields", "scripts/ui/ultimate_gauge", "scripts/ui/combat_chrome", "scripts/ui/fighter_bust"):
        assert f"assets/{script}.gdc" in names, f"Missing character presentation {script}"
    for script in ('scripts/network/session_code', 'scripts/network/session_discovery', 'scripts/network/online_session',
                   'scripts/network/network_match_driver', 'scripts/ui/online_lobby'):
        assert f'assets/{script}.gdc' in names, f'Missing V10 connection script {script}'
    import json
    fighters = json.loads(archive.read('assets/data/fighters.json'))['fighters']
    moves = json.loads(archive.read('assets/data/move_sets.json'))
    campaign = json.loads(archive.read('assets/data/story_campaign.json'))
    assert campaign['player'] == 'sharkbyte'
    assert [(level['opponent'],level['arena']) for level in campaign['levels']] == [
        ('bullet','citadel'),('nachtelf','nightelf_forest'),('spinegrin','living_ship'),('crystal_fang','crystal_mine')]
    cinematic_art = json.loads(archive.read('assets/data/intro_atlases.json'))
    assert set(cinematic_art) == {f['id'] for f in fighters}
    # V16 omitted these PNGs despite the gallery's runtime JSON references.
    # Check the actual import remap AND its imported payload for every fighter.
    for fighter, artwork in cinematic_art.items():
        remap_path = 'assets/'+artwork['path']+'.import'
        assert remap_path in names, f'Missing {fighter} gallery texture remap'
        remap = archive.read(remap_path).decode().rstrip('\0')
        imported = re.search(r'path="res://([^"]+)"',remap)
        assert imported and 'assets/'+imported.group(1) in names, f'Missing {fighter} gallery texture payload'

    assert len(fighters) == 12 and all(f['playable'] and f['sprite_ready'] for f in fighters)
    assert sum(map(len, moves.values())) == 77
    movement = json.loads(archive.read('assets/data/movement_animations.json'))
    assert set(movement['profiles']) == {f['id'] for f in fighters}
    assert {'start','brake','backstep','pivot','rise','apex','fall','land','guard_in','guard_out'} <= set(movement['clips'])
    legacy_ids = {f['id'] for f in fighters if f['id'] not in ('bamboo_blade','sawtina')}
    import base64
    fields = json.loads(archive.read('assets/data/walk_motion_fields.json'))
    assert set(fields['profiles']) == legacy_ids
    assert sum(map(len,fields['profiles'].values())) == 54
    for sequence in fields['profiles'].values():
        assert all(len(base64.b64decode(item)) == fields['grid'][0]*fields['grid'][1]*4 for item in sequence)
    import zlib
    actions = json.loads(archive.read('assets/data/action_motion_fields.json'))
    assert set(actions['profiles']) == legacy_ids
    assert sum(len(p['clips']) for p in actions['profiles'].values()) == 49
    assert sum(len(p['fields']) for p in actions['profiles'].values()) == 266
    for profile in actions['profiles'].values():
        for raw in profile['fields'].values():
            assert len(zlib.decompress(base64.b64decode(raw))) == actions['grid'][0]*actions['grid'][1]*4
    for shader in ['presentation','ultimate_bar','cel']:
        assert f'assets/assets/shaders/{shader}.gdshader' in names
    poses = json.loads(archive.read('assets/data/sprite_atlases.json'))
    busts = json.loads(archive.read('assets/data/select_busts.json'))['profiles']
    assert set(busts) == {f['id'] for f in fighters}
    assert sum(len(p['drawn']['frames'])+len(p.get('drawn_heavy',{}).get('frames',[])) for id,p in poses.items() if id in legacy_ids) == 240
    for fighter, data in poses.items():
        assert len(data['animations']['walk']['frames']) >= 6
        assert len(data['animations']['heavy']['frames']) >= 4
        assert {'idle','walk','light','heavy','guard','jump','special','ultimate','hit','ko'} <= set(data['animations'])
        if fighter in ('bamboo_blade','sawtina'):
            assert data['unique_frame_count'] == 26
            profile = next(f for f in fighters if f['id'] == fighter)
            assert profile['unlock_cost'] == 200
            remap = archive.read(f'assets/assets/sprites/{fighter}/atlas.png.import').decode().rstrip('\0')
            imported = re.search(r'path="res://([^"]+)"',remap)
            assert imported and 'assets/'+imported.group(1) in names, f'Missing imported {fighter} animation texture'
    assert any('v16_ultimates.png-' in name and name.endswith('.ctex') for name in names), 'Missing clean ultimate artwork'
    arenas = json.loads(archive.read('assets/data/arenas.json'))['arenas']
    assert {a['id'] for a in arenas} == {'citadel','nightelf_forest','living_ship','crystal_mine'}
    assert next(a for a in arenas if a['id']=='crystal_mine')['name'] == 'Crystal Fang zijn mijn'
    assert any('crystal_mine.png-' in name and name.endswith('.ctex') for name in names), 'Missing imported mine texture'
    for script in ['scripts/core/arena_catalog','scripts/ui/arena_select','scripts/combat/ultimate_aura','scripts/ui/ultimate_banner']:
        assert f'assets/{script}.gdc' in names, f'Missing V14 feature {script}'
    assert not any(name.startswith(("assets/tests/", "assets/releases/", "assets/builds/")) for name in names)
print(f"APK PAYLOAD PASS: ARM64 + x86_64, V17 four story levels, all twelve gallery textures, four arenas, twelve animated fighters, 77 moves, two 200-coin unlocks, persisted wallet, twelve intros, unicast discovery and compact snapshots, touch ({apk.stat().st_size} bytes)")
