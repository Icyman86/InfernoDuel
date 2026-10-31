# Android V17 / 0.17.0 — menuherstel en vier storylevels

Het hoofdmenu toont bij elk bezoek twee verschillende willekeurige fighters uit
de volledige roster. De linker en rechter figuur kijken naar elkaar en worden
afzonderlijk gekaderd met ruimte ertussen. Ze overlappen de menuknoppen niet.
De hoge-resolutie 2D-illustraties blijven ongewijzigd.

## Oorzaak en herstel van de witte vlakken

De gallery gebruikte in V16 `assets/intros/*_poses.png` via runtime-JSON, terwijl
de exportpresets juist die bestanden uitsloten. In de editor waren ze aanwezig;
in de APK ontbraken de remaps en geïmporteerde texturen voor alle twaalf fighters.
Een Polygon2D zonder geladen textuur werd daardoor een wit vlak. Dit was een
packagingfout, geen ontbrekend ontwerp of gewenste silhouetweergave.

De uitsluiting is verwijderd uit de presets. De APK-verifier controleert nu voor
**alle twaalf** illustraties zowel de import-remap als de bijbehorende CTEX-data.
Er is ook een portretfallback: een onverwacht ontbrekende illustratie wordt niet
meer als een wit polygon getekend. De tests eisen dat de echte volledige artwork
aanwezig is en dat die fallback in de release niet wordt gebruikt.

`tools/test_apk_ui.py` haalt alleen de werkelijke Android-assets uit de gebouwde
APK, maakt er een Godot-resourcepack van en start dat buiten de editorprojectmap.
Alle gamescripts en illustraties komen daarbij uit de export. Elke fighter wordt
gerenderd en op textuurbeschikbaarheid en kleurdetail gecontroleerd. Dit vangt de
V16-fout op die een editorrender alleen niet kon zien. Het is geen fysieke telefoontest.

## Story: Chapter One — The First Descent

Je speelt alle vier duels met **SharkByte** tegen de CPU:

| Level | Tegenstander | Arena |
|---|---|---|
| 1 — The Gatekeeper | Bullet | Infernal Citadel |
| 2 — Whispers in the Forest | Nachtelf | Nachtelvenbos — Hart van het Bos |
| 3 — The Living Ship | Spinegrin | Spinegrins ruimteschip — Levende Brug |
| 4 — The Heart of the Mine | Crystal Fang | Crystal Fang zijn mijn |

STORY MODE opent vier levelkaarten. Aanvankelijk is Bullet beschikbaar. Ieder
level heeft een eigen briefing, de juiste map en een best-of-three-duel. Win twee
rondes om het volgende level te openen. Na verlies kun je hetzelfde level opnieuw
proberen. Na de vierde overwinning is Chapter One voltooid. Eerder voltooide
levels blijven opnieuw speelbaar. Pauze, hervatten en terugkeren naar de levelkaart
werken via de bestaande bediening.

Een voltooide wedstrijd geeft nog steeds vijf coins bij winst of één bij verlies.
Dubbel openen van een uitslag betaalt niet opnieuw uit. De bestaande save krijgt
een optioneel `story_completed`-veld; V16-saves zonder dat veld starten op level 1
en behouden coins, betaalde fighters en eerdere reward-IDs. Checkpoints worden
met dezelfde atomische save en backup bewaard. Story geeft geen gratis aankoop
van Bamboo Blade of Sawtina; hun 200-coinprijs blijft gelden.

## Build en tests

V17 heeft hetzelfde preview-pakket-ID en certificaat als V14–V16, met versiecode
1700. Installeer over de huidige preview om appdata te behouden. Beide apparaten
gebruiken V17 voor een wifi-sessie. De oudere APK's en tags blijven staan.

```bash
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
export DISPLAY=:98 # gebruik het display van de eigen omgeving
./tools/test.sh
./tools/test_gallery.sh
python3 tools/test_network.py
export ANDROID_HOME=/workspace/.runtime/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_PRESET='Android Preview'
export ANDROID_OUTPUT_SUFFIX=-preview
./tools/build_android.sh
./tools/test_v17.sh builds/android/InfernoDuel-Android-v0.17.0-preview.apk
```

Behoud de bestaande preview-keystore buiten Git. Logs en screenshots van de
editor-, story- en APK-resourcepacktests staan bij de V17-release. ARM64/x86_64,
V2/V3-signature, 16-KiB alignment en de publicatiehash worden gecontroleerd.
Er is nog geen fysieke Android-/routertest uitgevoerd.
