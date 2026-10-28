# Inferno Duel: Legends — Linux v0.3.0

[Download Linux x86_64](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.3.0/releases/v0.3.0/InfernoDuel-Linux-v0.3.tar.xz)

[Watch the intro preview](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.3.0/releases/v0.3.0/InfernoDuel-IntroPreview-v0.3.mp4)

Extract the archive and run `InfernoDuel-Linux/PLAY.sh`. A Linux x86_64 desktop
with OpenGL 3.3 is required; no separate Godot installation is needed.

- Five playable fighters: SharkByte, Bullet, PoisonBoy, Chainveil and Cheese Rat.
- Bullet, Nachtelf and PoisonBoy each have their own gallery sheet view.
- All ten fighters have a **PLAY INTRO** button in FIGHTERS. Each 720p film
  opens on footwear, then shows a kick toward camera. Crystal Fang and Phoenix
  Reign retain their original claw feet. BACK/Esc returns; REPLAY restarts.
- PoisonBoy has Toxic Splash / Venom Cataclysm, Chainveil has Chain Lash / Iron
  Widow with pull, and Cheese Rat has Cheese Ball / King of the Cheese.
  Hold backward + special to place Cheese Trap.

P1: A/D move, W jump, S block, F light, G heavy, H special, J ultimate.
P2: arrows move/jump/block, I light, O heavy, P special, L ultimate.
F/I ready in selection; Enter enters the arena. Esc pauses. F3 shows hitboxes.

Gameplay source revision: `d3e6e0e3c8732f1ac46b324aa97a3e054ef21c78`.
Bundle: official Godot 4.6.3 Linux release template plus adjacent PCK, licenses,
validation logs and source hashes. `SHA256SUMS` verifies the archive and preview.
All eight original sheet hashes match. New sprites and intro key art are
reference-guided generated derivatives; films use key poses and camera motion.

Validation: 344 gameplay/artwork checks, 40 rendered checks and ten complete
film decodes passed. The native package also passed X11 menu/gallery/intro,
PoisonBoy-versus-Chainveil combat, pause and Quit checks. These are automated
checks. Physical keyboard rollover, two-person play, speaker output and final
balance need manual acceptance. Five other combat characters remain in development.

Made by Rens de Gee en Ted Sondervan.
