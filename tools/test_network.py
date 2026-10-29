"""Run isolated Godot processes over real loopback UDP/ENet, not mocked RPCs."""
from pathlib import Path
import json
import os
import re
import subprocess
import tempfile
import time
import shutil

root = Path(__file__).resolve().parent.parent
os.chdir(root)
godot = os.environ.get('GODOT_BIN', 'godot')
with tempfile.TemporaryDirectory(prefix='inferno-network-') as folder:
    directory = Path(folder)
    processes = []
    streams = []

    def start(role):
        stream = (directory / f'{role}.log').open('w')
        streams.append(stream)
        command = [godot] + (['--verbose'] if os.environ.get('NETWORK_VERBOSE') == '1' else []) + ([] if os.environ.get('NETWORK_RENDERED') == '1' else ['--headless']) + ['--audio-driver', 'Dummy', '--path', str(root), 'tests/network_peer.tscn',
                   '--', '--touch', f'--role={role}', f'--directory={directory}']
        process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT)
        processes.append(process)
        return process

    try:
        host = start('host')
        deadline = time.monotonic() + 10
        while not (directory / 'code.txt').exists():
            if host.poll() is not None or time.monotonic() > deadline:
                raise AssertionError('Host did not create a session')
            time.sleep(.05)
        bad = start('bad')
        assert bad.wait(timeout=12) == 0, 'Wrong-code rejection client failed'
        guest = start('guest')
        assert host.wait(timeout=45) == 0, 'Authoritative host integration failed'
        assert guest.wait(timeout=12) == 0, 'Guest integration failed'
        total = 0
        for role in ['host', 'bad', 'guest']:
            result = json.loads((directory / f'{role}.json').read_text())
            assert result['failed'] == 0, result
            log = (directory / f'{role}.log').read_text()
            assert not re.search(r'SCRIPT ERROR|^ERROR:|instances leaked', log, re.M), log
            print(log.strip())
            total += result['passed']
        print(f'NETWORK RESULT: {total} passed, 0 failed; three real Godot processes')
    finally:
        for process in processes:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
        for stream in streams:
            stream.close()
        if os.environ.get('NETWORK_ARTIFACT_DIR'):
            destination = Path(os.environ['NETWORK_ARTIFACT_DIR'])
            destination.mkdir(parents=True, exist_ok=True)
            for path in directory.iterdir():
                if path.suffix in ['.log', '.png', '.json']:
                    shutil.copyfile(path, destination / path.name)
        # Print diagnostic logs on failure, without publishing the invitation.
        for role in ['host', 'bad', 'guest']:
            path = directory / f'{role}.log'
            if path.exists() and any(p.returncode for p in processes):
                print(f'--- {role} diagnostics ---\n{path.read_text()}')
