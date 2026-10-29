# iPhone-port van V9 / 0.9.0 — 29 October 2026

Een iOS-preset voor ARM64, iOS 15+, build 900 is toegevoegd. Godot 4.6.3 exporteert
het echte Xcode-project en 100-MiB PCK op deze Linux-host, met de officiële,
checksum-gecontroleerde iOS-engine-template. De PCK-verifier controleert iedere
bestands-MD5, tien fighters/films, 69 moves, 49 actieclips en gecompileerde
platform/touch/network-code; project/plist-checks controleren versie, device-engine,
landschap en de local-network-prompt. Dit is nog geen gebouwde of geteste iPhone-app.

GamePlatform behandelt iOS en Android als handheld: touch, geen lokale versus,
geen desktop-window/fullscreen-operaties, native pixels en safe areas. iOS gebruikt
Metal/Mobile-rendering en beide landschaporiëntaties. Wijzigende safe areas bouwen
controls opnieuw op en passen de logische arena aan. App background/focusverlies
pauzeert de fight. iOS toont geen desktop Quit-knop of Android Back-instructie.

SessionDiscovery gebruikt op iOS gewone unicast naar maximaal twee nabijgelegen
private /24-netwerken, 64 doelen per 650 ms, zodat geen beperkt multicast-entitlement
nodig is. De code/nonce/versiecontrole blijft gelijk. Dit vindt niet iedere mogelijke
LAN-indeling en omzeilt geen clientisolatie of internetrouters. Met de bestaande
Android V9-APK wordt Android als host aanbevolen. Tests oefenen echte unicast-
request/reply-sockets op loopback; geen fysieke iPhone-Wi-Fi-acceptatie wordt geclaimd.

De aparte GitHub Actions workflow bouwt op macos-15 met Xcode, zonder Apple
credentials, een unsigned device IPA. Publicatie gebeurt alleen als de echte
ARM64 iPhoneOS executable, versie/plist, volledige ZIP-CRCs en alle PCK-bestanden
zijn gevalideerd. AltStore ondertekent op de computer van de gebruiker. Gratis
Apple-accounts vragen normaal elke zeven dagen om vernieuwen; de Nederlandstalige
handleiding behandelt Windows/Mac, developer trust/mode en netwerktoestemming.
Native iPhone-installatie, Metal-beelden, audio, notches/rotatie, prestaties en
fysieke twee-device sessies zijn niet getest in deze Linux-omgeving.

Voor deze port zijn 1.004 broncontroles opnieuw geslaagd: core/art/expansion/roster
896, iOS/mobile/unicast 25, echte drie-processen netwerk-integratie 25, touch 38
en native-resolutielayouts 20. Acht originele hashes en tien volledige films zijn
ook opnieuw gecontroleerd. De export bevat geen tests, docs of buildbestanden.
Een builds/.gdignore voorkomt dat gegenereerde Xcode-iconen opnieuw als game-
assets worden geïmporteerd bij een volgende export.

Deze port houdt versie 0.9.0 zoals gevraagd. Het bestaande Android-artifact,
ondertekening, tag en alle oorspronkelijke artwork blijven ongewijzigd.

---

# V9 whole attacks, planted movement and ultimate readiness — 29 October 2026

V9 / 0.9.0, Android code 900. All ten fighters now render continuous whole-attack
in-betweens across 49 clips, including anticipation, chamber, extension/contact,
recovery and idle return. Another 266 bidirectional vector fields and fixed
support-foot pivots supplement the existing artwork. Walking's 54 fields were
re-analyzed around steady torso/ground anchors; strides cover two steps, grounded
whole-body offsets are removed and extra bounce is reduced. Gait now follows
resolved locomotion distance, including opponent/wall collision and guest state.
The persistent 3D podium uses the same interpolated signature and rings.

Combat has angular dark HUD panels, animated energy gauges and a gold pulse at
100 meter, matched by the ULT touch halo. HP is 200 for all fighters, round reset,
healing cap and HUD. Clean incoming damage grants ceil(actual_damage × .35)
meter, while blocking retains four; the cap and ultimate cost remain 100.

| Final required check | Result and scope |
| --- | --- |
| Immutable art / intro media | PASS — eight source hashes unchanged; ten complete intro decodes |
| Core / art / expansion / roster | PASS — 70 + 494 + 45 + 287 = 896 assertions; all 69 moves and ten full CPU matches |
| Touch / persistent 3D gallery | PASS — 38 + 92 rendered assertions |
| Linux / intro rendering | PASS — 9 + 31 assertions |
| Codes / network / resolution / modern UI | PASS — 53 + 25 + 20 + 10 assertions |
| Real rendered network repeat | PASS — same 25 assertions, three actual Godot processes |
| Movement / GPU compositing | PASS — 121 + 37 assertions, all ten fighters |
| New whole-attack / balance checks | PASS — 160 assertions, all 49 clips, decoded fields, actual heavy poses, fixed feet, normal-input ultimate earn/spend/hit, collision gait, HP and ready/pause UI |
| New rendered attack / gold gauge checks | PASS — 20 assertions, all ten fighters, distinct rendered attack images and actual GPU pixels of the golden bar |
| Native Linux release engine + PCK | PASS — OS keyboard menu/Fighters/select/arena/fight, actual visible damage, pause and normal Quit; no installed editor needed |
| Android export / payload / CRC / signing | PASS — ARM64+x86_64; new compiled motion/UI scripts and shaders; 49 clips / 266 action fields; v2/v3 signatures and 16-KiB native alignment |
| Android manifest / retained certificate | PASS — 0.9.0 / code 900; min API 24 / target 36; same V4–V8 development certificate |
| Combat preview | PASS — full decode, 1280×720, 60 FPS, 1,111 frames / 18.516667 seconds |
| Physical Android / two-device Wi-Fi | NOT RUN — no attached device; no Android runtime, digitizer, thermal or frame-rate acceptance claimed |

