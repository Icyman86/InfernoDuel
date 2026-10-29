"""Package a real unsigned device .app, then verify the resulting sideload IPA."""
import hashlib
from pathlib import Path
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent
app = Path(sys.argv[1]).resolve()
if app.suffix != '.app' or not app.is_dir():
    raise SystemExit('Expected an existing Xcode-built device .app directory')
version = re.search(r'config/version="([^"]+)"', (ROOT/'project.godot').read_text())[1]
target = ROOT/'builds/ios'/f'InfernoDuel-iPhone-v{version}-unsigned.ipa'
target.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for file in sorted(app.rglob('*')):
        if file.is_file():
            archive.write(file, Path('Payload')/app.name/file.relative_to(app))
subprocess.run([sys.executable, str(ROOT/'tools/verify_ios.py'), str(target)], check=True)
with target.open('rb') as source:
    digest = hashlib.file_digest(source, 'sha256').hexdigest()
(target.parent/'SHA256SUMS').write_text(digest+'  '+target.name+'\n')
print('Unsigned IPA built and verified:', target)
