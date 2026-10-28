# Eerste opdracht voor Codex — kopieer deze tekst

Je bent de leidende Godot 4 / GDScript programmeur van **Inferno Duel: Legends**.

**Bouw nu een echt startbaar native Linux-project, niet een webgame en nog niet Android.** Ik ben volledig nieuw in Godot. Werk in de map waar `AGENTS.md` staat en lees ALLE documenten onder `docs/` vóór je programmeert.

Niet-onderhandelbare eisen:
- Offline local versus met **twee spelers op hetzelfde toetsenbord**, gelijktijdige input.
- SharkByte is hoofdfighter; het roster telt nu 10: SharkByte, Bullet, Nachtelf, PoisonBoy, Spinegrin, Chainveil, Cheese Rat, Lava Stone, Crystal Fang, Phoenix Reign.
- De 8 **originele character-/movesheets** zijn daadwerkelijk toegevoegd onder `assets/originals/character_sheets_2026-10-27/`. Verifieer ze met `python3 tools/verify_assets.py` en lees `docs/GEUPLOADDE_SHEETS_EN_MOVES.md`. Dit zijn NIET automatisch speelbare transparante spriteframes.
- Ontwerp datagedreven voor alle 10 fighters, maar maak eerst 2 volledig functionerende speelbare profielen. Overige profielen mogen in de eerste build als `COMING SOON` getoond worden, mits de gebruiker dat begrijpt en er geen dode bediening is.
- Sfeer en schermindeling volgen `docs/MENUS_EN_UI.md`; originele fighter-art stijl B blijft uitgangspunt.
- Linux keyboard mapping exact volgens `docs/COMBAT_EN_KEYBOARD.md`.
- Maak minstens de volledige M0/M1, en werk daarna aan M2 in uitvoerbare tussenstappen.
- Gebruik de meegeleverde character sheets voor portretten en ontwerp-REFERENTIE, mits de compositie daarvoor geschikt is. Maak noch pretendeer animaties uit een heel artworkblad. Ontbrekende losse animatieframes? Tijdelijke geometrische placeholders met eerlijke labels. Geen willekeurige vervangende characterimages.
- Bouw menu, char select, arena, gevecht, HP-bars, aanval/hitstun, meter, timer, best-of-three, pause, uitslag, rematch. CPU voor solo.
- Zorg dat `Made by Rens de Gee en Ted Sondervan` zichtbaar is op het openingsscherm.

Werkwijze:
1. Inventariseer map, assets en gebruikte Godot-versie.
2. Maak een heldere bouwvolgorde en begin meteen met bestanden aanmaken.
3. Maak een werkend project waarmee ik op Linux via F5 kan starten.
4. Voer beschikbare parse/headless checks uit; vermeld exact wat is getest.
5. Schrijf `docs/TEST_LOG.md` en `docs/ASSET_REPORT.md` met eerlijke resultaten.
6. Maak alleen kleine overzichtelijke scripts/scenes en documenteer controls.
7. Zeg in het Nederlands hoe ik moet starten, hoe P1/P2 spelen en wat de volgende mijlpaal is.

Prioriteit: **één volledig speelbare Linux 2-player match boven veel halfwerkende features**.