There are **1,512 distinct successful automated source assertions**. The repeated
network run and direct quality rerun are additional executions. Media, original
hashes, export/signing and native package checks are separate. Final required
runs contain no script/engine errors or leaked instances. The software display's
unsupported V-Sync warning is unchanged. Tests and video scripts are excluded
from the APK. Final logs, sample screenshots and the native smoke helper are in
releases/android-v0.9.0/validation/.

## Ultimate availability

Each fighter starts from normal 200 HP and zero meter, walks to the opponent and
uses only ordinary heavy/movement input. No meter/HP fixtures or repositioning
are used in the balance loop. All ten reach 100 meter after nine heavy hits while
the target still has 92 HP, then spend 100 and land their default ultimate.
The sequence including approach and ultimate completes in 7.85–8.25 simulated
seconds. Resulting target HP is 62 normally, 66 for Lava Stone and 64 for Crystal
Fang, reflecting existing per-move damage. Separate checks cover incoming meter,
guarding, healing cap and reset. This establishes basic availability, not human
competitive balance. The video uses a ready-meter UI fixture and slow-motion
heavy attacks; its charged meters are not evidence of earning meter in combat.

## Frame pacing and animation limits

Separate final V9 runs use the native Linux X11 window, llvmpipe software renderer,
two fighters walking/reversing, a two-second warm-up and six-second sample window.
Actual intervals use monotonic Time.get_ticks_usec(), not fixed video cadence.
No other GPU test or video recording runs concurrently with these measurements.

| Native size | Actual average FPS | Median frame | p95 | p99 |
| --- | ---: | ---: | ---: | ---: |
| 1280×720 | 59.87 | 16.664 ms | 19.587 ms | 22.075 ms |
| 2400×1080 | 43.62 | 21.601 ms | 31.676 ms | 35.924 ms |

The wide software-rendered workload still misses the 60-FPS budget. These short
runs are not a controlled speedup comparison or physical Android measurements.
Engine delta/process diagnostics in the raw JSON are not CPU or phone metrics.
The 60-FPS Movie Maker recording is offline animation review, not a live benchmark.
Native resolution and the 60-FPS cap remain; device frame pacing needs testing.
Motion-aligned existing illustrations provide continuous in-betweens, not new
independently hand-drawn frames. Limb disocclusion/warping can still be visible.

## Published package

APK size: 153,018,490 bytes. SHA-256:
01991a370360af3a38bfc869cadfdd132cc00c3c642186a96c26482c5b4cce24.
The APK uses the retained development certificate and is a sideload preview.
V9 must be installed on both peers. Same-Wi-Fi six-character direct sessions,
native resolution, ten fighters, 69 moves and all ten films are retained.
Different networks / 4G / 5G still need a relay/NAT traversal service; none is
bundled. Previous published versions and tags are preserved.

---

# V8 persistent rings and continuous movement — 29 October 2026

V8 / 0.8.0, Android code 800. Fighters retains the same lit 3D character, world,
podium and rings after the move. The camera settles while breathing/sway continues;
there is no switch to another 2D sprite. Sheet view pauses the existing world;
return/replay retains its nodes. All ten fighters have continuous walk in-betweens
plus individual start/brake/backstep/pivot, rise/apex/fall/land and guard transitions.

| Final required check | Result and scope |
| --- | --- |
| Immutable art and intro media | PASS — eight source hashes unchanged, ten complete film decodes |
| Core / art / expansion / roster | PASS — 70 + 494 + 45 + 287 = 896 assertions |
| Existing touch / persistent gallery | PASS — 38 + 92 rendered assertions |
| Existing Linux / intro rendering | PASS — 9 + 31 assertions |
| Codes / network / native resolution / UI | PASS — 53 + 25 + 20 + 10 assertions |
| Rendered real-network repeat | PASS — same 25 assertions using three real processes |
| New movement state / cache / cadence checks | PASS — 121 assertions, all ten fighters |
| New movement and GPU opacity rendering | PASS — 37 assertions, all ten fighters |
| Native Linux release engine + PCK | PASS — OS keyboard menu/showcase/select/arena/fight/damage/pause/Quit, normal exit 0 |
| Android export, CRC, payload, signature and alignment | PASS — ARM64+x86_64, compiled movement code, 54 fields/ten profiles, v2/v3 signing and 16-KiB alignment |
| Android manifest and update certificate | PASS — 0.8.0 / code 800, min API 24 / target 36; same retained V7 development certificate |
| Published movement video | PASS — full decode, 1280×720, 60 FPS, 1,188 frames / 19.8 seconds |
| Physical Android / two-device Wi-Fi | NOT RUN — no physical device attached; no Android runtime/FPS acceptance claimed |

