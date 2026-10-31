# Android V15 / 0.15.0 — Crystal Fang zijn mijn

De gebruiker koos **C1** en gaf de exacte mapnaam **Crystal Fang zijn mijn**.
De uiteindelijke arena is een grote ondergrondse mijn met monumentale rotspilaren,
gloeiende roze diamanten, blauwe nevel en een vrije stenen vechtvloer.
De roze lichtaccenten en zwevende mineralendeeltjes passen bij de nieuwe omgeving.
De drie oorspronkelijke voorstellen zijn in de release bewaard; alleen C1 is
als speelbare map toegevoegd.

Na character select zijn er nu vier kaarten: Infernal Citadel, Nachtelvenbos,
Spinegrins ruimteschip en Crystal Fang zijn mijn. De kaartbreedte en miniatuur
schalen met het aantal maps, zodat de vierde kaart ook op het scherm past.
RANDOM kiest uit alle vier. In een sessie kiest de host en ontvangt de gast
betrouwbaar dezelfde arena. Een rematch behoudt de gekozen map. Beide spelers
moeten dezelfde gameversie gebruiken.

V15 gebruikt hetzelfde preview-pakket-ID en dezelfde signing identity als V14,
met versiecode 1500 in plaats van 1400. De APK kan dus de **V14-preview** bijwerken;
de aparte oorspronkelijke V11-app blijft behouden. De Android-app heet nu
Inferno Duel V15 Preview. De eerdere ultimate-aura en +20% vervolgaanvalbonus zijn
ook in deze build aanwezig. Er is geen fysieke telefoontest uitgevoerd.

## Controlebewijs

- 196 arena-/ultimate-checks geslaagd: onder meer de exacte mapnaam, zichtbaarheid
  van alle vier kaarten, daadwerkelijk aanklikken van kaart vier en RANDOM-dekking.
- 29 netwerkchecks over drie echte processen: host én gast laden de nieuwe mijn.
- 1.151 bestaande gameplay-/artwork-/roster-checks geslaagd; tien films gedecodeerd.
- Ingame-render met Crystal Fang in de mijn; touchlayout, vloer en diamanten beoordeeld.
- APK-payload bevat vier arena's én de geïmporteerde mijntextuur. ARM64/x86_64,
  V2/V3-signature, 16-KiB alignment en pakketmetadata gecontroleerd.
- De publieke signing-certificaatvingerafdruk is gelijk aan die van V14-preview.

Herhalen met de bestaande Godot 4.6.3/SDK-omgeving:

```bash
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
export ANDROID_HOME=/workspace/.runtime/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_PRESET='Android Preview'
export ANDROID_OUTPUT_SUFFIX=-preview
./tools/build_android.sh
# DISPLAY nodig voor de echte touchlayout:
./tools/test_arenas_ultimate.sh
python3 tools/test_network.py
```

Behoud de bestaande lokale preview-keystore. Ze staat niet in Git.
