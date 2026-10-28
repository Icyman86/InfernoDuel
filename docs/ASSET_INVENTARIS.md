# Assetinventaris — bijgewerkt 27 oktober 2026

## Meegeleverd in dit pakket

**8 originele afbeeldingen** uit `Character sheets.zip` zijn nu werkelijk in de ZIP opgenomen. Zie `docs/GEUPLOADDE_SHEETS_EN_MOVES.md` en `data/uploaded_character_sheets.json` voor de exacte bestandsnamen, fighter-koppelingen, afmetingen en SHA256-controle. In totaal vertegenwoordigen ze **10 ontworpen fighters**.

De vier nieuwe fighterbladen zijn JPEG's en de andere vier PNG's. De bestanden zijn kleurillustraties met opgemaakte achtergronden; **geen van deze acht is een transparante, gesegmenteerde animatie-spritesheet**. Voor runtime animatie blijven nog frame-creatie/isolatie en rigging/validatie nodig.

## Niet meegeleverd uit de oudere bibliotheek

Eerdere gesprekken verwezen naar 32 aparte PNG-referenties. Alleen de bestanden die nu echt door de gebruiker in de actuele ZIP zijn aangeleverd, zitten in dit pakket. Oude referenties hieronder zijn een **wishlist**, geen claim dat die al beschikbaar zijn. Sommige namen hebben een analoog uploadbestand (zoals `Spinegrin: ...` versus `Spinegrin_ ...`), maar we vervangen geen exact-bestandsnaam stilzwijgend.

## Eerder geïdentificeerde extra bibliotheekassets (optioneel)

- `Spinegrin: Inferno Duel Character Sheet.png`
- `Chainveil: Inferno Duel Character Sheet.png`
- `Inferno_FighterArt_Bullet.png`
- `Inferno_FighterArt_Nachtelf.png`
- `Inferno_FighterArt_Poisonboy.png`
- `Inferno_Bullet_Sprite_Vergelijking.png`
- `Inferno_Nachtelf_Sprite_Vergelijking.png`
- `Inferno_PoisonBoy_Sprite_Vergelijking.png`
- `Inferno_FighterArt_Concepts.zip` (bronarchief, indien je het hebt)

## Extra referentiemateriaal

Zie de volledige exacte lijst in `data/asset_manifest.csv`. Andere oude referenties (nog niet meegeleverd) omvatten onder meer `Dark Fantasy Fighter Roster Sheet.png`, `Inferno Duel: Legends Game UI Showcase.png`, `Inferno Duel: Legends Promotional Game Poster.png` en `Inferno_Legends_Gameplay.png`.

## Zo voeg je aanvullende beelden toe

1. Download of exporteer de beelden uit de eerdere Rens poppetjes-conversaties of je ChatGPT Library, of pak je eigen lokale spritesmap.
2. Zet de PNG's *ongewijzigd* in `assets/originals/_drop_files_here/`.
3. Voer vanaf de projectroot `python3 tools/import_assets.py` uit. Het script maakt kopieën in categorie-mappen, bewaart alle originele bestanden en schrijft `docs/ASSET_REPORT.md`.
4. Open de echte assets en beoordeel: transparante achtergrond, losse animatieframes, gelijke outfit in alle frames, camerahoek, pivot, schaal en licentiestatus.
5. Zet alleen echte, gevalideerde spriteframes onder `assets/sprites/`.

Codex mag tot dan bewegende placeholders gebruiken. Visueel ontwerp wordt op de bestaande character sheets gebaseerd; geen nieuwe canon of artstyle zonder toestemming.