There are 1,332 distinct successful source assertions. The rendered network
repeat and separate recorded movement repeat are additional executions. Media,
hash, signature and native-package checks are separate. Final required runs have
no script/engine errors or leaked instances. The known software-display V-Sync
warning and optional absent adb-daemon probe do not prevent builds or these tests.

The 121 motion checks drive real controllers for every fighter: starting, reversing,
braking, backstepping and a complete jump through rise/apex/fall/landing; guard
entry/exit; pause/reset; cache reuse and matching phase at 60/120 time samples.
Collision, HP/meter and every attack/CPU regression remain unchanged. Tests caught
a direction reversal crossing below the movement threshold: short neutral crossings
now preserve the previous travel direction so the pivot clip is not skipped.

The new GPU test actually renders an offscreen transparent viewport and checks
that overlapping opaque poses remain opaque halfway through a blend. Initial
fixture setup omitted UPDATE_ALWAYS for an undisplayed viewport; the corrected
fixture renders it explicitly. Normal walking uses one pass with aligned poses.
Existing artwork is analyzed into 54 bidirectional motion fields; it is not
replaced or repainted. All ten original key sets and their unique-image counts
remain intact. Motion vectors and movement curves create derived intermediate
poses, not 60 independently hand-drawn images. Occluded limbs can still show
small interpolation/warping artifacts; final artist and human feel review remains.

The rendered gallery checks retain world/character/ring identity after all ten
entrances, framing, continuing breathing, original sheets and replay. The new
movement fixture renders every fighter's actual controllers through gait, pivot,
jump and landing while preserving HP and returning to the floor. The video shows
that scripted fixture; it is not a human match or live Android performance result.
Movie Maker records 60 samples/second offline. Cropping/encoding retains that
frame rate without generating frames; the final MP4 fully decodes 1,188 frames.

## Actual frame pacing, separate from offline recording

A repeatable scripted two-fighter workload uses the V7 visual script/shader and
current V8, the same scene and 60-FPS cap. After two seconds of warmup, six seconds
are sampled per condition on Linux X11 / Mesa llvmpipe software rendering. Frame
intervals use Time.get_ticks_usec; engine delta and process-monitor values are
retained only as diagnostics. The table reports the actual monotonic clock.

| Native framebuffer | V7 mean FPS | V8 mean FPS | V8 p95 frame interval |
| --- | --- | --- | --- |
| 1280x720 | 59.92 | 59.92 | 16.88 ms |
| 2400x1080 | 43.48 | 41.24 | 35.27 ms |

This is one sample per condition, not a phone benchmark or a general speedup
claim. Both versions approach the cap at 720p; the wide software-rendered case
does not achieve 60 FPS, and V8 is slower in that sample. The improvement targets
animation continuity between authored poses, not a guaranteed increase in engine
FPS. Cached geometry eliminates per-render polygon reconstruction, while motion
alignment adds GPU work. Native resolution is preserved. Actual hardware GPU,
thermal and 60-FPS frame pacing on phones/tablets still need acceptance.
Reproduce with ./tools/benchmark_motion.sh (V7 tag required); do not run competing
render/encode workloads while measuring.

The signed APK remains a sideload preview, retaining the development certificate
for an in-place V7 update. The six-character same-Wi-Fi host-device sessions and
modern thumbstick/skill controls remain intact. No Internet relay is added.
Still required: physical install/update, Wi-Fi/multitouch, audio, cutouts, thermal
behavior, frame pacing and final two-human animation/ergonomic review. Every
published change gets a new version/code/path/tag; older releases are retained.

# V7 six-character rooms, character showcase and thumbstick UI — 29 October 2026

V7 / 0.7.0, Android code 700, replaces the V6 endpoint invitation and move lab.
CREATE SESSION now makes exactly six random letters/numbers. The host device
advertises the temporary room; the guest enters only the code. The UI exposes
no addresses. This is same-Wi-Fi direct play without an extra hosted server.
Different networks / 4G / 5G still require rendezvous/NAT traversal/relay support;
none is deployed or bundled, and the connection UI states this limitation.

| Final check | Result and scope |
| --- | --- |
| Immutable art and intro media | PASS — all eight hashes unchanged, ten full film decodes |
| Core / art / expansion / full roster | PASS — 70 + 494 + 45 + 287 = 896 assertions |
| Actual touch/drag/cancel and analog combat | PASS — 38 assertions |
| All ten character presentations | PASS — 92 rendered assertions, including full camera framing |
| Existing Linux rendered integration / intro expansion | PASS — 9 + 31 assertions |
| Six-character codes / input / Android routes | PASS — 53 assertions |
| Actual broadcast discovery + ENet | PASS — 25 assertions over three separate OS processes |
| Rendered network repeat | PASS — same 25 assertions with X11-rendered game peers |
| Native framebuffer sizes | PASS — 20 assertions over seven phone/tablet/window formats |
| Actual create/cancel UI and combat layouts | PASS — 10 assertions; no visible endpoint information |
| Android export / payload / signatures / alignment | PASS — final universal ARM64+x86_64 APK, compiled V7 discovery/presentation code, CRCs, v2/v3 signing, 16-KiB alignment |
| Android version / compatibility | PASS — version 0.7.0 / code 700, API 24 minimum / 36 target; retained V6 development certificate for update |
| Native Linux release engine + PCK | PASS — OS keyboard menu/showcase/select/fight/damage/pause/Quit, normal exit 0 |
| Physical Android / Wi-Fi acceptance | NOT RUN — no physical devices attached; no native Android end-to-end pass claimed |

