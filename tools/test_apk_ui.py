"""Run Godot against the actual APK assets, with no editor project fallback.

Only the probe script is outside the resource pack. APK assets keep their exported
compiled scripts, import remaps, packed textures and project.binary settings.
Requires a DISPLAY and the matching Godot version; not a physical Android test.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

root = Path(__file__).resolve().parent.parent
apk = Path(sys.argv[1]).resolve()
output = Path(os.environ.get('V17_ARTIFACT_DIR', '/tmp/inferno-v17'))
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='inferno-apk-ui-') as directory:
    directory = Path(directory)
    pack = directory / 'android-assets.zip'
    with zipfile.ZipFile(apk) as source, zipfile.ZipFile(pack, 'w', compression=zipfile.ZIP_STORED) as target:
        for entry in source.infolist():
            if entry.filename.startswith('assets/') and not entry.is_dir():
                target.writestr(entry.filename.removeprefix('assets/'), source.read(entry))
    probe = directory / 'probe.gd'
    shutil.copyfile(root/'tests/apk_ui_probe.gd', probe)
    result = subprocess.run([
        os.environ.get('GODOT_BIN', 'godot'), '--main-pack', str(pack),
        '--audio-driver', 'Dummy', '--script', str(probe), '--', '--touch',
    ], cwd=directory, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
    log = result.stdout
    (output/'apk-ui.log').write_text(log)
    print(log)
    assert result.returncode == 0, 'Exported APK UI probe failed'
    assert not re.search(r'SCRIPT ERROR|^ERROR:|instances leaked', log, re.M), 'APK UI emitted errors'
    assert re.search(r'APK UI RESULT: [1-9][0-9]* passed, 0 failed', log)
