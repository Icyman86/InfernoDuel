# Combat / Input — 2 spelers op één fysiek toetsenbord

## De belangrijkste eis
**Local multiplayer is GEEN online multiplayer en geen split-screen.** Twee mensen zitten bij dezelfde Linux-pc, delen één toetsenbord en vechten tegelijkertijd op hetzelfde scherm. Beide spelers moeten volledige onafhankelijke input hebben; geen beurtensysteem. Mouse niet nodig tijdens match.

## Standaard Linux keymaps

| Actie | Player 1 (links) | Player 2 (rechts) |
|---|---|---|
| Links | `A` | `←` |
| Rechts | `D` | `→` |
| Spring | `W` | `↑` |
| Blokkeer | `S` (vasthouden) | `↓` (vasthouden) |
| Snelle aanval / Light | `F` | `I` |
| Zware aanval / Heavy | `G` | `O` |
| Special | `H` | `P` |
| Ultimate (meter vol) | `J` | `L` |
| Pauze | `Esc` (globaal) | `Esc` (globaal) |

Deze opzet sluit aan bij de eerdere web-build. Bewaar mappings in één centrale configuratie en laat v0.2 remapping toe. Omdat `J` en `I/O/P/L` relatief dicht bij elkaar zitten, laat **exacte mapping aanpasbaar zijn** als ghosting of ergonomie klachten veroorzaakt. Sommige goedkope toetsenborden registreren combinaties van vier+ toetsen niet: dat is een hardwarelimiet, niet per se een Codex-bug.

## Kerninputregels
- `keydown`/`keyup`-achtige state via Godot Input en `_input` of `_unhandled_key_input`: voor elke fighter own input_state.
- Gebruik fysieke keycodes voor consistente gameplay onafhankelijk van keyboard layout, configureerbaar op termijn.
- Rekening houden met gelijktijdige inputs en `just_pressed` voor aanvallen (voorkom spam bij vasthouden).
- V1 laat max één actieve attack tegelijk toe per fighter; buffer volgende input max 120 ms vóór recover.
- Na focusverlies of pause release alle inputstates om stuck movement te voorkomen.
- Blocking sluit aanvallen uit, maar laat los en aanvallen in de volgende tick toe.
- Begin ronde: input lock tijdens countdown. KO: input lock.
- Flip character sprite volgens facing, maar gebruik richting input links/rechts absoluut (no fighting-game-relative movement confusion).

## Basismoves

| Move | Basis-schade | Basis-recovery | Gebruik |
|---|---:|---:|---|
| Light | 6 | ca. 0.30s totaal | snel, relatief kort bereik |
| Heavy | 12 | ca. 0.55s totaal | langzaam, knockback |
| Special | 16 | ca. 0.8s actief + 1.5s cooldown | fighterspecifiek, projectiel/hitbox |
| Ultimate | 30 | ca. 1.2s totaal | kost 100 meter, fraaie effectintro |

Timing uit AttackData Resources, nooit hardcoded in twintig scripts. Attack-lifecycle `startup -> active -> recovery`, one-hit-per-target per activation, invulnerability uitsluitend waar specifiek ontworpen, friendly fire niet van toepassing.

## Fighter mechanics (werkbare placeholders, later art-driven)

- SharkByte: **Fin Dash** (snelle korte rush); ultimate **Abyssal Frenzy** (meerslag-blauw impact).
- Bullet: **Bull Charge**; ultimate **Stampede Breaker** (sterke grondimpact).
- Nachtelf: **Ember Bolt**; ultimate **Infernal Rift** (vuureruptie).
- PoisonBoy: **Toxic Splash**; ultimate **Venom Cataclysm** (gifzone, voor v0.1 enkel damage/effect; DOT pas goed tunen).
- Spinegrin: **Arm-Spike Volley**; ultimate **Spineburst** (groen oplichtende rugspikes, meter van rug synct).
- Chainveil: **Chain Lash**; ultimate **Iron Widow** (kettinggrip + combo).

Specials zijn onderscheidend, maar gevechtslogica/hitdetectie gebruiken dezelfde gestandaardiseerde hitbox- en damage-systemen.

## Simpele combos (v0.1)

- `Light -> Light -> Heavy`: 3-hit keten mits elk deel raakt en binnen cancel window.
- `Light -> Special`: quick special cancel met kleine timing; super niet automatisch.
- Toon combinatieteller (2+, reset na 1.2s zonder extra hit).
- Geen onbeperkte juggle/stunlock: begrens hitstun en aantal hits/cooldown.

## Hit detection en fairness

CollisionLayers gescheiden (fighter body, hurtbox, attack hitbox, projectile, arena). Hitstop ±60ms bij heavy/impact als optionele polish; round timer stopt tijdens pause, niet tussen schermtransities. Geen hit tijdens countdown of nadat fighter KO is. Beide spelers mogen tegelijk elkaar raken ('trade') als actief op hetzelfde tick. Geen onzichtbare collision op de decorstukken.

## Tests voor twee personen

1. Houd P1 `A + F` ingedrukt terwijl P2 `→ + I` uitvoert: beide acties registreren.
2. P1 springt met `W` en drukt `H`, P2 blokkeert met `↓` en drukt `O`: actieconcurrentie test.
3. Elk van de 16 gameplayknoppen afzonderlijk én in combinaties; controleer key ghosting.
4. Menu na KO/Rematch: geen stuck movement door aangehouden toetsen.
5. P1/P2 kiezen in character select tegelijk een fighter; input gaat naar correct paneel.
6. Both on same character: beide incarnaties onafhankelijk HP/special/meter/animatie.

## V9 speelbare balans en presentatie

Iedere fighter start nu met 200 HP; genezing is ook begrensd op 200. Ontvangen
schade levert ceil(schade × 0,35) ultimate-meter op, naast de bestaande meter uit
raken en blokkeren. Blokkeren geeft vier meter. De grens blijft 100 en een
ultimate kost 100. Bij een volle meter gloeien de balk en ULT-touchknop goud.
Alle tien fighters kunnen in een normale start vanuit nul meter met negen zware
hits hun ultimate opladen voordat de tegenstander KO gaat (92 HP resterend).
Dit is een geautomatiseerde inputtest, geen volledige multiplayer-balansclaim.
Alle 49 aanvalclips hebben doorlopende tussenbeelden voor voorbereiding,
uitstrekking en herstel. Het spel gebruikt dezelfde damage, hitboxes en timing.
