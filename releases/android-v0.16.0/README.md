# Android V16 preview — Bamboo Blade, Sawtina en 2D-fighters

[Download de APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.16.0-android-preview/releases/android-v0.16.0/InfernoDuel-Android-v0.16.0-preview.apk).

Installeer over de bestaande V14-/V15-preview. Het preview-pakket en de signing
identity blijven gelijk; de nieuwe versiecode is 1600. De oorspronkelijke aparte
V11-app en alle oudere downloads blijven behouden.

- **Bamboo Blade** en **Sawtina**: eigen gevechtsanimaties, specials, ultimates en
  introfilms. Beide kosten **200 coins**. De volledige roster telt twaalf fighters.
- Een afgeronde best-of-three geeft **5 coins bij winst** of **1 bij verlies**.
  Coins en unlocks worden op het apparaat bewaard. Koop via FIGHTERS of de selectie.
- **FIGHTERS gebruikt grote 2D-illustraties voor alle twaalf personages**, met een
  volledig lichaam, portret en signature-pose. De 3D-menuweergave is vervangen.
- Sessiecodes zoeken op hetzelfde wifi-netwerk nu ook via unicast wanneer broadcast
  niet werkt. Gebruik **V16 op beide apparaten** en gewone wifi of een hotspot.
  Er is, zoals afgesproken, geen internetrelay toegevoegd.
- Alle vier maps, RANDOM en de grote ultimate-melding met drie seconden krachtbonus
  zijn behouden.

## Beelden

| 2D-fightermenu | Gevechten en coins |
|---|---|
| [Chainveil](validation/chainveil-gallery.png) | [Nieuwe fighters in de mijn](validation/new-fighters-combat.png) |
| [Sawtina](validation/sawtina-gallery.png) | [Sawtina ultimate](validation/sawtina-ultimate.png) |
| [Bamboo Blade](validation/bamboo_blade-gallery.png) | [Bamboo Blade ultimate](validation/bamboo_blade-ultimate.png) |
| [Selectie en unlocks](validation/locked-fighter-select.png) | [Beloning na winst](validation/coin-reward.png) |
| [Bamboo Blade intro](validation/bamboo_blade-intro.png) | [Sawtina intro](validation/sawtina-intro.png) |

## Uitgevoerde controles

- 1.263 gameplay-, artwork- en rostertests; alle 77 single-input moves en twaalf CPU-profielen.
- 163 coin-, unlock-, opslag- en animatiecontroles, inclusief 199/200 coins en geen dubbele beloning.
- 174 gallerychecks via echte knoppen en twee schermformaten; 71 aanvullende visuele checks.
- 37 netwerkchecks over drie echte processen, met beide nieuwe fighters, unicast,
  afzonderlijke unlocks en afzonderlijke winnaar-/verliezer-wallets.
- 53 sessie-UI-checks, 196 arena-/ultimate-checks en twaalf volledig gedecodeerde introfilms.
- Tien originele uploadbestanden op SHA-256 gecontroleerd; beelden blijven ongewijzigd.
- ARM64/x86_64 APK-inhoud, V2/V3-signature, 16-KiB alignment, versie en dezelfde
  publieke signing identity als V15-preview gecontroleerd.

De logs staan in `validation/`, de APK-hash in `SHA256SUMS` en de technische
instructies in [V16_ANDROID.md](../../docs/V16_ANDROID.md). Dit zijn lokale
proces-/rendertests; er is nog geen fysieke Android-/wifi-routertest uitgevoerd.
