#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin=${GODOT_BIN:-godot}
mkdir -p builds/linux
"$godot_bin" --headless --path "$PWD" --export-pack Linux builds/linux/InfernoDuel.pck
template_path=${GODOT_LINUX_TEMPLATE:-/workspace/.runtime/godot/linux_release.x86_64}
engine_kind="standard Godot engine"
if [ -x "$template_path" ]; then
  editor_version=$("$godot_bin" --version)
  template_version=$("$template_path" --headless --version)
  if [ "$editor_version" != "$template_version" ]; then
    printf 'Godot editor/template version mismatch: %s / %s\n' "$editor_version" "$template_version" >&2
    exit 1
  fi
  cp "$template_path" builds/linux/InfernoDuel.x86_64
  engine_kind="official Linux release template $template_version"
else
  cp "$(readlink -f "$(command -v "$godot_bin")")" builds/linux/InfernoDuel.x86_64
fi
chmod 755 builds/linux/InfernoDuel.x86_64
cp assets/fonts/LICENSE.txt builds/linux/FONT_LICENSE.txt
cp docs/GODOT_LICENSE.txt builds/linux/GODOT_LICENSE.txt
cp docs/GODOT_THIRD_PARTY_NOTICES.txt builds/linux/GODOT_THIRD_PARTY_NOTICES.txt
cat > builds/linux/PLAY.sh <<'PLAY'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec ./InfernoDuel.x86_64 "$@"
PLAY
chmod 755 builds/linux/PLAY.sh
cat > builds/linux/README.txt <<'README'
INFERNO DUEL: LEGENDS — Linux full roster V6 / v0.6.0
Made by Rens de Gee en Ted Sondervan

Run ./PLAY.sh on a Linux x86_64 desktop with OpenGL 3.3 support.
This build bundles the Godot engine and a game PCK. No installed Godot is required.

P1: A/D move, W jump, S block, F light, G heavy, H special, J ultimate.
P2: arrows move/jump/block, I light, O heavy, P special, L ultimate.
ESC pauses. F3 displays hitboxes. Win two rounds to win a match.
Select: P1 WASD + F ready / G undo. P2 arrows + I ready / O undo.
Mouse: choose the P1/P2 edit button before clicking a fighter.

All ten fighters are playable: SharkByte, Bullet, Nachtelf, PoisonBoy, Spinegrin,
Chainveil, Cheese Rat, Lava Stone, Crystal Fang and Phoenix Reign.
FIGHTERS has a live animated move lab: tap/click any move to execute it, or leave
AUTO on for a tour. ORIGINAL SHEET and PLAY INTRO preserve all reference art.
The 69 attacks/abilities include directional variants: hold forward, backward
or guard plus LIGHT, SPECIAL or ULT. The move lab lists every exact binding.
Armor halves damage; power buffs add 20%; Phoenix Rebirth spends 35 meter to
escape hitstun and heal 8 HP. Supers cost 100 meter and cannot revive a KO.
Each short intro opens on footwear (original claws for Crystal Fang/Phoenix
Reign), then a front kick toward camera. REPLAY restarts; Esc/BACK returns.
Original reference sheets are preserved. New sprite/intro art is reference-guided.
CONNECT uses direct session codes between devices on the same reachable Wi-Fi.
Android has one touchpad per device; offline CPU remains available.
Rendering follows native device/window pixels; the arena preserves its proportions.
Android touch play is available as a separate V6 APK. Story and music are later milestones.
Two-person physical keyboard / ghosting testing is still required.
README
printf '\nEngine package: %s\n' "$engine_kind" >> builds/linux/README.txt
printf 'Built: %s/builds/linux/PLAY.sh\n' "$PWD"
