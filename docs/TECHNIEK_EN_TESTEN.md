# Linux-first technische uitvoering en testplan

## 1. Vereisten

Godot 4 stable standaardeditor (geen Mono/.NET vereist), GDScript, Linux met grafisch bureaublad. Richt je op Linux x86_64. Project start met `project.godot`; geen Android Studio in deze fase. Zet renderer `gl_compatibility`/Compatibility. Project window 1280×720, resizable en fullscreen optie.

## 2. Voorgestelde scenes

```text
res://
  project.godot
  scenes/main.tscn
  scenes/ui/main_menu.tscn
  scenes/ui/character_select.tscn
  scenes/ui/arena_select.tscn
  scenes/ui/options.tscn
  scenes/ui/fighter_gallery.tscn
  scenes/ui/story_preview.tscn
  scenes/ui/pause_menu.tscn
  scenes/ui/result_screen.tscn
  scenes/combat/match.tscn
  scenes/combat/fighter.tscn
  scenes/combat/hitbox.tscn
  scenes/arenas/infernal_citadel.tscn
  scripts/core/game_state.gd
  scripts/core/input_router.gd
  scripts/core/save_manager.gd
  scripts/combat/fighter_controller.gd
  scripts/combat/match_controller.gd
  scripts/combat/attack_data.gd
  scripts/combat/ai_controller.gd
  scripts/ui/*.gd
  assets/reference/...  # concept art, nooit als automatisch spritesheet
  assets/sprites/...     # alleen gescheiden, gevalideerde frames
```

Splits scenes en niet 1 gigantisch script. Toetsen in InputRouter; fight-scène ontvangt twee aparte PlayerInput objecten. Solo AI stuurt dezelfde inputinterface aan als een speler.

## 3. Visuals asset-pipeline

- `assets/originals`: handmatig teruggehaalde ruwe bronbeelden (niet bewerken).
- `assets/reference`: concept- en rosterplaten om naar te kijken, NIET als animatiebron gebruiken zonder inspectie.
- `assets/sprites`: alleen transparante individuele frames of correct gedocumenteerde grid-sheets met uniforme afmetingen, pivots, animatievolgorde.
- Maak optioneel per fighter JSON/metadocument: idle, run, jump, light, heavy, special, ultimate, hit, block, KO, win. Voor ontbrekende animaties: visueel heldere placeholder.
- Teken nooit grafische bron-elementen automatisch opnieuw met een 'vergelijkbare stijl' als de echte PNG wel nodig is.

## 4. Fases met 'go/no-go'

### Milestone M0 — Scaffold
`project.godot`, opstartscene, menu en credits; start met F5. Geen parsefouten. Git repository en README.

### M1 — Keyboard local versus
2 onafhankelijke inputstreams, twee simpele fighters, één arena, lopen en springen. Test beide gelijktijdig.

### M2 — Complete loop
Selectie, HP/timer/rounds, attacks, hitboxes, supermeter, pause, result, rematch, CPU. Dit is **Linux-v0.1**.

### M3 — Visual upgrade
Import gevalideerde echte assets, animatie- en FX-pipeline; tien unieke specials; UI polish.

### M4 — Linux export
Godot export templates, export Linux x86_64 (of bundel project + command), voer export uit en start hem buiten editor. Schrijf uitvoerinstructies.

### Later — Story en Android
Na akkoord en werkende Linux basis; voorkom scopecreep.

## 5. Verifiëren

Gebruik waar beschikbaar (pas `godot` aan voor de binary op de host):

```bash
godot --version
godot --headless --path . --editor --quit
godot --path .
```

Documenteer exit code, parse errors en runtime errors. Headless parse-check is niet hetzelfde als een echte speeltest of screenshot. Vereis handmatige 2P-test via één keyboard (of gesimuleerde code-input met testharnas). Test window resize, fullscreen, loss of focus, pause, rematch en exit. Schrijf `docs/TEST_LOG.md` met datum, buildhash, uitgevoerde stappen, resultaat, bugs en bekende asset-gaten. Geen 'werkt' claim zonder echte run.

## 6. Definition of Done M2

- Godot Linux F5 start title menu en geen runtime errors in de flow.
- UI: Menu -> Local Versus -> Select -> Arena -> Fight -> Results -> Rematch -> Menu.
- P1 en P2 **tegelijk actief** op één keyboard, attack-, movement- en blok-acties getest.
- Health, timer, round, KO, win, ultimate meter, blocks en één eenvoudige combo werken.
- Solo CPU kan vechten, geen onverslaanbare permanent block loop.
- Game over/menu pauzeert/stop gameplay en timers correct.
- Export Linux-procedure gedocumenteerd en export indien export templates aanwezig.
- Openstaande art-items duidelijk gemarkeerd, geen placeholders voorgesteld als definitieve sprites.