There are 1,174 distinct successful source assertions; the 25 network assertions
also pass with rendering. Media/hash and native package checks are separate.
The final required suites have no script/engine errors or instance leaks. X11's
unsupported V-Sync warning is a known virtual-display limitation. An optional
Android editor device-list probe can report the absent adb daemon; export and
signature/payload checks still complete with exit 0. This does not mean an Android
device was present or exercised.

The network fixture uses actual IPv4 broadcast lookup on UDP 38747 and unicast
replies, then the real ENet peer, rather than an injected endpoint/mock service.
An unknown code times out without creating a fake match; a valid code connects,
owned selection/readiness starts the match, guest movement/light/projectile and
host heavy apply exact health changes, pause votes freeze the timer, results
agree, mutual rematch increments the epoch and leaving returns the guest to UI.
Round-transition KOs remain fixtures. Local process traffic proves the protocol,
not physical Wi-Fi reachability, carrier NAT or encrypted account authentication.

Touch tests inject real screen events, cover simultaneous stick/attacks, analog
magnitude, deadzone recentering, off-base clamping/release, canceled contacts,
finger ownership, keyboard isolation, all actions, actual damage and directional
armor/shield commands. Pause/background/round transitions clear inputs. Layouts
fit five phone/tablet formats. A legacy two-pad component remains tested only for
desktop reuse; Android cannot enter shared-screen versus. A one-pixel stick-edge
tolerance fixes boundary hit tests under scaled layouts; assertions compare
fractional motion with float tolerance. Combat readiness rings use actual special
cooldown and meter. The UI suite clicks CREATE and CANCEL and scans visible
label/button/input text to ensure addresses never leak into the screen.

Fighters tests click all ten cards, render the actual perspective 3D world and
textured extruded silhouette, check the signature heavy, full camera framing,
automatic transition after 2.8 seconds, stationary breathing idle, original-sheet
pause/return and replay. The old movement tour and executable move list are gone.
The 3D viewport stops during idle/sheet view. Visual review caught a wide Crystal
Fang bite cropping outside the camera; the entrance now fits the maximum authored
width/height and centers each pose on the podium. All ten framing checks pass.
This is a 2.5D presentation built from existing art, not newly modelled/rigged
characters. No original artwork pixels have changed.

Native resolution remains unchanged: actual framebuffer readbacks, viewport/root
and safe stage proportions are checked from 960×540 through 2560×1440, including
2400×1080 phones and 1024×768 tablets. Modern combat screenshots additionally
cover 1280×720, 2400×1080 and 1024×768 with one thumbstick, adjacent block, a large
Attack and surrounding heavy/special/ultimate/jump, plus pause.

The native Linux package also passed outside the editor, with X11 key injection,
rendered character showcase, owned selections, active timer, actual damage pixels,
pause and normal Quit. The harness now waits for visible menu/select/arena/fight
states; fixed delays could send keys while a new screen was loading. Whole-image
OCR could omit a clearly rendered HUD, so names/active time are checked before
attacks and the actual health-bar change checks damage. Final native log has
normal exit 0 and no engine/script errors. This remains a Linux package result.

Still required: install this exact APK on two phones/tablets and test temporary
room lookup on real Wi-Fi, own touch movement/attacks, pause/background/resume,
rematch/disconnect, cutouts, physical multitouch, audio, thermals and native pixel
frame rate. The guest uses smoothing without prediction/rollback. No physical
Android, public Internet service or two-human ergonomics result is inferred from
Linux tests. All versions are retained; later changes get a fresh APK/code/tag.

# V6 native resolution + direct sessions — 29 October 2026

This supersedes earlier Android shared-tablet and fixed-render-resolution behavior.
V6 / 0.6.0 (Android versionCode 600) follows the actual device surface, preserves
logical arena proportions and replaces Android local versus with a session-code
connection between two devices. CPU solo remains offline. Direct IPv4/UDP requires
a reachable host, normally the same Wi-Fi. No Internet relay or NAT traversal is
bundled; different networks / 4G / 5G are not automatically connected by a code.

| Final check | Result and limits |
| --- | --- |
| Original sheets + ten intro films | PASS — eight SHA-256 hashes unchanged; ten full film decodes |
| Core / artwork / expansion / roster | PASS — 70 + 494 + 45 + 287 = 896 assertions |
| Existing rendered touch / gallery / Linux / expansion | PASS — 35 + 84 + 9 + 31 = 159 assertions |
| Session-code, input validation and Android routes | PASS — 35 assertions |
| Real ENet multi-process gameplay | PASS — 25 assertions, three processes over loopback UDP |
| Rendered ENet repeat | PASS — the same 25 assertions with real X11-rendered peers |
| Native framebuffer and mobile UI | PASS — 20 assertions; framebuffer, viewport and root track actual pixels |
| Native Linux release engine + PCK | PASS — X11 keyboard menu / move lab / select / fight / damage / pause / normal Quit; exit 0 |
| Android export / payload / archive integrity | PASS — signed universal ARM64 + x86_64 APK; compiled V6 scripts and ten films |
| Android signing / alignment / manifest | PASS — v2/v3 signatures, 16-KiB alignment, code 600 / version 0.6.0, API 24 minimum / 36 target, landscape; INTERNET + ACCESS_NETWORK_STATE |
| Physical Android / Wi-Fi acceptance | NOT RUN — no physical devices attached; no native Android end-to-end success claimed |

