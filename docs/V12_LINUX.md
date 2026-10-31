# V12 / 0.12.0 — Linux 3D-preview

Dit is een **speelbaar technisch prototype**, geen voltooide moderne 3D-fighter.
Local Versus en Solo vs CPU gebruiken echte volumemodellen in een belichte
3D-gladiatorenarena. De modellen bestaan uit nieuw gemaakte procedurele meshes
met een gelede transform-rig; het zijn geen sprites op een podium. De tien
silhouetten onderscheiden onder meer vinnen, hoorns, kristallen, rattenoren,
kettingen en vleugels. Oorspronkelijke artwork en V11-portretten blijven behouden.

De kwaliteit is eenvoudig en gestileerd. Er zijn geen productieklare sculpted
characters, geskinnde skeletal rigs, PBR-textuursets, motion capture of fijn
uitgewerkte vechtanimaties aangetroffen of toegevoegd. Blender 4.3.2 is beschikbaar;
deze preview bouwt meshes en gewrichtsanimatie rechtstreeks in Godot. De gedeelde
animatiepatronen vervangen geen per-character professionele animatieproductie.
V12 voldoet daarom nog niet aan het volledige gewenste moderne kwaliteitsdoel.

## Spelen

Pak de Linux-download uit en start `InfernoDuel-Linux/PLAY.sh`. Een Linux x86_64
bureaublad met OpenGL 3.3 is nodig. De engine is inbegrepen. Broncode:
`./tools/run.sh` met Godot 4.6.3. Er zijn geen accounts of externe services nodig.

| Actie | P1 | P2 | Controller (Xbox/Godot-labels) |
| --- | --- | --- | --- |
| Lopen | A/D | Links/rechts | Linkerstick / D-pad |
| Springen | W | Omhoog | A |
| Block / command down | S | Omlaag | LT / D-pad omlaag |
| Light | F | I | X |
| Heavy | G | O | Y |
| Special | H | P | B |
| Ultimate, 100 meter | J | L | RT |
| Grab / throw tech | R | U | LB |
| Break free, 35 meter | T | K | RB |
| Pauze | Esc | Esc | Start |

De eerste twee aangesloten controllers krijgen P1/P2. Een vervangende controller
vult de lege plaats; hij neemt de andere speler niet over. Loskoppelen tijdens een
match pauzeert. D-pad/stick navigeert menu's, A bevestigt, B gaat terug. Character
select: A/X ready, Y undo. In Solo maakt Start beide slots ready, zodat één
controller voldoende is. Laat bediening na pauze/overgangen even los.
Een fysieke controller, mapping van elk merk en tweepersoons keyboard-rollover
zijn nog niet getest; de geautomatiseerde tests injecteren Godot-events en X11-input.

## Directionele combo's

Bestaande light → light → heavy en light → special blijven beschikbaar.
Nieuwe commando's gebruiken de 60-Hz simulatietijd en een historie van 380 ms:

- **Down → down-forward → forward + special:** Rising Breaker, 22 schade,
  opwaartse beweging, twee seconden special-cooldown. Down is je blockbediening.
- **Forward → neutral → forward + heavy:** Momentum Strike, 18 schade en een rush.

Forward/back zijn relatief aan de tegenstander; beide kijkrichtingen zijn getest.
Een herkende historie wordt verbruikt en kan niet als eindeloos herhaalde input
worden gebruikt. Bestaande 69 aanvallen blijven aanwezig; er zijn daarnaast twee
universele motion-aanvallen per fighter. De nieuwe bewegingen hebben gedeelde
procedurele animaties; ze zijn nog geen twintig afzonderlijk geauthoriseerde clips.

## Grabs, stuns en physics

Een grab werkt alleen op de grond binnen 115 simulatieteenheden, buiten eigen
attack/stun en buiten de grab-cooldown. Grabs passeren guard. Houd backward vast
bij het grijpen voor een achterwaartse worp. De worp commit na 250 ms, doet 18
schade, lanceert en geeft 1,3 s bescherming tegen opnieuw grijpen. De verdediger
kan binnen **220 ms** grab indrukken om te tech-en; gelijktijdige grabs tech-en
symmetrisch. Een trap of hit op de aanvaller onderbreekt een onvoltooide worp.

Break free beëindigt hitstun of een klem voor 35 meter, geeft 450 ms immunity en
heeft drie seconden cooldown. Zonder genoeg meter moet je herstel afwachten.
Bestaande anti-stunlockbescherming blijft bestaan. Het model toont terugdeinzen,
gegrepen/geworpen draaien en herstel; de HUD noemt de speciale toestand.
Zware schone hits hebben 50 ms hitstop. Knockback remt in V12 minder abrupt en
body-collision behoudt ook tegen een muur de volledige afstand. F3 tekent de echte
hurt- en hitboxes als transparante 3D-volumes; de deterministische collision zelf
blijft op het zijaanzichtvlak met 60-Hz physics.

## Gladiator Crucible

De stenen ring heeft driedimensionale zuilen/bogen, tribunes, materialen,
perspectiefcamera, licht en schaduwen. Twee vloerklauwen liggen op x=460 en x=820.
Een gouden ring waarschuwt **1,2 s** vóór **450 ms** activatie. Een gegronde fighter
op de klem wordt **750 ms** gestund zonder directe trapschade. Springen of weglopen
ontwijkt de klem. Break free of afwachten beëindigt de stun. Elke klem heeft een
cyclus van acht seconden; ze zijn 3,6 seconden verschoven. Pauze, countdown en
round-over laten de trapklok niet doorlopen. Een round-reset wist actieve grabs.

## Bestaande platforms

Android/touch en LAN gebruiken de bestaande 2D-routes. De nieuwe lokale grabs,
escapes en arena zijn niet heimelijk aan het netwerkprotocol toegevoegd. De
LAN-invoerpakketten behouden hun strikte oude vorm. Beide peers moeten dezelfde
appversie gebruiken; een bestaande Android V11 APK kan niet met Linux V12 verbinden.
Er is geen nieuwe Android- of iOS-build gemaakt en oude tags/downloads blijven staan.
De galerij en films tonen nog de vorige artworkpresentatie.

## Herhaalbare controles

```bash
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
./tools/test.sh
./tools/test_v10.sh
./tools/test_v12.sh
# Werkend X11-scherm nodig voor deze controles:
TEST_V12_RENDERED=1 ./tools/test_v12.sh
godot --path . --audio-driver Dummy tests/visual.tscn
./tools/build_linux.sh
python3 tools/test_native.py
```

De native test start de geëxporteerde engine/PCK en stuurt X11-toetsaanslagen door
menu, character select en gevecht. Een read-only observer kijkt naar routes,
beweging, schade en pauze; hij schrijft geen inputs, HP of phases. Dat is geen
fysieke hardwareacceptatie. Screenshots staan onder `/tmp/inferno-v12/`.
