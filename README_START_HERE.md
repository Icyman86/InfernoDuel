# INFERNO DUEL: LEGENDS — Codex-startpakket

**Eerste doel: een speelbare Linux-desktopversie in Godot 4, met lokaal 1-vs-1 op EEN toetsenbord.**
Dit is een ontwerp- en opdrachtenpakket; **het is nog geen gebouwde game**.

## Lees dit eerst

1. Pak de ZIP uit in een nieuwe map, bijvoorbeeld `~/Games/InfernoDuelLegends/`.
2. Start Codex in deze map. Geef Codex de tekst uit `docs/CODEX_STARTPROMPT.md`.
3. Codex leest `AGENTS.md` en de overige ontwerpdocumenten.
4. Laat Codex eerst een Godot-4-project en een werkende **Linux-demo** bouwen.
5. Test lokale versus met twee mensen op hetzelfde fysieke toetsenbord.
6. Pas wanneer Linux-v0.1 werkt: eventueel Android-export plannen.

## Meegeleverde character sheets — 27 oktober 2026

Deze bijgewerkte ZIP bevat **8 echte bestanden uit `Character sheets.zip`**, waaronder de sheets van SharkByte, Spinegrin, Chainveil, de drie klassieke fighters op een gezamenlijk blad en vier nieuwe fighters: Cheese Rat, Lava Stone, Crystal Fang en Phoenix Reign. Alle acht zijn **exact en ongewijzigd** opgenomen in `assets/originals/character_sheets_2026-10-27/`. Bestandsnamen, SHA256-hashes en afmetingen staan in `data/uploaded_character_sheets.json`. Controle: `python3 tools/verify_assets.py`.

**Dit zijn character- en move-referentiebladen, geen kant-en-klare, transparante animatie-spritesheets.** De originele beelden niet overschrijven; maak voor beweging aparte, consistent uitgelijnde transparante frames en gebruik tot dan eerlijk gelabelde placeholders. Zie `docs/GEUPLOADDE_SHEETS_EN_MOVES.md`. Andere, oudere bibliotheekbeelden die niet in deze upload zaten, zijn nog steeds niet allemaal beschikbaar. Eventuele aanvullende originele PNG's kunnen via `assets/originals/_drop_files_here/` worden aangeleverd en met `python3 tools/import_assets.py` gesorteerd.

## Overzicht

- `AGENTS.md` — vaste afspraken voor Codex.
- `docs/GAME_DESIGN_DOCUMENT.md` — doel, sfeer, roster, functies en fasering.
- `docs/MENUS_EN_UI.md` — specifieke schermen, structuur, kleuren en interacties.
- `docs/COMBAT_EN_KEYBOARD.md` — gevechten en 2P-toetsenbordbediening.
- `docs/TECHNIEK_EN_TESTEN.md` — Linux-architectuur en QA.
- `docs/CODEX_STARTPROMPT.md` — kopieerbare eerste taak.
- `docs/ASSET_INVENTARIS.md` — bestaand kunstwerk en assetstatus.
- `docs/GEUPLOADDE_SHEETS_EN_MOVES.md` — de 8 echte uploads, inclusief 4 nieuwe fighters en hun aanvallen.
- `data/uploaded_character_sheets.json` — hashes, bestandsnamen en exacte assetlocaties.
- `tools/verify_assets.py` — controleert de meegeleverde bronbeelden.
- `docs/Inferno_Duel_Legends_Specificatie.docx` — leesbare ontwerpversie.
- `data/fighters.json` — voorgestelde speelbare cast en aanvallen.
- `data/input_layouts.json` — concrete toetsenverdeling.
- `tools/import_assets.py` — niet-destructieve assetimport.

**Projectcredits:** Made by Rens de Gee en Ted Sondervan.