The source suites execute 1,135 distinct assertions, with the 25 network assertions
also repeated under rendering (1,160 successful assertion executions). Hash,
film and native-package checks are separate. Final logs contain no engine/script
errors or leaked-instance warnings. The software X11 display's unsupported V-Sync
warning is a known display limitation, not a device performance measurement.

The native-resolution suite checks actual framebuffer image dimensions as well
as the viewport/root at 960×540, 1280×720, 1920×1080, 2560×1440, 1280×800,
1024×768 and 2400×1080. It checks stage aspect, live Options pixel readout,
Android route removal, offline CPU and one nine-button touchpad. Godot Window.size
must be used in resize tests: changing DisplayServer's low-level window size
alone does not resize the engine framebuffer, which a framebuffer assertion caught.

The network test launches a host, wrong-nonce client and then valid guest. It
checks rejection/recovery, owned character selection, both-ready start, countdown
input lock, guest move/light/projectile damage at the host, host damage at the
guest, exact synchronized HP, shared pause votes, frozen time, matching best-of-three
results, mutual rematch with a new epoch and host disconnect back to usable UI.
Fixture KOs set low HP to exercise round transitions; this does not establish a
human-played full network match. Tests use separate real processes and UDP,
but do not establish physical Android/Wi-Fi, lossy Internet or carrier NAT behavior.
The legacy shared-pad component layout remains tested in isolation for desktop
reuse; Android's menus and match entry points prohibit local versus.

Network testing caught and fixed unsafe peer replacement during an ENet callback,
forced-disconnect bookkeeping, a paused guest's stale timer readout and an existing
Android HUD footer allocation leak. Peer shutdown is deferred outside polling,
rejection disconnects gracefully after its error response, pause sends an exact
reliable state, and the footer is allocated only on desktop. Final headless and
rendered runs have no corresponding errors/leaks. Countdown and paused controls
are dropped on both sides; no delayed attack should escape into the next round.

Native Linux smoke uses OS key injection and rendered screenshots outside the
editor. Android checks validate the actual final APK's CRCs, libraries, films,
compiled code, manifest, signature and alignment; Linux results are not presented
as Android runtime results. The retained v0.4/v0.5 certificate signs V6 for in-place
updates. The APK remains a sideload preview using a local development key.

Still required: install this exact APK on two phones/tablets and test host/join,
owned touch movement/attacks, background/pause/resume, result/rematch/disconnect,
physical multitouch, Wi-Fi isolation, cutouts, audio, thermal behavior and native
high-resolution frame rate. Native resolution can increase GPU load. The guest
uses smoothed host snapshots without prediction/rollback; high latency will be
felt. Prior cloud emulator limitations remain recorded below. All final logs,
artifact checksum, source hashes and representative screenshots accompany V6.
Published tags and APKs are retained; each future update must get a new version.

# Full roster + interactive move lab v0.5.0 — 29 October 2026

All ten fighters are playable in versus and CPU mode, with animated selection
and gallery previews. The five missing sets now have reference-guided generated
combat art. The four detailed new move sheets have all their named moves mapped
to playable directional inputs. The roster contains 69 attacks/abilities.

| Required check | Result |
| --- | --- |
| Original reference integrity | PASS — all 8 original SHA-256 hashes unchanged |
| Godot import / core gameplay suite | PASS — 70 passed, 0 failed |
| Ten-fighter artwork / animation suite | PASS — 494 passed, 0 failed |
| Earlier fighter-expansion suite | PASS — 45 passed, 0 failed |
| Full roster / real moves / CPU matches | PASS — 287 passed, 0 failed |
| Ten bundled films | PASS — full decode, 193 frames per film |
| Real rendered gallery click tests | PASS — 84 passed, 0 failed |
| Touch / directional variant tests | PASS — 35 passed, 0 failed |
| Existing Linux rendered integration | PASS — 9 checks, 0 failures |
| Existing sheets / intros / expansion rendering | PASS — 31 passed, 0 failed |
| Linux native release-engine package | PASS — official 4.6.3 release engine, menu/move lab/select/fight/damage/pause, normal exit 0 |
| Android universal APK | Export/signature/alignment/payload checks pass; ARM64 + x86_64, versionCode 500 |
| Native Android / physical phone/tablet acceptance | NOT RUN for v0.5 — no device attached; prior software-emulator limits remain |

The 1,055 source-level/integration/artwork/rendered assertions are distinct from
native package checks and media/hash checks. No final suite reports script or
engine errors or leaked instances. The X11 software display's unsupported V-Sync
warning is expected. The current tests replace the old assumption that only five
fighters can ready; all ten must now enter versus.

The roster suite executes every named attack through its actual directional
binding, verifies exact total damage (including three-projectile volleys), meter
costs, insufficient-meter rejection, armor/power/invulnerability activation and
healing. Every CPU must win a complete normal-health match against a passive
player. Defensive tests check half damage, true invulnerability, no shared attack
resource mutation, landing jump buffering, smooth acceleration, evading low
attacks by jumping, capped healing, real Rebirth hitstun escape and no KO revival.
The touch suite additionally performs Lava Stone armor and P2 Crystal Fang shield
through simultaneous contacts and facing-relative commands.

