# Android V14 / 0.14.0 — gekozen arena's en ultimate power

De gebruiker heeft **A3 — Hart van het Bos** gekozen voor Nachtelvenbos en
**B1 — Levende Brug** voor Spinegrins ruimteschip. De zes oorspronkelijke
voorstellen staan onder `releases/android-v0.14.0/concepts/`. De uiteindelijke,
opnieuw gegenereerde speelachtergronden staan onder `assets/arenas/`.
Oorspronkelijke character-artwork blijft behouden.

Na character select verschijnt CHOOSE YOUR ARENA met de bestaande Infernal
Citadel, Nachtelvenbos, Spinegrins ruimteschip en RANDOM. Klik een kaart of RANDOM,
dan ENTER THE ARENA. Random kiest één van de drie beschikbare arena's bij het
bevestigen; een rematch behoudt die arena. De foto's/scenery veranderen het vlakke
speelveld en de combat-collision niet. De achtergrond vult ook brede schermen.

In verbonden spel wachten beide spelers na ready op de mapkeuze. De host kiest;
de arena-ID gaat betrouwbaar naar de guest vóór countdown. De guest kan geen
andere map afdwingen. Bij rematch blijven de map en de fighterkeuzes behouden.
Gebruik op beide apparaten V14; oudere versies zijn niet compatibel met het
nieuwe sessieprotocol. Dit blijft directe LAN-play zonder publieke relay.

## Duidelijke ultimate

Een succesvolle ultimate-activatie toont een groot ULTIMATE!-paneel met fighter,
aanvalnaam en een aftellende bonus. De fighter krijgt drie seconden een grote
karakterkleurige/gouden aura, ronddraaiende lichtbogen, een grondring en extra
licht op het spritebeeld. De Android ULT-knop toont ACTIVE met de resterende duur.
De vorm van de oorspronkelijke animatieframes blijft ongewijzigd.

Tijdens die drie seconden doen **vervolgaanvallen +20% schade**, naar boven
op hele HP afgerond (heavy 12 → 15). De eerste ultimate behoudt zijn eigen
balanswaarden; bestaande empowerment en de nieuwe bonus stapelen niet bovenop
elkaar. Een mislukte poging bij te weinig meter geeft geen aura/bonus. Pauze
bevriest de simulatietimer en de effecten. Ronde-einde, reset en KO ruimen de aura
op. De host blijft autoritatief; snapshots nemen de effectduur en aanvalnaam mee.

## Aparte installeerbare preview

De gebruiker koos expliciet voor een **aparte preview-app naast de bestaande app**.
De oorspronkelijke V11-signingsleutel ontbreekt; de nieuwe developerhandtekening
heeft een andere openbare certificaatvingerafdruk. Daarom is deze APK geen
in-place update van V11. Pakket-ID: `org.infernoduel.legends.preview`, label
`Inferno Duel V14 Preview`, versie 0.14.0 / code 1400. V11 hoeft niet verwijderd te
worden. De preview heeft eigen instellingen; gebruik voor sessies op beide
apparaten de preview. Bewaar de nieuwe lokale keystore voor latere preview-updates.

De APK bevat ARM64 en x86_64, voor Android 7+ met een 64-bit OS en OpenGL ES 3.0.
De preview is met een lokale development key ondertekend; dit is geen Play Store
publicatie. De keystore is niet in Git opgenomen. Er is geen fysieke telefoontest
uitgevoerd; touchweergave en LAN-verkeer zijn in de Linux-testomgeving gecontroleerd.

## Validatie en herhaalbare build

- 176 arena-/ultimate-checks, waaronder daadwerkelijke selectie, randomdekking,
  damage/expiry/non-stacking, pauze/reset, snapshot en gastbeperkingen.
- 1.151 bestaande gameplay/artwork/roster-checks en tien films gecontroleerd.
- 29 netwerkchecks met drie echte processen, inclusief host-mapkeuze op beide peers.
- Officiële Godot 4.6.3 Android-templates gecontroleerd met de gepinde SHA-512;
  SDK-pakketten gecontroleerd tegen Googles HTTPS-repositorymetadata.
- APK-payload, native ABI's, V2/V3-handtekening, 16-KiB alignment en pakketgegevens gecontroleerd.

```bash
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
export ANDROID_HOME=/workspace/.runtime/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_PRESET='Android Preview'
export ANDROID_OUTPUT_SUFFIX=-preview
./tools/build_android.sh
# Met werkende DISPLAY:
./tools/test_arenas_ultimate.sh
# Echte lokale ENet-peers, headless:
python3 tools/test_network.py
```

Het gewone Android-exportprofiel behoudt het oorspronkelijke pakket-ID en is
bedoeld voor een toekomstige build met de juiste oorspronkelijke sleutel.
Publiceer die niet met de preview-sleutel als een update voor V11.
