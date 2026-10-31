"""Exercise the exported PCK through real X11 key events on a virtual display.
This proves OS event delivery, not physical controller/keyboard hardware quality.
"""
import ctypes
import json
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parent.parent
output_dir = Path('/tmp/inferno-v13-native')
output_dir.mkdir(parents=True, exist_ok=True)
state_path = Path('/tmp/inferno-v12-native.json')
state_path.unlink(missing_ok=True)
x11 = ctypes.CDLL('libX11.so.6')
xtst = ctypes.CDLL('libXtst.so.6')
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x11.XKeysymToKeycode.restype = ctypes.c_uint
x11.XFlush.argtypes = [ctypes.c_void_p]
x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
xtst.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
display = x11.XOpenDisplay(None)
assert display, 'A working DISPLAY is required'

def key(symbol, down):
    code = x11.XKeysymToKeycode(display, symbol)
    assert code, f'Unmapped keysym {symbol}'
    assert xtst.XTestFakeKeyEvent(display, code, int(down), 0)
    x11.XFlush(display)

def tap(symbol):
    key(symbol, True)
    time.sleep(.25)
    key(symbol, False)
    time.sleep(.25)

def wait_for(predicate, timeout=12):
    deadline = time.monotonic() + timeout
    state = {}
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise AssertionError(f'Packaged game exited {process.returncode}')
        if state_path.exists():
            state = json.loads(state_path.read_text())
            if predicate(state):
                return state
        time.sleep(.05)
    raise AssertionError(f'Expected native game state was not reached: {state}')

log_path = Path('/tmp/inferno-v12-native.log')
with log_path.open('w') as log:
    package_dir = Path(os.environ.get('INFERNO_PACKAGE_DIR', root/'builds/linux'))
    process = subprocess.Popen([str(package_dir/'PLAY.sh'), '--audio-driver', 'Dummy', '--script', str(root/'tests/native_probe.gd')], stdout=log, stderr=subprocess.STDOUT)
    try:
        state = wait_for(lambda s: s['route'] == 'menu')
        assert state['version'] == '0.13.0', state
        tap(ord('f'))
        wait_for(lambda s: s['route'] == 'select')
        tap(ord('f'))
        wait_for(lambda s: s.get('ready', [False, False])[0])
        tap(ord('i'))
        wait_for(lambda s: s['route'] == 'arena')
        tap(0xff0d)  # Return
        initial = wait_for(lambda s: s.get('phase') == 'fight')
        assert initial['modern'], initial
        key(ord('d'), True)
        key(0xff51, True)  # Left
        wait_for(lambda s: s.get('fighters') and s['fighters'][1]['x'] - s['fighters'][0]['x'] <= 100)
        key(ord('d'), False)
        key(0xff51, False)
        moved = wait_for(lambda s: s['fighters'][0]['x'] > 500 and s['fighters'][1]['x'] < 780)
        tap(ord('f'))
        tap(ord('i'))
        hit = wait_for(lambda s: any(f['hp'] < 200 for f in s['fighters']))
        tap(0xff1b)  # Escape
        paused = wait_for(lambda s: s['route'] == 'pause')
        time.sleep(.35)
        frozen = wait_for(lambda s: s['elapsed'] > paused['elapsed'] + .2)
        assert frozen['remaining'] == paused['remaining'], (paused, frozen)
        subprocess.run(['import', '-display', os.environ['DISPLAY'], '-window', 'root', str(output_dir/'native-package.png')], check=True)
        print('NATIVE RESULT: exported 0.13.0 PCK loads; X11 menu/select/fight, two-player movement, damage and pause verified')
        # Return through the actual pause menu and confirmation dialog.
        for _ in range(3): tap(0xff54)  # Down: restart, options, main menu
        tap(0xff0d)
        wait_for(lambda s: s.get('dialog'))
        tap(0xff0d)
        wait_for(lambda s: s['route'] == 'menu')
        for _ in range(4): tap(0xff54)  # Fighters
        tap(0xff0d)
        wait_for(lambda s: s['route'] == 'gallery' and s.get('bones',0) >= 16)
        for index in range(10):
            if index:
                tap(0xff53)  # Right: next roster card
                tap(ord('f'))
            state = wait_for(lambda s: s.get('current') == index and s.get('bones',0) >= 16)
            assert state['triangles'] >= 30000, state
            print(f'NATIVE GALLERY PASS: packaged character {index+1}/10, {state["bones"]} bones')
        subprocess.run(['import', '-display', os.environ['DISPLAY'], '-window', 'root', str(output_dir/'native-gallery.png')], check=True)
        print('NATIVE GALLERY RESULT: all ten packed GLB characters selected through real X11 keyboard input')
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        x11.XCloseDisplay(display)
assert 'SCRIPT ERROR' not in log_path.read_text() and '\nERROR:' not in log_path.read_text(), log_path.read_text()
