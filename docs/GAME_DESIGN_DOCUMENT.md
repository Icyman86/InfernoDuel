# GAME DESIGN DOCUMENT | Inferno Duel: Legends

**Versie:** 1.1 ontwerpbrief, 27 oktober 2026 — bijgewerkt met 8 originele character sheets  
**Platform 1:** Linux desktop (x86_64)  
**Engine:** Godot 4, standaard GDScript, 2D, Compatibility renderer  
**Primair speltype:** offline local versus, 2 spelers, 1 toetsenbord  
**Later:** story mode, character unlocks, Android APK.

## 1. Visie

Maak een snelle, visueel expressieve 2D-fighter in dark-fantasy/urban-monster-stijl, geïnspireerd door onze gekozen **fighter-art stijl B**. De game moet voelen als een echte fightinggame: duidelijke silhouetten, trefzekere botsingen, weighty aanvallen en een leesbare UI. De bestaande webgame is alleen referentie voor concept en oude bediening, NIET de implementatiebasis.

### Doelervaring
- 60 frames per seconde als doel op gangbare Linux-desktops.
- Duel van 60 seconden, first-to-two rounds (best-of-three).
- Zowel eerlijk competitief 2P als een solo trainings-/CPU-route.
- Elke fighter heeft herkenbare identiteit, speciaal projectiel/aanval en ultieme aanval.
- Gameplay blijft leesbaar ondanks gloed, vuur, rook en impacteffecten.

## 2. Figuren / rooster

Er zijn nu **tien** ontworpen fighters: de zes oorspronkelijke plus vier nieuwe uit de upload van 27 oktober 2026. De acht meegeleverde beelden zijn samen referentie voor alle tien fighters:

| Fighter | Art-direction | Unieke gevechtsidentiteit | Status |
|---|---|---|---|
| **SharkByte** | Hai-mens, zwart-/donkerblauwe schubben, leren jasje, witte broek, zwart/witte sport-/skateschoenen | snelle dash, bijt/grijp-combo, water/blauw impacteffect | Hoofdpersoon; altijd beschikbaar |
| **Bullet / Stier** | Krachtige stiervechter, eventueel kat als achtergrond-/intro-metgezel | krachtige stomp, charge, zware impact | Originele fighter; final details verifiëren met art |
| **Nachtelf / Warlock** | Nachtelf-magier, duister vuur, vuurelementaal | ranged vuurbol, ontwijkende zone-control, eruptie | Originele fighter |
| **PoisonBoy** | Groene/giftige fighter, verwijzing naar fighter-art concepts | poison hit, venom cloud, toxische super | Originele fighter; precieze costumelementen uit art halen |
| **Spinegrin** | Groen-geel geschubde eenogige alien, geen neus, enorme grijns, dunne gespierde bovenarmen/torso, spikes op onderarmen, strakke leren broek, skateschoenen, oplichtende band langs ruggengraat | spikes schieten; meter zichtbaar op rug; ult: grote groene rugspikes | Nieuwe fighter |
| **Chainveil** | Gothic vrouw, leather-and-lace outfit, schoenen met dikke zolen, vecht met kettingen | lange chain-reach, pull, trap, chain-storm ultimate | Nieuwe fighter |
| **Cheese Rat** | Stoere zwarte rat, geel kaaspatroon-overhemd, jeans, rood-zwarte sneakers, gloeiende rode ogen | cheese ball, cheese trap, snelle dash, King of the Cheese | Toegevoegd 27-10 |
| **Lava Stone** | Zwarte steen-/lavavechter met gloeiende scheuren, metalen look en sneakers | lava shield, stone spikes, earthquake, metal beast mode | Toegevoegd 27-10 |
| **Crystal Fang** | Spierachtige donkere weerwolf met felroze kristaluitgroei, donkere broek | crystal dash, lunar howl, spikes, Full Moon Rage | Toegevoegd 27-10 |
| **Phoenix Reign** | Antropomorfe vuur-/feniksvechter, veren, vleugels, zwarte leren kleding | phoenix dash, fire tornado, rebirth, Phoenix Rising | Toegevoegd 27-10 |

**Noot:** de originele source-art voor zes hoofdfiguren staat nu in `assets/originals/character_sheets_2026-10-27/`. Bullet, Nachtelf/Warlock en PoisonBoy delen daarin één referentieplaat. De vier nieuwe character-sheets tonen ook uitgebreide move-inspiratie; zie `docs/GEUPLOADDE_SHEETS_EN_MOVES.md`. Verander namen/identiteiten niet zonder overleg.

## 3. Modi en volgorde

