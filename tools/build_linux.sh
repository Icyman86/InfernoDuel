#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin=${GODOT_BIN:-godot}
mkdir -p builds/linux
"$godot_bin" --headless --path "$PWD" --export-pack Linux builds/linux/InfernoDuel.pck
# The cloud image has the standard editor engine, but no export templates.
# Bundle that unmodified Linux engine with the PCK: native and self-contained,
# larger than a template export. No download or third-party launcher required.
cp "$(readlink -f "$(command -v "$godot_bin")")" builds/linux/InfernoDuel.x86_64
chmod +x builds/linux/InfernoDuel.x86_64
cp assets/fonts/LICENSE.txt builds/linux/FONT_LICENSE.txt
cp docs/GODOT_LICENSE.txt builds/linux/GODOT_LICENSE.txt
cp docs/GODOT_THIRD_PARTY_NOTICES.txt builds/linux/GODOT_THIRD_PARTY_NOTICES.txt
cat > builds/linux/PLAY.sh <<'PLAY'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec ./InfernoDuel.x86_64 --main-pack InfernoDuel.pck "$@"
PLAY
chmod +x builds/linux/PLAY.sh
cat > builds/linux/README.txt <<'README'
INFERNO DUEL: LEGENDS — Linux prototype v0.1
Made by Rens de Gee en Ted Sondervan

Run ./PLAY.sh on a Linux x86_64 desktop with OpenGL 3.3 support.
This build bundles the unmodified Godot 4.6.3 editor engine and a game PCK,
not a stripped release-template executable. No installed Godot is required.

P1: A/D move, W jump, S block, F light, G heavy, H special, J ultimate.
P2: arrows move/jump/block, I light, O heavy, P special, L ultimate.
ESC pauses. F3 displays hitboxes. Win two rounds to win a match.
Select: P1 WASD + F ready / G undo. P2 arrows + I ready / O undo.
Mouse: choose the P1/P2 edit button before clicking a fighter.

SharkByte and Bullet are playable geometric prototypes. Eight fighters are
coming soon. The gallery contains original concept sheets, not animations.
Story, final character animation, music and Android are later milestones.
Two-person physical keyboard / ghosting testing is still required.
README
printf 'Built: %s/builds/linux/PLAY.sh\n' "$PWD"