The move lab runs the same controllers, hitboxes, projectiles and resource costs
as combat. Only its preview resets HP/meter between demonstrations. Real GUI
clicks test every fighter, heavy/ultimate selection (including scrolling), manual
autoplay interruption/resumption, original sheet toggling and live rendering.
It also verifies that the automatic tour advances and gait frames change over
time. Original intro navigation and decoding still work for all ten fighters.

Art inspection and screenshots confirmed preserved identity, transparent
silhouettes, natural claw feet for Crystal Fang/Phoenix Reign, full extended kick
feet and recognizable bite/slam/wing/buff poses. Supplemental art replaced heavy
poses that initially looked like punches instead of named kicks/bites. Heavy
extension keys now align with the active hit window. These are illustrated
key-pose animations with 55 ms blending and secondary motion, not fully hand-drawn
in-betweens. Physical feel, final balance, device thermal/FPS behavior, sound,
cutouts and two-human ergonomics still require hands-on testing.

The v0.5 APK uses the same retained local development certificate as v0.4, allowing
an in-place update. It remains a sideloadable preview, not a Play Store release.
No native Android success is inferred from source tests or APK signature checks.
The native Linux smoke test uses actual X11 key injection and screenshot checks, not internal scene calls. It reaches the packaged move lab, selects two fighters, starts combat, applies visible attack damage, pauses and exits through the normal Quit confirmation with code 0. An initial smoke-harness OCR check missed the small HP text despite visible damage; the final check reads the actual health-bar change. No application change was needed for that harness correction. Detailed logs, hashes and representative screenshots accompany the new release.

# Android preview v0.4.0 — 29 October 2026

Source milestone: `289326f`. Standard Godot 4.6.3; Android release templates
verified against the official SHA-512 sums. Google SDK components were checked
against their repository checksums. Linux remains supported.

| Check on the final source / artifact | Result |
| --- | --- |
| Original artwork integrity | PASS — all 8 original SHA-256 hashes unchanged |
| Headless integration/combat | PASS — 70 passed, 0 failed |
| Artwork/animation | PASS — 229 passed, 0 failed |
| Fighter expansion | PASS — 45 passed, 0 failed |
| Intro film decode | PASS — all 10 films, 193 frames each |
| Rendered Linux regression | PASS — 9 checks, 0 failures |
| Rendered multitouch suite | PASS — 33 passed, 0 failed |
| Reproducible Android export/signing script | PASS — exit 0, no engine/script errors |
| Final APK payload and CRCs | PASS — ARM64 + x86_64, compiled touch scripts, all ten films |
| APK signing and native alignment | PASS — APK v2/v3 signatures; `zipalign -c -P 16 4` |
| Manifest | PASS — package `org.infernoduel.legends`, version 0.4.0/code 400, min API 24, target 36, landscape, small through xlarge screens |
| Native Android end-to-end acceptance of final APK | NOT COMPLETED — software-emulator limitation, described below |
| Physical phone/tablet acceptance | NOT RUN — no physical Android device attached |

The touch suite exercises actual ScreenTouch, ScreenDrag and canceled events:
simultaneous move/attack, damage from touch, one press edge per hold, independent
finger release, drag-off release, keyboard isolation, guard/jump/special/ultimate,
touch pause/resume, mobile options, background clearing, round/reset invalidation
and two simultaneous players. Ten layout checks use actual SubViewports at five
phone/tablet sizes (16:9, 16:10, 4:3 and wide phone), both solo and shared modes,
and reject clipped or overlapping controls. These are software-injected touches;
they do not establish physical digitizer behavior or comfort.

## Android emulator evidence and limit

An earlier signed candidate installed successfully on an Android 15/API 35
x86_64 emulator. The cloud host has no `/dev/kvm`; the emulator uses slow TCG CPU
emulation. Its direct SwiftShader GLES driver failed Godot shader linking with
`Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`.
This rendering attempt is **not a pass**. Restarting the same AVD with the
supported `-gpu swangle` backend reached GLES 3.1 initialization and
`OnGodotMainLoopStarted` without those shader errors, but did not establish a
complete interactive Android game flow.

A readback/hash comparison correctly detected that the installed candidate was
older than the final download. Attempts to replace it with the final APK timed
out in Android's package installer, including after the final APK had been
successfully transferred. The native result therefore must not be attributed to
the final APK. The final download is build/signature/payload verified; its native
menu-to-fight flow still needs on-device acceptance. No physical-phone result,
runtime performance claim, or fully passed emulator smoke test is made.

The preview is signed with a local development key, not a production Play Store
key. Its exact checksum, source hashes and successful test logs are in
`releases/android-v0.4.0/`. Real-phone/tablet checks should cover installing this
exact APK, menu/select/fight/result/rematch, multiple fingers, Android Back,
pause/background/resume, audio, cutouts, frame rate and tablet shared-player
ergonomics. See `docs/ANDROID.md` for build and install commands.

# Linux v0.3.0 validation, 28 October 2026

Engine: Godot **4.6.3.stable.official.7d41c59c4**, standard Linux x86_64,
Compatibility renderer, 60 Hz physics. Rendered tests use Xvfb 1280×720 and Mesa
llvmpipe. Input is automated; no two-human keyboard test is claimed.

