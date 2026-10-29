"""Validate exported Godot/Xcode data or a real device IPA, without Apple secrets."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import plistlib
import struct
import zipfile


def pack_files(raw):
    stream = io.BytesIO(raw)
    def read(fmt):
        return struct.unpack(fmt, stream.read(struct.calcsize(fmt)))
    magic, version, major, minor, patch, flags = read('<6I')
    assert magic == 0x43504447 and version in (2, 3), 'Invalid Godot PCK'
    assert (major, minor, patch) == (4, 6, 3), 'Godot engine mismatch'
    assert not flags & 1, 'Encrypted directory is unexpected'
    base, = read('<Q')
    if version == 3:
        directory, = read('<Q')
        stream.seek(directory)
    else:
        stream.seek(16*4, 1)
    count, = read('<I')
    files = {}
    for _ in range(count):
        length, = read('<I')
        name = stream.read(length).decode().rstrip('\0').removeprefix('res://')
        offset, size = read('<2Q')
        digest = stream.read(16)
        file_flags, = read('<I')
        assert not file_flags & 1, 'Encrypted file is unexpected'
        data = raw[base+offset:base+offset+size]
        assert len(data) == size and hashlib.md5(data).digest() == digest, 'PCK data mismatch: '+name
        files[name] = data
    return files


def verify_pack(raw):
    files = pack_files(raw)
    assert not any(name.startswith(('tests/', 'releases/', 'docs/', 'builds/')) for name in files)
    for script in ['core/game_platform', 'ui/game', 'ui/touch_controls', 'combat/action_pose_fields', 'ui/ultimate_gauge', 'network/session_discovery']:
        assert 'scripts/'+script+'.gdc' in files, 'Missing compiled script '+script
    fighters = json.loads(files['data/fighters.json'])['fighters']
    assert len(fighters) == 10 and all(f['playable'] for f in fighters)
    assert sum(map(len, json.loads(files['data/move_sets.json']).values())) == 69
    actions = json.loads(files['data/action_motion_fields.json'])
    assert sum(len(p['clips']) for p in actions['profiles'].values()) == 49
    for fighter in fighters:
        assert 'assets/intros/'+fighter['id']+'.ogv' in files
    print('IOS PCK PASS: every file hash; ten fighters, 69 moves, 49 action clips, ten films, compiled touch/iOS code')


def verify_plist(info):
    assert info['NSLocalNetworkUsageDescription'].strip()
    for key in ['UISupportedInterfaceOrientations', 'UISupportedInterfaceOrientations~ipad']:
        assert all('Landscape' in orientation for orientation in info[key]), key
    assert not info.get('UIFileSharingEnabled', False)


def verify_project(folder):
    project = (folder/'InfernoDuel.xcodeproj/project.pbxproj').read_text()
    for expected in ['IPHONEOS_DEPLOYMENT_TARGET = 15.0', 'MARKETING_VERSION = 0.9.0', 'CURRENT_PROJECT_VERSION = 900', 'PRODUCT_BUNDLE_IDENTIFIER = org.infernoduel.legends']:
        assert expected in project, expected
    info = plistlib.loads((folder/'InfernoDuel/InfernoDuel-Info.plist').read_bytes())
    verify_plist(info)
    entitlements = plistlib.loads((folder/'InfernoDuel/InfernoDuel.entitlements').read_bytes())
    assert 'com.apple.developer.networking.multicast' not in entitlements
    framework = plistlib.loads((folder/'InfernoDuel.xcframework/Info.plist').read_bytes())
    assert any(item['LibraryIdentifier'] == 'ios-arm64' for item in framework['AvailableLibraries'])
    assert (folder/'InfernoDuel.xcframework/ios-arm64/libgodot.a').stat().st_size > 1000000
    verify_pack((folder/'InfernoDuel.pck').read_bytes())
    print('IOS XCODE PROJECT PASS: iOS 15+, arm64 device engine, landscape, local-network prompt; no signed IPA claimed')


def verify_ipa(path):
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, 'IPA CRC failure'
        plists = [n for n in archive.namelist() if n.startswith('Payload/') and n.count('/') == 2 and n.endswith('.app/Info.plist')]
        assert len(plists) == 1, 'IPA must contain one app under Payload'
        prefix = plists[0].removesuffix('Info.plist')
        info = plistlib.loads(archive.read(plists[0]))
        verify_plist(info)
        assert info['CFBundleIdentifier'] == 'org.infernoduel.legends'
        assert info['CFBundleShortVersionString'] == '0.9.0' and info['CFBundleVersion'] == '900'
        assert info['CFBundleSupportedPlatforms'] == ['iPhoneOS'], 'Simulator build is not installable'
        assert tuple(map(int, info['MinimumOSVersion'].split('.'))) >= (15, 0)
        binary = archive.read(prefix+info['CFBundleExecutable'])
        magic, cpu, _, kind, commands, _, _, _ = struct.unpack_from('<8I', binary)
        assert magic == 0xFEEDFACF and cpu == 0x0100000C and kind == 2, 'Expected a real ARM64 Mach-O app executable'
        position = 32
        device = False
        for _ in range(commands):
            command, length = struct.unpack_from('<2I', binary, position)
            if command == 0x32:
                device = struct.unpack_from('<I', binary, position+8)[0] == 2
            if command in (0x21, 0x2C):
                assert struct.unpack_from('<I', binary, position+16)[0] == 0, 'Encrypted Store binary cannot be re-signed'
            position += length
        assert device, 'Mach-O must target iPhoneOS devices'
        packs = [name for name in archive.namelist() if name.startswith(prefix) and name.endswith('.pck')]
        assert len(packs) == 1, 'Missing game pack'
        verify_pack(archive.read(packs[0]))
        assert prefix+'embedded.mobileprovision' not in archive.namelist(), 'Unsigned sideload build must not embed a private provisioning profile'
    print('IOS IPA PASS: real ARM64 iPhoneOS executable, bundle/version/plist, CRCs and game payload. AltStore signing still required.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa', nargs='?', type=Path)
    parser.add_argument('--project', type=Path)
    args = parser.parse_args()
    if args.project:
        verify_project(args.project)
    elif args.ipa:
        verify_ipa(args.ipa)
    else:
        parser.error('Provide an IPA or --project directory')
