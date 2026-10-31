# Android V16 / 0.16.0 — Bamboo Blade, Sawtina en coins

De twee nieuwe uploads zijn toegevoegd als **Bamboo Blade** en **Sawtina**.
De complete JPEGs staan ongewijzigd in de originele-assetsmap van 31 oktober.
Hun SHA-256 staat in de bronmanifest; de eerdere acht bronbeelden blijven intact.

Elke fighter heeft een eigen transparante 24-key combat-atlas en twee extra
ultimate-poses met volledige silhouetten. Alle tien staten zijn aanwezig:
idle, lopen, light, heavy, guard, jump, special, ultimate, geraakt en KO.
Bamboo Blade gebruikt bamboezwaarden, Fruit Throw en Crimson Harvest.
Sawtina gebruikt een Razor Heel, Bullet Tutu en Razor Rhapsody.
Hun projectielen hebben eigen fruit-, kogel- en zaagbeelden. De bestaande grote
ultimate-melding, drie seconden aura en +20% vervolgaanvalschade blijven actief.

De fighterselectie toont twaalf kaarten in 6×2, een coin-balans en unlockknoppen.
FIGHTERS toont alle twaalf fighters als grote 2D-illustraties uit de bestaande
reference-guided artwork. De volledige silhouetten worden met marge gekaderd;
portret- en signature-poseknoppen tonen de bijbehorende aparte illustraties.
De 3D-gallery is op verzoek vervangen; de oorspronkelijke 2D-vormgeving en
lichaamsverhoudingen blijven daardoor behouden.
Elke nieuwe fighter heeft ook een gerenderde Theora-intro van 6,43 seconden.
Intro's en illustraties kunnen vóór aankoop bekeken worden.

## Coins en ontgrendelen

- Beide nieuwe fighters kosten afzonderlijk **200 coins**.
- Een **afgeronde best-of-three-wedstrijd** levert de lokale speler **5 coins bij
  winst** of **1 bij verlies** op, tegen CPU of via een sessie.
- Een verlaten of herstart gevecht geeft geen coins. Alleen complete resultaten
  tellen; een match-ID voorkomt dubbele beloning vanuit hetzelfde resultaatscherm.
- Ontgrendel via FIGHTERS of UNLOCK bij de geselecteerde fighter. De bestaande
  tien fighters blijven beschikbaar. Een tweede aankoop van dezelfde fighter
  trekt geen coins af. De CPU-keuze in solo volgt dezelfde lokale unlocks.
- De wallet en beide unlocks worden lokaal opgeslagen via een tijdelijk bestand,
  atomische vervanging en backup. Bij een opslagfout wordt de aankoop/beloning
  niet als succesvol voorgesteld. Desktop Local Versus gebruikt de P1-wallet;
  Android heeft een afzonderlijke wallet per app-installatie/apparaat.

V16 gebruikt hetzelfde preview-pakket en certificaat als V14/V15, met versiecode
1600. Installeer over de bestaande preview om de appdata te behouden. De aparte
oorspronkelijke V11-app blijft bestaan. Er is geen account- of cloudopslag voor coins.

## Sessiecode

Op Android zocht de gast voorheen uitsluitend via globaal UDP-broadcast.
De zoekfunctie probeert nu ook gewone unicast binnen maximaal twee lokale
private /24-netwerken. Dat ondersteunt routers die broadcast onderdrukken.
De timeout laat twee volledige zoekcycli toe; invoer kan spaties/streepjes
bevatten en normaliseert vóór codevalidatie. Verouderde V11-teksten zijn vervangen.

Gebruik **V16 op beide apparaten**, op hetzelfde wifi-netwerk of een telefoonhotspot.
Gastnetwerkisolatie, VPN en firewalls kunnen peer-verkeer nog blokkeren.
Codes verbinden geen apparaten op verschillende internetnetwerken: er is geen
publieke rendezvous-/relayserver geconfigureerd. Zie [NETWORK.md](NETWORK.md).

Protocol 4 wisselt de per-device unlocklijsten uit. De host controleert elke
fighterkeuze tegen de bij die speler bekende lijst, kiest de map en simuleert het
gevecht. Projectielen gebruiken compacte snapshotrecords; gecomprimeerde state
past ook bij een volley in één UDP-pakket. De drie-hit-combo-ontsnapping blijft
van kracht, ook wanneer een volley op een eerdere jab volgt.

## Validatie en herhalen

De release bevat de uitgevoerde logs en screenshots. Tests omvatten kopen bij
199/200 coins, afzonderlijke unlocks, herladen, dubbele resultaten, afbreken,
backupherstel, animatiegeometrie, twee echte netwerkspelers met verschillende
unlocks, hun afzonderlijke winnaar/verliezer-beloningen en werkelijke introdecoding.
De fysieke Android-/routertest moet nog worden uitgevoerd; lokale ENet-processen
en gerenderde touch-UI zijn geen fysieke telefoontest.

```bash
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
export DISPLAY=:98 # gebruik het X-display van de eigen omgeving
./tools/test.sh
./tools/test_v16.sh
export ANDROID_HOME=/workspace/.runtime/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_PRESET='Android Preview'
export ANDROID_OUTPUT_SUFFIX=-preview
./tools/build_android.sh
```

Bewaar de bestaande preview-keystore buiten Git. De APK gebruikt de officiële
Godot 4.6.3-engine, ARM64 en x86_64, V2/V3-signature en gecontroleerde 16-KiB alignment.
