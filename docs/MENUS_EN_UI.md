# Actuele V17-menu's

STORY MODE opent vier opeenvolgende duels met SharkByte, met eigen briefings,
checkpoint/retry en coins. De levelkaart toont Bullet in de Citadel, Nachtelf in
zijn bos, Spinegrin op zijn schip en Crystal Fang in zijn mijn. Zie
[V17 Android](V17_ANDROID.md). De oude specificatie hieronder beschrijft eerdere
milestones; FIGHTERS gebruikt inmiddels twaalf grote 2D-illustraties en het
hoofdmenu kiest twee verschillende, afzonderlijk gekaderde willekeurige fighters.

# Menu- en UI-specificatie (Pixel-independent Godot UI)

**Basisresolutie:** 1280×720, breedbeeld, desktop/landscape. Godot Controls/Containers/anchors; niet op exacte screenshotpixels vastspijkeren. Safe margins ≥36 px aan alle kanten. Gebruik `canvas_items`-schaalgedrag, vaste interne verhoudingen, 16:9 voorkeursaspect.

## A. Startscherm / Main Menu

**Beeldcompositie**: donkere, filmische achtergrond met een kapotte stenen arena, rook, gloeiende lava-spleten en twee vervaagde fighter-silhouetten links/rechts. Titel groot op x≈50%, y≈18%. `INFERNO` in ivoor en `DUEL: LEGENDS` met oranje gouden rand en rode gloed. Onder de titel kleine regel `ENTER THE ARENA`.

**Interactieve knoppen in de middenkolom, y≈38–80%, breedte ±390 px**:
1. `LOCAL VERSUS` (primair, goud/oranje highlight) — twee spelers, één toetsenbord.
2. `SOLO VS CPU` — tegen basis-AI.
3. `STORY MODE` — voor v0.1 opent een 'Binnenkort'-scherm met SharkByte-teaser; v0.3 functioneel.
4. `FIGHTERS` — galerij/rosterdetails; bij ontbrekende assets een fallback-panel.
5. `OPTIONS` — audio, display en controls.
6. `QUIT` — vraagt bevestiging indien passend.

**Onderin, volledig leesbaar:** `Made by Rens de Gee en Ted Sondervan` (geen alternatieve creditregel). Rechtsonder klein versieveld `Linux Prototype v0.1`. Geen Android-buttons tonen in Linux-build.

**Focus/interactie:** P1 kan menu bedienen met W/S + F (confirm) en pijltjes + Enter; Esc terug. Muis werkt. Een geselecteerde button verandert outline, subtiele vuurglans en wordt iets groter; knopnamen blijven in hoofdletters.

```text
┌──────────────────────────────────────────────────────────────────────┐
│                      INFERNO DUEL: LEGENDS                           │
│                       ENTER THE ARENA                               │
│                                                                      │
│                        [ LOCAL VERSUS ]                              │
│                        [ SOLO VS CPU ]                               │
│                        [ STORY MODE ]                                │
│                        [ FIGHTERS ]                                  │
│                        [ OPTIONS ]                                   │
│                        [ QUIT ]                                      │
│                                                                      │
│ Made by Rens de Gee en Ted Sondervan          Linux Prototype v0.1    │
└──────────────────────────────────────────────────────────────────────┘
```

## B. Character Select

**Background:** blurred arena with dust/flame motes, low contrast so portraits pop. Header `CHOOSE YOUR FIGHTER`. Top-left player-1 highlighted cyan `P1`; top-right player-2 amber `P2`. Center roster 5 columns × 2 rows for **10 fighter cards** (of adaptive scroll/flow when readability suffers). Maak minimaal 2 profielen volledig speelbaar en markeer de overige als COMING SOON tot gevechtsprofiel klaar is. Gebruik originele character sheets als artworkreferentie; whole sheets zijn geen schone portretten. Footer shows a control legend per player and `F / I = Select` only when those are mapped to select; Esc = Back.

