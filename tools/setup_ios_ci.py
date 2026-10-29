"""Install pinned official Godot editor/iOS template on a macOS CI runner."""
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent.parent
lock = json.loads((ROOT / 'tools/godot_ios_lock.json').read_text())
if platform.system() != 'Darwin':
    raise SystemExit('This bootstrap installs the macOS editor; run it on a Mac.')
downloads = ROOT / 'builds/ios-tools'
downloads.mkdir(parents=True, exist_ok=True)
base = f'https://github.com/godotengine/godot-builds/releases/download/{lock["version"]}-stable/'


def fetch(kind):
    name = lock[kind + '_archive']
    path = downloads / name
    if not path.exists():
        print('Downloading official', name, flush=True)
        with urllib.request.urlopen(base + name, timeout=120) as response, path.open('wb') as dest:
            while block := response.read(1024 * 1024):
                dest.write(block)
    with path.open('rb') as source:
        actual = hashlib.file_digest(source, 'sha512').hexdigest()
    if actual != lock[kind + '_sha512']:
        raise SystemExit(f'Official {kind} archive checksum mismatch')
    return path


subprocess.run(['ditto', '-x', '-k', str(fetch('macos')), str(downloads)], check=True)
binary = downloads / 'Godot.app/Contents/MacOS/Godot'
binary.chmod(0o755)
templates = Path.home() / 'Library/Application Support/Godot/export_templates' / (lock['version'] + '.stable')
templates.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(fetch('templates')) as archive:
    (templates / 'ios.zip').write_bytes(archive.read('templates/ios.zip'))
if os.environ.get('GITHUB_ENV'):
    with open(os.environ['GITHUB_ENV'], 'a') as out:
        out.write('GODOT_BIN=' + str(binary) + '\n')
print('Verified macOS editor:', binary)
print('Verified iOS template:', templates / 'ios.zip')