| Required check | Result |
| --- | --- |
| Immutable original artwork | PASS — 8/8 SHA-256 hashes |
| Godot editor import | PASS — exit 0, no script/engine errors |
| Original integration/combat suite | PASS — 70 checks, 0 failures |
| Sprite/avatar/state suite | PASS — 229 checks, 0 failures |
| Fighter expansion suite | PASS — 45 checks, 0 failures |
| Ten film files | PASS — full decode, 193 frames each, distinct close-up/kick images |
| Base rendered integration | PASS — 9 checks, 0 failures |
| Expansion rendered integration | PASS — 31 checks, 0 failures |
| Native release-engine + PCK | PASS — startup, X11 menu/gallery/film/select/fight/pause/quit |

The 344 gameplay/artwork checks cover the original flow plus five playable fighters,
new attacks, block/chip, meter costs, PoisonBoy projectile single-hit behavior,
Chainveil range/pull, Cheese Rat ball/trap/ultimate, trap expiry and the three-object
per-owner cap. Each new CPU fighter completes a full normal-health match against
a passive player. The new three fighters have distinct animation sets and previews.

The 40 rendered checks include all three individual gallery sheets, all ten real
intro buttons decoding 1280×720 video, replay from the beginning, clip completion,
Esc returning to the same fighter, and the three new fighters reaching combat.
Gallery keyboard focus now returns to the selected fighter. Source screenshots
are generated in `/tmp/inferno-visual/` and `/tmp/inferno-v03-visual/`.

`tools/verify_intros.py` uses FFprobe/FFmpeg to decode each film, verify its 30 FPS,
6.43-second duration and 193-frame count, and compare actual video frames. This
is separate from Godot's real-time playback tests. All ten films were rendered
from the deterministic cinematic timeline. The shoe/claw close-up and camera-kick
framing were also visually inspected. Crystal Fang/Phoenix Reign retain their
original claw feet, as confirmed by the user.