**Rooster** (standaard volgorde): SharkByte / Bullet / Nachtelf / PoisonBoy / Spinegrin / Chainveil / Cheese Rat / Lava Stone / Crystal Fang / Phoenix Reign. Each card: portrait, all-caps name, fighting archetype tag, availability. Both players independently change focus; left/right can select same fighter and each gets distinguishable player color/outline. If identical fighter, use alternate palette overlay for P2; do not mirror portraits into incorrect clothing design.

Below grid: two opposing large preview panels. `READY` requires both players confirming; character-specific previews show specialty and control hint. In solo, second slot marked `CPU` with difficulty Easy/Normal (only Easy required v0.1).

**Navigation:** P1 `A/D` navigate, `W/S` row, `F` confirm and `G` unconfirm; P2 arrow keys navigate, `I` confirm `O` unconfirm. For stage selection after both ready, show one available stage; Enter starts match; Esc returns. Buttons always clickable.

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│ P1: SHARKBYTE       CHOOSE YOUR FIGHTER             P2: CHAINVEIL           │
│                                                                               │
│ [SHARKBYTE] [BULLET] [NACHTELF] [POISONBOY] [SPINEGRIN]                    │
│ [CHAINVEIL] [CHEESE RAT] [LAVA STONE] [CRYSTAL FANG] [PHOENIX REIGN]         │
│                                                                               │
│   P1 portrait + stats           VS            P2 portrait + stats            │
│                                                                               │
│          P1 READY                          P2 READY                          │
│    A/D/W/S + F                       Arrows + I                [BACK]          │
└───────────────────────────────────────────────────────────────────────────────┘
```

## C. Arena Selection (v0.1)

`CHOOSE ARENA` centered heading; one large landscape thumbnail `INFERNAL CITADEL` with molten lava, ruined cathedral arches, scattered embers. Left and right slots for future arenas shown as locked silhouettes but not interactive. Selected thumbnail gold frame. `ENTER / F = FIGHT`, `ESC = BACK`.

## D. Fight Screen / HUD

- Top-left P1 name + portrait + cyan accent, HP bar from left toward center; top-right P2 in amber with mirrored bar direction.
- Timer in gold-framed circular/hex central panel: `60` decreasing each second; below `ROUND 1`.
- Super meter below HP bars (0–100), sparks only near full, special visual meter on Spinegrin's back synced.
- Round win markers dots/diamonds near names; 2 wins required.
- Gameplay occupies central 80% of scene; floor baseline ≈80–85% viewport height.
- Popups 2–5 hits `3 HIT COMBO`, block spark, KO, VICTORY; effects don't cover critical HP/timer.
- Pause overlay uses black blur with `RESUME`, `RESTART MATCH` (confirmation), `OPTIONS`, `MAIN MENU` (confirmation).

## E. Result / Rematch

Center winner character (original artwork or fallback silhouette), huge `P1 WINS` / `P2 WINS` / `DRAW`, score `2 : 1`. Backdrop darker with arena still visible. Selectable `REMATCH`, `CHARACTER SELECT`, `MAIN MENU`. Both players can navigate or use mouse. On rematch HP/timers reset and fighters retain chosen character; no accidental input carry-over.

## F. Options

Left section `VIDEO`: Fullscreen [On/Off], window size 1280×720 default; use borderless toggle later. Right `AUDIO`: Master / Music / SFX sliders. Bottom `CONTROLS`: visually show P1 and P2 mapping side by side, warn about keyboard ghosting. `RESET DEFAULTS`, `BACK`. Save settings to `user://settings.cfg` or equivalent ConfigFile.

## G. Fighter Gallery / Future Story

Gallery shows ten tiles + large fighter-art preview, biography snippets, move overview. `STORY MODE` in v0.1 is a **working informational screen** rather than an unresponsive button. Later cinematic chapter map shows SharkByte path and unlock badges.

## Responsive / Navigation / Accessibility

All key instructions visible; no tiny text <18 px at 720p for essential instructions. Focus clearly distinguished. UI works with only keyboard, except optional mouse. Disable gameplay input when overlays active. Button hover, focus, pressed, disabled states implemented. Do not use raster screenshot as UI element, instead rebuild with Godot Controls and anchors.
