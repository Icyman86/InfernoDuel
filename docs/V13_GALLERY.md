# V13 / 0.13.0 — 3D-personages in Fighters

FIGHTERS toont nu tien nieuwe Blender-meshpersonages met een echt skelet en
skin-gewichten. Het vorige geëxtrudeerde illustratievlak is in dit menu vervangen.
De gevechtsweergave uit V12 blijft behouden; deze update concentreert zich op
het grote, draaibare personage in de galerij.

## Wat er is gemaakt

Iedere fighter heeft een eigen volumemodel, 16 bones, een cyclische idle-animatie,
afzonderlijke materialen, ingebedde normal maps en getekende vertexkleuren voor
de huid. De modellen hebben circa 89.000–128.000 driehoeken. Geometrie is opgebouwd
in Blender met het meegeleverde modelleerscript: aaneengesloten huidvormen,
vingers, ogen/oogleden, tanden, haarlokken, naden, schoenveters en accessoires.
De acht oorspronkelijke character sheets zijn als identiteitsreferentie gebruikt
en byte voor byte behouden. Er zijn geen externe character-modellen gebruikt.

| Fighter | Herkenbare details in het nieuwe model |
| --- | --- |
| SharkByte | Haaienkop, tanden, kieuwen, vinnen, tegenkleuring, zwarte jas, lichte broek |
| Bullet | Menselijke bruiser, rood hemd, zwart haar, stoppelbaard, litteken, arminkt, bull-crest en ketting |
| Nachtelf | Elfenoren, donker haar, zwart-rode jas, schouderornamenten en rode magie |
| PoisonBoy | Menselijk gezicht, groene muts, donkere streetwear, ketting en groene magie |
| Spinegrin | Groene reptielenhuid, schubben, rugstekels en staart |
| Chainveil | Bleke huid, lang zwart haar, korset met veters, laarsdetails, choker en afzonderlijke kettingschakels |
| Cheese Rat | Rattenkop, oren, snorharen, snijtanden, geel overhemd en denim |
| Lava Stone | Basaltplaten, zichtbare gloeiende scheuren en donkere materialen |
| Crystal Fang | Wolvenkop, vachtplukken, gefacetteerde roze kristallen en klauwen |
| Phoenix Reign | Vogelkop, kuif, gelaagde vleugels, veerschachten en klauwvoeten |

Dit zijn nieuw gemaakte, gestileerde interpretaties van de referenties. De
gezichten en anatomie zijn vereenvoudigd; er is geen facial capture, haar- of
kledingsimulatie. De galerij gebruikt een rustige skelet-idle en een korte entree,
geen nieuwe complete sets vechtanimaties. De beelden in deze release laten de
werkelijke kwaliteit zien; polygonenaantallen zijn geen kwaliteitsgarantie.

## Groot en volledig in beeld

Het 3D-vlak is vergroot tot 748 × 503 logische pixels binnen het 1280 × 720 menu.
De camera past zich aan de werkelijke modelgrenzen, kijkhoek en beeldverhouding
aan. Hij houdt ook voeten, haar, vinnen, staarten en vleugels in beeld. De tests
controleren minstens 72% verticale beeldvulling van de model-envelop en een
veilige rand. De 3D-framebuffer volgt de daadwerkelijke pixelschaal van het venster.

- Klik een van de tien kaarten om die fighter groot te bekijken.
- Sleep met de linkermuisknop over het personage of gebruik TURN om te draaien.
- PORTRAIT VIEW toont het hoofd/bovenlichaam dichterbij; FULL BODY herstelt de volledige weergave.
- REPLAY ENTRANCE herstart dezelfde live 3D-presentatie.
- ORIGINAL SHEET en PLAY INTRO blijven beschikbaar. De originele afbeelding en film worden apart getoond.

De nieuwe studiobelichting combineert hoofdlicht, koel invullicht en een gekleurde
randverlichting. De ondergrond ontvangt echte schaduwen. Tijdens het bekijken van
een bronblad stopt ook de skeleton-animatie; daarna komt hetzelfde model terug.

## Bronbestanden en controle

- `assets/models/v13/*.glb`: de tien zelfstandige modellen, inclusief texturen, skin en animatie.
- `data/character_models.json`: modelpaden, grenzen, aantallen en SHA-256 per fighter.
- `tools/modeling/build_roster.py`: herhaalbaar modelleerrecept voor Blender 4.3+ met NumPy uit Blender.
- `scripts/ui/fighter_presentation.gd`: belichting, modelpresentatie en camerakadrering.
- `scripts/ui/gallery.gd`: grote viewer en de bediening.

De Blender-export hoeft niet bij iedere taak opnieuw te draaien. De GLB-bestanden
zijn al beschikbaar en Godot 4.6.3 importeert ze rechtstreeks. Heropbouw:

```bash
blender --background --threads 4 --python tools/modeling/build_roster.py
# Eén character kan ook: voeg -- sharkbyte toe.
python3 tools/verify_models.py
godot --headless --path . --editor --quit
```

De builder vernieuwt het manifest met de werkelijk gemaakte bestanden; Blender/
OpenVDB kan de vertexvolgorde per export variëren. De checksums zijn die van de
meegeleverde, gecontroleerde assets en vormen geen claim van byte-identieke rebuilds.

Met werkende X11-display, Godot 4.6.3 en de gebruikelijke schrijfbare XDG-mappen:

```bash
./tools/test.sh
./tools/test_gallery.sh
./tools/build_linux.sh
python3 tools/test_native.py
```

De galerijtest klikt de echte kaarten en knoppen aan, test slepen, skeleton-idle,
normal maps, alle tien modellen, zij-/achteraanzicht, portret/full body, bronblad en
resoluties 960 × 540, 1280 × 720 en 1920 × 1080. De native test bedient de geëxporteerde
engine/PCK via X11 en selecteert alle tien characters in het verpakte Fighters-menu.
Geen fysieke controller- of gamehardwaretest wordt hiermee geclaimd.
