# Codex werkafspraken — Inferno Duel: Legends

## Doel en prioriteit
Bouw een **native Godot-4 / GDScript game voor Linux eerst**. Fase 1 moet op Linux draaien via F5 en een export naar Linux x86_64 kunnen maken. Geen HTML-wrapper, geen browserafhankelijkheid, geen Android-project in de eerste milestone.

## Volgorde
1. Lees README en alle docs. Inventariseer echte bestanden.
2. Maak `project.godot`, basis-scènes en een werkende title/menu flow.
3. Maak een centrale InputRouter die 2 spelers op **hetzelfde fysieke toetsenbord** tegelijk ondersteunt.
4. Maak een eenvoudig maar eerlijk 2D-fightprototype met gedeelde Fighter-controller, hitboxes, AI en health/timer.
5. Maak Character Select, arena, HUD, pauze en rematch.
6. Gebruik de ECHT meegeleverde, ongewijzigde sheets uit `assets/originals/character_sheets_2026-10-27/` als **visuele referentie**, maar vervang placeholders in runtime alleen wanneer losse transparante animatieframes zijn gevalideerd. De echte sheets zijn geen kant-en-klare animaties.
7. Test en documenteer resultaat; maak daarna Linux-export.

## Grenzen
- Niet overstappen op Unity/Unreal/HTML zonder expliciete toestemming.
- Geen nep-sprites genereren en doen alsof het de originele tekeningen zijn.
- Inspecteer vóór artworkwerk `data/uploaded_character_sheets.json` en `docs/GEUPLOADDE_SHEETS_EN_MOVES.md`. De karakterbronbeelden zijn in dit pakket opgenomen; maak geen willekeurige varianten.
- Er zijn **10 roster-fighters** in het ontwerp. Vier nieuwe (Cheese Rat, Lava Stone, Crystal Fang, Phoenix Reign) zijn toegevoegd vanuit de huidige upload. Focus in eerste Linux-prototype op twee speelbare profielen; de roster/data moet uitbreidbaar blijven naar tien.
- De controllerbutton-symbolen op JPEG-movebladen zijn voorbeelden en GEEN basis voor de Linux-inputmap; `data/input_layouts.json` bepaalt één-toetsenbord-P1/P2 bediening.
- Geen IP/merklogo's namaken op kleding; gebruik de oorspronkelijke ontwerpintentie.
- Maak geen claims over implementatie of tests die niet echt zijn uitgevoerd.
- Maak `story` en Android pas actief volgens latere mijlpalen.
- Verwijder of wijzig nooit oorspronkelijke artwork-bestanden.
- Hanteer consequent GDScript, herbruikbare Scenes/Resources en Git-commits per mijlpaal.
- Iedere button moet werken of duidelijk naar een 'in ontwikkeling'-scherm navigeren; nooit stille dode knoppen.

## Definitie van klaar (v0.1 Linux)
- Project opent in geïnstalleerde stabiele Godot 4 zonder parsefouten.
- Main Menu -> Local Versus -> Character Select -> Fight -> Result -> Rematch/Main Menu.
- P1 en P2 bewegen tegelijk en voeren gelijktijdig aanvallen uit op EEN toetsenbord.
- Minstens twee fighters/placeholderprofielen met identieke basis-bewegingen; SharkByte is standaard P1. In character select kunnen overige acht slots bestaan en expliciet als nog niet volledig speelbaar gemarkeerd worden. Geen dode knoppen.
- Blocking, heavy/light, special, ultimate, meter, knockback, hitstun, HUD, timer en best-of-three werken.
- Intro en menu hebben de tekst 'Made by Rens de Gee en Ted Sondervan'.
- Testresultaten staan in `docs/TEST_LOG.md` incl. bekende problemen.
- Er is een herhaalbare Linux exportinstructie; geen Android-afhankelijkheid.

## Als input ontbreekt
Maak een expliciete TODO met bestandsnaam, kies tijdelijke geometrische placeholders voor runtime, en ga door. Vraag niet voor elke ontbrekende asset om toestemming. Meld het in TEST_LOG en ASSET_REPORT.
