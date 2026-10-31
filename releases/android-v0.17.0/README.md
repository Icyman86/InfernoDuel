# Android V17 preview — menuherstel en vier storylevels

[Download de APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.17.0-android-preview/releases/android-v0.17.0/InfernoDuel-Android-v0.17.0-preview.apk).

Installeer over de bestaande V14–V16-preview. Pakket-ID en certificaat blijven
gelijk; de nieuwe versiecode is 1700. Coins en betaalde unlocks blijven behouden.
Eerdere downloads en de aparte oorspronkelijke V11-app blijven bestaan.

- Het hoofdmenu toont bij ieder bezoek twee verschillende willekeurige fighters,
  naar elkaar gericht en afzonderlijk gekaderd. De figuren overlappen niet.
- De witte galleryvlakken zijn hersteld. De V16-export sloot de gebruikte PNG's
  uit; V17 levert alle twaalf illustraties mee en controleert hun echte APK-render.
- STORY MODE heeft vier opeenvolgende best-of-three-duels met **SharkByte**:

| Level | Tegenstander | Map |
|---|---|---|
| 1 | Bullet | Infernal Citadel |
| 2 | Nachtelf | Nachtelvenbos |
| 3 | Spinegrin | Spinegrins ruimteschip |
| 4 | Crystal Fang | Crystal Fang zijn mijn |

Elk level heeft een briefing. Winst opent het volgende level; verlies geeft een
retry. Na level vier is Chapter One voltooid en kun je de levels opnieuw spelen.
Voortgang wordt opgeslagen. Een voltooide wedstrijd geeft vijf coins bij winst
of één bij verlies; dubbel openen van de uitslag geeft geen extra coins.

## Beelden uit de controles

| Gebouwde APK | Story |
|---|---|
| [Willekeurig menuduel](validation/apk-random-menu.png) | [Levelkaart](validation/story-level-select.png) |
| [Cheese Rat zonder wit vlak](validation/apk-gallery-cheese_rat.png) | [Briefing van level 1](validation/story-briefing-1.png) |
| [SharkByte](validation/apk-gallery-sharkbyte.png) | [Bullet in de Citadel](validation/story-level-1.png) |
| [Sawtina](validation/apk-gallery-sawtina.png) | [Nachtelf in zijn bos](validation/story-level-2.png) |
| [APK-storybriefing](validation/apk-story-briefing.png) | [Spinegrin op zijn schip](validation/story-level-3.png) |
| — | [Crystal Fang in zijn mijn](validation/story-level-4.png) |
| — | [Hoofdstuk voltooid](validation/story-result-4.png) |

## Uitgevoerde controles

- 139 story-/menuchecks: willekeurige, verschillende, niet-overlappende fighters;
  vier juiste tegenstanders/maps; verlies, retry, next-level, replay en save-migratie.
- 43 checks op de **echte geëxporteerde APK-assets**, buiten de editorprojectmap:
  alle twaalf illustraties laden en hebben kleurdetail, met story-start en opgeslagen winst.
- 1.263 gameplay-/artwork-/rostertests, twaalf gedecodeerde introfilms en 174 gallerychecks.
- 37 echte netwerkchecks, 163 coin-/unlockcontroles en 53 sessie-UI-checks.
- Tien oorspronkelijke artworkbestanden op SHA-256 gecontroleerd.
- ARM64/x86_64, V2/V3-signature, 16-KiB alignment, packageversie en dezelfde publieke
  signing identity als V16-preview gecontroleerd. Hash staat in `SHA256SUMS`.

De APK-render gebruikt de exportresources met de overeenkomende Linux-Godot-engine;
er is nog geen fysieke Android-/routertest uitgevoerd. De storytests gebruiken
gecontroleerde KO-fixtures voor de round/result-flow; de bestaande rostertests
controleren echte moves en complete CPU-matches. Logs staan in `validation/`.
Herhalen en technische details: [V17_ANDROID.md](../../docs/V17_ANDROID.md).
