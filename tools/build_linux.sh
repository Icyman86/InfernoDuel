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
INFERNO DUEL: LEGENDS — Linux V13 / 0.13.0 gallery update
Made by Rens de Gee en Ted Sondervan

Run ./PLAY.sh on Linux x86_64 with OpenGL 3.3.
This self-contained package includes the matching Godot engine and game PCK.

Local Versus / Solo use the new Gladiator Crucible 3D prototype.
FIGHTERS now presents ten detailed original Blender volume models with real
16-bone skins, idle animation, normal maps, cloth/leather/skin/metal materials,
faces, fingers and character-specific silhouettes. About 89k-128k triangles each.
The gallery keeps the entire character large in frame, including wings/tails.
Drag to rotate; use TURN, PORTRAIT VIEW / FULL BODY and ORIGINAL SHEET.
The arena combat renderer retains its V12 prototype models and mechanics.
The new gallery models are a stylized artist/programmatic interpretation;
they are not a claim of AAA or photorealistic character production.

Ten original procedural articulated COMBAT volume models; no sprite billboards.
These simple stylized COMBAT models and procedural animation are NOT production-quality
modern fighter assets. Detailed sculpted models, skinning, textures and authored
animation polish are still missing. Previous portraits/gallery/intros are kept.

P1: A/D move, W jump, S block, F/G/H/J light/heavy/special/ultimate.
P2: arrows move/jump/block, I/O/P/L attacks.
P1 R grab / T break free. P2 U grab / K break free.
Controllers: first connected = P1; second = P2. Left stick or D-pad move,
A jump, X light, Y heavy, B special, LT block, RT ultimate, LB grab/throw,
RB break free (35 meter), Start pause. Unplugging pauses the match.
Menus: D-pad/stick navigate, A confirm, B back. In selection A/X ready,
Y undo. Solo: Start readies your fighter and CPU opponent.

Down, down-forward, forward + special within 380 ms: Rising Breaker (22 damage).
Forward, neutral, forward + heavy within 380 ms: Momentum Strike (18 damage).
Forward/backward are relative to your opponent. Down uses your BLOCK control.
Close grounded grab range is 115 units; hold backward to reverse the throw.
Defender LB/grab within 220 ms techs the grab. Simultaneous grabs also tech.
Throws deal 18 damage and grant 1.3 s regrab protection.
RB/escape breaks stun or a clamp for 35 meter with a 3 s cooldown.
Gold floor rings warn for 1.2 s before a 0.45 s clamp activation. Jump or move
away; a caught fighter is stunned for 0.75 s, with no trap damage. Each trap
cycles every eight seconds; the two traps are offset by 3.6 seconds.
Escape or wait to recover. F3 displays actual collision boxes in 3D.
Heavy clean hits add 50 ms hitstop. Best of three; 200 HP; 60-second rounds.

LAN sessions retain the previous 2D combat rules/rendering and no new local
V12 actions. Both devices need the same app version. Existing published Android
APKs are preserved. No Android/iOS V12 build is included.
No physical controller or two-person hardware acceptance is claimed.

README
printf '\nEngine package: %s\n' "$engine_kind" >> builds/linux/README.txt
printf 'Built: %s/builds/linux/PLAY.sh\n' "$PWD"
