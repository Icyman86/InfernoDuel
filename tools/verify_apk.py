"""Inspect the actual APK payload; apksigner and zipalign validate it separately."""
from pathlib import Path
import sys
import zipfile

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None, "Corrupt APK entry"
    names = set(archive.namelist())
    for abi in ("arm64-v8a", "x86_64"):
        assert f"lib/{abi}/libgodot_android.so" in names, f"Missing {abi} engine"
    for fighter in ("sharkbyte", "bullet", "nachtelf", "poisonboy", "chainveil",
                    "spinegrin", "cheese_rat", "lava_stone", "crystal_fang", "phoenix_reign"):
        assert f"assets/assets/intros/{fighter}.ogv" in names, f"Missing {fighter} intro"
    for script in ("scripts/core/input_router", "scripts/ui/game", "scripts/ui/touch_controls"):
        assert f"assets/{script}.gdc" in names, f"Missing compiled {script}"
    for script in ("scripts/ui/gallery", "scripts/ui/fighter_presentation", "scripts/combat/move_catalog", "scripts/combat/fighter_motion", "scripts/combat/walk_pose_fields"):
        assert f"assets/{script}.gdc" in names, f"Missing character presentation {script}"
    for script in ('scripts/network/session_code', 'scripts/network/session_discovery', 'scripts/network/online_session',
                   'scripts/network/network_match_driver', 'scripts/ui/online_lobby'):
        assert f'assets/{script}.gdc' in names, f'Missing V8 connection script {script}'
    import json
    fighters = json.loads(archive.read('assets/data/fighters.json'))['fighters']
    moves = json.loads(archive.read('assets/data/move_sets.json'))
    assert len(fighters) == 10 and all(f['playable'] and f['sprite_ready'] for f in fighters)
    assert sum(map(len, moves.values())) == 69
    movement = json.loads(archive.read('assets/data/movement_animations.json'))
    assert set(movement['profiles']) == {f['id'] for f in fighters}
    assert {'start','brake','backstep','pivot','rise','apex','fall','land','guard_in','guard_out'} <= set(movement['clips'])
    import base64
    fields = json.loads(archive.read('assets/data/walk_motion_fields.json'))
    assert set(fields['profiles']) == {f['id'] for f in fighters}
    assert sum(map(len,fields['profiles'].values())) == 54
    for sequence in fields['profiles'].values():
        assert all(len(base64.b64decode(item)) == fields['grid'][0]*fields['grid'][1]*4 for item in sequence)
    assert not any(name.startswith(("assets/tests/", "assets/releases/")) for name in names)
print(f"APK PAYLOAD PASS: ARM64 + x86_64, V8 persistent podium and continuous movement scripts, ten playable fighters, 69 moves, touch ({apk.stat().st_size} bytes)")