### Linux v0.1 — moet werken
1. **Local Versus (2P / 1 keyboard)** — belangrijkste speltype.
2. **Solo vs CPU** — basale AI voor solo testen; kies fighter/opponent.
3. **Character Select** — schaalbaar rooster voor tien slots (5×2 bij 16:9); voor v0.1 zijn minimaal twee profielen volledig speelbaar, overige slots expliciet als prototype/COMING SOON wanneer niet geïmplementeerd.
4. **Eén arena** — 'Infernal Citadel': vurige/donkere ruïnes, achtergronddiepte.
5. **Gevechtsengine**, HUD, match result, pause, rematch, instellingen.

### Linux v0.2 — verdieping
Volledige movesets, combo-cancel vensters, betere hit-reacties, audio en unieke specials/ultimates voor uiteindelijk alle tien fighters; echte sprite-animaties zodra assets geschikt zijn; keyboard rebinding.

### Linux v0.3 — story
SharkByte start unlocked. Tegenstanders worden in een campagne verslagen en daardoor vrijgespeeld. Voorstel speelvolgorde (oude zes): Bullet -> PoisonBoy -> Nachtelf -> Chainveil -> Spinegrin. De nieuwe vier hebben nog geen storyvolgorde; niet zonder ontwerpbesluit invullen. Bewaar progress lokaal (user://), inclusief unlocks en beste uitslagen. Story-dialogen zijn voorlopig placeholders waar ontbrekende lore expliciet aangegeven wordt.

### Later — Android
Pas zodra Linux-v0.2 stabiel en artwork pipeline betrouwbaar is: touch-overlay, landscape-UI, Android SDK, export en fysieke Android-tests.

**Belangrijk:** voor lokale versus in v0.1 zijn minimaal SharkByte en één tegenstander volledig speelbaar. De overige acht staan in het tien-slots-roster met duidelijk label `COMING SOON` totdat ze een werkend profiel hebben; geen dode SELECT-knoppen. Zodra generieke profile+controller werkt, mag Codex extra fighters als echte speelbare placeholders toevoegen. Story-locks gelden later voor campaign-unlocks, niet voor het lokale testroster. Toon voor niet-beschikbare animaties `ANIMATIEFRAMES NOG NIET BESCHIKBAAR`.

## 4. Gevechtsregels

- View: side-on 2.5D look, speelbaar 2D vlak zonder dieptebeweging.
- Geen double-jump in v0.1; jump, left/right, block.
- Scherm houdt beide fighters in beeld; arena grens verhindert oneindig teruglopen.
- Start HP 100 per fighter, meter 0/100 per matchstart; behoud meter per round zolang match duurt.
- Light: 6 dmg, 0.30s totale actie; Heavy: 12 dmg, 0.55s; Special: 16 dmg, cooldown 1.5s; Ultimate: 30 dmg, kost volle 100 meter.
- Exacte startup/active/recovery en hitbox per attack komen uit data; timings zijn initieel te tunen, geen belofte van balans.
- Guard reduceert directe schade met 75% als blocking richting aanvaller en op de grond; chip damage minimaal 1.
- Hits leveren meter op (light 7, heavy 12, special 14; verdedigen 4). Meter clamped 0–100.
- Win door KO; time-out wint fighter met meer HP; exact gelijke HP = draw round en retry.
- KO stopt spelsimulatie, toont round result, daarna countdown 3-2-1-FIGHT.
- Match best-of-three: twee gewonnen rounds.
- Hit effects mogen maximaal 2–3 frames korte camera-shake geven; UI blijft stabiel.

## 5. Visuele stijl

Palet: obsidiaan #0B0911, dieprood #3B101B, vuuroranje #F46B35, goud #FFCA7A, ivoor #F6E7D9, koel accent #49C4D7 (SharkByte). Prioriteit: hoge tekstcontrast, silhouetten leesbaar, geen vlakke emoji-personages. Menus met metallic/gothic panel frames, lichte rook, subtiele vlamreflecties, parallax. Geen overdaad aan gloed achter HP-bar en kleine letters.

Typografie: dramatische displaytekst voor titel, duidelijke open-source leesfont voor knoppen/beschrijvingen. Zorg voor vrije licenties en bundel rechten/documenteer fontbronnen.

## 6. Audio

Technisch voorbereid: title ambience, confirm/cancel, character select blip, whoosh, hit, block, KO, round announcement, ultimate. Geen stock/licentie-aannames; werk met placeholders indien niet aangeleverd. Apart instelbaar master/music/SFX.

## 7. Fysiek toetsenbord

Beide spelers delen een toetsenbord: één input-eventbus, onafhankelijke acties per speler, nooit een globale 'current player' die de ander overschrijft. Zie `COMBAT_EN_KEYBOARD.md` voor exacte toetsen en testen van key ghosting.

## 8. Succescriteria

De Linux-v0.1 is klaar als P1 en P2 **tegelijk** kunnen lopen/aanvallen, 3 rounds en een rematch kunnen afronden, pauze/menu goed werken, en Codex de exacte teststatus rapporteert. Een APK hoort nadrukkelijk niet bij deze eerste oplevering.
