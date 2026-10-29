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
    assert not any(name.startswith(("assets/tests/", "assets/releases/")) for name in names)
print(f"APK PAYLOAD PASS: ARM64 + x86_64, touch scripts, ten films, valid ZIP ({apk.stat().st_size} bytes)")