The independent native bundle uses the official Linux **release template**, not
the editor engine used by v0.1/v0.2. Matching version and official ZIP-entry CRC32
were checked. Template SHA-256:
`2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.
The wrapper uses adjacent PCK discovery. X11 actions exercised PoisonBoy's own
sheet, its actual movie inside the pack, return to the same sheet, PoisonBoy versus
Chainveil, attacks, pause and normal Quit. Representative screenshots are retained
in `docs/screenshots/`. Release `validation/` includes logs and source hashes.

No final required check reported script errors, engine errors or instance leaks.
The initial sandboxed editor check could not create its local socket; repeating
through the supported execution permission path passed. Xvfb still reports that
V-Sync switching is unsupported; this is a virtual-display limitation. Review
caught a low Cheese Ball spawn, corrected to the caster's hand height before the
final combat validation and package. No source sheet pixels were changed.

## Remaining acceptance and scope

Physical F5 interaction, two humans sharing a real keyboard, hardware ghosting,
real speaker output and gameplay balance still require manual testing. The new
sets use keyed illustrated poses; extra in-betweens and final artist review remain
useful. Nachtelf, Spinegrin, Lava Stone, Crystal Fang and Phoenix Reign have avatars,
sheets and intros but are not yet combat-ready. Complete extra move lists, Story,
rebinding, recorded music/voice and Android remain future milestones.

## Historical validation below (v0.1 / v0.2)

These entries describe earlier builds. Their missing-artwork, two-fighter and
editor-engine limitations are superseded by the v0.3 status above.

# Validation — 27 October 2026

Engine: Godot **4.6.3.stable.official.7d41c59c4**, standard Linux x86_64,
Compatibility renderer, fixed 60 Hz physics. Cloud virtual display: Xvfb 1280×720,
Mesa llvmpipe OpenGL 4.5. Tests used generated input, not two humans on a keyboard.
See `builds/validation/source.sha256` for the exact implementation-file hashes
of the validated build (generated by packaging). This historical entry describes validation before the v0.1 publication.

## Completed

| Check | Result | Evidence / limits |
| --- | --- | --- |
| Original artwork integrity | PASS — 8/8 | SHA-256 via `python3 tools/verify_assets.py` |
| Godot editor import | PASS — exit 0 | `godot --headless --path . --editor --quit`, no engine/script errors |
| Automated integration/combat | PASS — 70 checks, 0 failures; exit 0 | `tools/test.sh`; underlying output scanned for runtime errors and leaks |
| Rendered integration | PASS — 9 checks, 0 failures; exit 0 | `godot --path . --audio-driver Dummy tests/visual.tscn` under Xvfb |
| Native X11 keyboard input | PASS | `xdotool`: menu → both ready keys → arena → fight; simultaneous move and attack keys |
| Linux engine + PCK package | PASS — startup exit 0 | `builds/linux/PLAY.sh --headless --quit-after 15`; full editor engine bundled because export templates absent |
| Packaged native window | PASS | X11 keyboard flow: menu → select → arena → simultaneous move/attack → pause; no runtime errors |
| Physical F5 key in editor | NOT RUN | Main scene loaded and rendered directly; F5 entry point is configured, but no human editor interaction claimed |
| Two humans / physical keyboard ghosting | NOT RUN | Requires the target keyboard; software injection cannot prove hardware rollover |
| Real sound output | NOT RUN | Synthesized streams exist; validation used headless/Dummy audio, not speakers |
| Production template export | NOT RUN | Matching export templates are not installed; repeatable release export command supplied in README |

## Automated coverage

The 70 checks cover boot/menu and ten roster slots; independent character cursors;
unavailable roster feedback; both confirmations; countdown input lock; all sixteen
physical mappings; simultaneous move/attack events; edge triggering; state clearing;
movement; same-tick damage trades; hit meter; one hit per activation; directional
ground guard/chip; out-of-range misses; special cooldown; 120 ms follow-up buffering;
light-to-special recovery cancel; ultimate cost/damage; Bullet ground-shock projectile;
light/light/heavy three-hit combo; escape immunity; jump/no double jump; gravity;
arena boundaries; pause timer; cleared resume inputs; focus-loss pause; paused Options;
timeout winner; per-round meter retention; equal-timeout replay; draw round numbering;
double KO; complete scripted 2–1 match; rematch resets; restart confirmation/cancel;
all ten gallery sheets; Story preview; Easy CPU approach/damage; full CPU match against
a passive player; mirror-match state separation; and saved settings.

The scripted 2–1 fixture reduces HP to six before each final exchange to exercise
round transitions deterministically. The separate CPU full-match check uses normal
100 HP, attacks, cooldowns and 60-second timers, without health shortcuts.

The nine rendered checks cover keyboard entry into versus, both ready confirmations,
simultaneous movement and damage in the real physics loop, frozen pause timer,
Options focus, fullscreen, gallery focus, and a 960×540 window retaining the logical
1280×720 interface. Eight screenshots are generated under `/tmp/inferno-visual/`.
Representative screenshots are retained in `docs/screenshots/`.

## Diagnosed and fixed during development

- Options and Gallery initially lacked an initial keyboard focus target.
- Draw replay initially incremented the round number; it now retries the same round.
- Confirmation dialogs now hide before being freed and ignore duplicate opening.
- SFX now use a bounded 12-voice pool; fast simulation tests wait for playback cleanup.
- The initial resize assertion incorrectly expected manual stage scaling despite Godot's
  canvas stretch already maintaining the logical viewport. The corrected check verifies
  actual window dimensions plus logical UI dimensions; the saved screenshot confirms it.
- Restricted command sandbox blocks proxy access and local editor/X11 sockets. Native
  network/graphical validation used the supported escalation path. Writable XDG paths
  under `/workspace/.runtime/` avoid attempting writes into read-only home directories.
- Xvfb reports unsupported V-Sync mode switching. Rendering continues normally; this is
  a virtual-display limitation, not a demonstrated gameplay defect.

## Manual acceptance checklist — still required

1. Open `project.godot` in Godot 4.6.3 on Linux and press F5.
2. Play a full match with two people on the same physical keyboard. Test A+F while
   the other player uses Right+I, and W+H while the other holds Down+O.
3. Check key rollover/ghosting, held keys during focus loss, ergonomics, and input feel.
4. Check actual audio, fullscreen, windowed mode, confirmation dialogs and rematch.
5. Review balance, geometry readability, and collision/combos using F3 hitboxes.

## Known scope gaps

Only SharkByte and Bullet are playable. Combat characters and arena are explicit
geometric prototypes; supplied sheets are only gallery references. No validated
sprite animation, final music/voice, complete ten-fighter move sets, rebinding,
Story campaign, Android build, or production export-template validation yet.

# Visual build v0.2 — 28 October 2026

This update supersedes the v0.1 geometric-renderer and missing-animation notes
above. SharkByte and Bullet now use illustrated reference-derived sprite sets;
all ten roster fighters have distinct original-sheet avatars. See ART_PIPELINE.md.

| Required check | Current outcome |
| --- | --- |
| Original source hashes | PASS: 8/8 unchanged |
| Editor import + gameplay/flow suite | PASS: 70 checks, zero failures, exit 0 |
| Sprite/avatar suite | PASS: 103 checks, zero failures, exit 0 |
| Rendered Linux integration | PASS: 9 checks, zero failures, exit 0 |
| Deterministic animation showcase | PASS: recorded 496 frames at 30 FPS, 16.5 seconds; all ten animation states shown |

No script errors, runtime errors or leaked-instance warnings occurred in the final
required checks. The virtual-display V-Sync warning remains the same platform
limitation as in v0.1. The showcase is a scripted artwork review rather than a
human-played match. Renderer telemetry averaged about 10 ms GPU and 2 ms CPU per
recorded frame on llvmpipe; this is not a frame-rate guarantee for another machine.

Visual review covered the original likeness references, alpha cutouts, portrait
identity/cropping, frame isolation, idle/walk, block, jump, light/heavy timing,
special/ultimate silhouettes, hit reactions, KO and both player facings. Generated
frames with clipped silhouettes/adjacent-art contamination were replaced or
isolated using texture meshes before integration. The six-frame walk replaces the
first four-step walk attempt. No original character sheet was edited.

The revised hurtbox height, strike height and body separation match the larger
rendered characters; the full combat suite remains green. Actual physical keyboard
rollover, two-human play and real speaker output still require manual testing.
Eight characters have avatars but are not yet playable. More artist-authored
in-betweens and a final likeness/animation review remain useful follow-up work.

The final v0.2 native engine + PCK bundle also booted outside the editor (exit 0),
and its X11 menu → avatars → arena → simultaneous movement/attacks → pause flow
was exercised without runtime errors. Package evidence and implementation hashes
are included in the release's `validation/` directory. The native bundle uses the
full installed Godot engine; a stripped export-template build is still untested.
