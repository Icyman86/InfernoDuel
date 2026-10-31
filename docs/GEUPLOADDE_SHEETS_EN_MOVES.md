# Acht originele character sheets + vier nieuwe fighters (27 oktober 2026)

**Bron:** originele `Character sheets.zip` van de gebruiker. Alle 8 afbeeldingen staan 1:1 (niet bijgesneden, geen hercompressie) onder `assets/originals/character_sheets_2026-10-27/`.

**Status:** concept-, pose- en movesheets; ALLE afbeeldingen zijn RGB met ingetekende achtergronden/tekst. Geen bestand is al een spritesheet met losse transparante animatieframes. Gebruik ze als design-reference en evt. tijdelijke gallery-art; maak karakteranimaties los met consistente body-perspectieven en transparantie.

## Exacte bestandskoppeling

| Fighter(s) | Origineel bestand in assets/originals/character_sheets_2026-10-27/ |
|---|---|
| SharkByte | `SharkByte Fighting Game Character Sheet.png` |
| Spinegrin | `Spinegrin_ Inferno Duel Character Sheet.png` |
| Chainveil | `Chainveil_ Inferno Duel Character Sheet.png` |
| Bullet, Nachtelf, PoisonBoy | `Dark Fantasy Fighting Game Character Sheet.png` |
| Cheese Rat | `WhatsApp Image 2026-10-25 at 18.59.15.jpeg` |
| Lava Stone | `WhatsApp Image 2026-10-25 at 19.53.45.jpeg` |
| Crystal Fang | `WhatsApp Image 2026-10-27 at 20.17.30.jpeg` |
| Phoenix Reign | `WhatsApp Image 2026-10-27 at 20.18.10.jpeg` |

## Overzicht nieuwe fighters en moves (bronbeeld is leidend)

### Cheese Rat
speed/mixup; zwart rattenhoofd, roodgloeiende ogen, geel overhemd met kaasprint, jeans en zwart-rode sneakers

**Basic attacks:** Jab (quick bite), Strong (Cheese Claw), Tail Whip, Low Cheese Swipe.

**Special moves:** Cheese Slide, Cheese Ball, Tail Spin, Cheese Trap.

**Super moves:** Rat Rush, Cheese Storm, King of the Cheese.

### Lava Stone
power/defense; steen/metallic humanoid met vurige aderen en sneakers

**Basic attacks:** Rock Punch, Lava Kick, Stone Slam, Metal Strike.

**Special moves:** Lava Shield, Stone Spikes, Metal Armor, Lava Burst.

**Super moves:** Earthquake, Lava Ascension, Metal Beast Mode.

### Crystal Fang
rushdown; zwarte weerwolf met roze kristalvormen en donkere broek

**Basic attacks:** Claw Slash, Bite, Crystal Punch, Ground Pound.

**Special moves:** Crystal Dash, Shatter Shield, Lunar Howl, Crystal Spikes.

**Super moves:** Full Moon Rage, Diamond Transformation, Crystal Storm.

### Phoenix Reign
fire/air; mensachtige feniks met gevederde vleugels, leren outfit, intense vlammen

**Basic attacks:** Flame Slash, Fire Kick, Bird Bite, Wing Beat.

**Special moves:** Phoenix Dash, Fire Tornado, Heat Wave, Rebirth.

**Super moves:** Phoenix Rising, Solar Flare, Inferno Wings, Eternal Flame.

## Betekenis voor de Godot-build
- Toon **10 fighters** in een 5×2 responsive fighterselectie (of een scrollbare variant voor kleinere schermen). Het doel blijft eerst een 2P Linux-vertical-slice met twee speelbare profielen, niet tien onafgewerkte spelers.
- De knoppen en richtingssymbolen op de JPEG-sheets (A/B/X/Y/R) zijn visuele move-aanduidingen van een console-layout, NIET de definitieve 2P-Linux-bediening. Zie `data/input_layouts.json` en `docs/COMBAT_EN_KEYBOARD.md`.
- Implementatie van complexe special-move-commando's pas als het universele combo-/inputbuffersysteem werkt; voor v0.1 één special/ultimate per speelbare fighter.
- Bestaande story-route is niet aangevuld met nieuwe lore of verplichte unlockvolgorde: Cheese Rat/Lava Stone/Crystal Fang/Phoenix Reign zijn voorlopig gepland voor uitbreiding.
- Als fighter art wordt uitgesneden uit deze platen, laat de oorspronkelijke complete sheet staan; voer een menselijke controle uit op volledig silhouet, cut-out, transparantie, lijnconsistentie en animatievervorming.
- Let op originele merken/logo's en tekst op kleding/schoenen in referentie-art: bij publiek uitbrengen eerst rechten-/licentiecheck doen, geen merken repliceren als gameplayvoorwaarde.

## Integriteit van bestanden
- `data/uploaded_character_sheets.json` bevat SHA-256, formaat, afmetingen en bronbestandsnaam.
- Run `python3 tools/verify_assets.py` op Linux in de projectroot; verwacht `8/8 OK`.
- Geen extra plaatjes uit oudere conversaties zijn in deze update verzonnen of als echte beelden gepresenteerd.

## Bamboo Blade en Sawtina — upload 31 oktober 2026

De twee nieuwe JPEGs blijven ongewijzigd onder
`assets/originals/character_sheets_2026-10-31/`. Hun hashes en oorspronkelijke
bestandsnamen staan in `data/uploaded_character_sheets.json` (nu 10 bronbeelden).
Deze afbeeldingen zijn ontwerp-/movesheets, geen animaties. De aparte gegenereerde
RGBA-atlassen hebben elk 24 combatkeys, twee extra ultimate-poses en vier introbeelden; de indexers wijzigen
geen pixels. Provenance staat in `data/visual_asset_provenance.json`.

- **Bamboo Blade:** rode panda, zwart-rode kleding, bronzen bracers, fruitmand en
  groene bamboezwaarden. Bamboo Slash, Twin Bamboo Cleave, Fruit Throw en Crimson Harvest.
- **Sawtina:** magenta haar, elfenoren, zwart-roze jurk, munitieriemen en zaaglaarzen.
  Cartridge Jab, Razor Heel, Bullet Tutu en Razor Rhapsody.

Beide zijn in V16 speelbaar na aankoop voor 200 verdiende coins per fighter.
De twaalf fighterprofielen gebruiken een 6×2-selectie. De gallery toont grote, volledige 2D-illustraties en de zes seconden durende introfilms zijn ook vóór
ontgrendeling te bekijken.
