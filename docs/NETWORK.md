# V16 six-character direct sessions

The device hosting the game manages a temporary room. CREATE SESSION produces
six cryptographically random characters from a 30-symbol unambiguous alphabet.
The other player enters those six symbols and taps CONNECT. No network addresses
are displayed or typed, and no external service/account is required on the same
Wi-Fi. Both devices must run the exact same app version.

## Connect and leave

1. Open CONNECT · SESSION CODE on both devices on the same Wi-Fi.
2. Host: CREATE SESSION, then share the six-character code (COPY CODE is available).
3. Guest: enter the code and CONNECT. Lowercase normalizes to uppercase.
4. Each selects/readies their own fighter. Both ready opens map choice; the host chooses the shared arena before the countdown.
5. Android uses one thumbstick and skill pad per device. Desktop connected play
   uses A/D, W, S, F/G/H/J regardless of player side. Directional variants work.
6. Either may pause; all pause requests must be released to continue. Both must
   vote for a rematch. Leaving ends the match for the other player with a message.
7. CANCEL SESSION closes a pending room/search and permits creating a fresh code.
   A fresh room gets a new code. Leaving the app/network can invalidate the room.

## How lookup works

SessionDiscovery advertises only while the host waits. Guest queries the local
IPv4 network on UDP 38747 using broadcast plus bounded unicast probes with the requested code and a random query
challenge. Only the matching host replies to the guest's ephemeral port. Its
internal endpoint and independent random room nonce establish the existing ENet
handshake. No endpoint information appears in the player UI. The host uses a
random game UDP port from 20000 through 50000. Protocol and exact version are
checked. Discovery retries and has a fourteen-second not-found timeout; subsequent
ENet connection attempts have a separate timeout. Replies echo the query nonce;
malformed/oversized packets and excessive repeats are ignored. This is a LAN
invitation, not encrypted account authentication. Protocol 4 adds per-device fighter ownership lists and compressed combat snapshots. Duplicate-code collision is
very unlikely, but there is no global directory reserving names across networks.

Guest/client isolation, VPN adapters and firewall policies can block broadcast or
direct peer traffic. Put both devices on a network permitting peer-to-peer Wi-Fi
and allow local UDP discovery/game traffic. No multicast lock is used or needed
for broadcast or ordinary unicast. Android now probes nearby private /24 addresses too, so blocked global broadcast alone does not prevent lookup. Up to two distinct private /24 prefixes are searched; isolated clients still cannot communicate. If discovery fails, check the code and leave/recreate
the room. Do not infer physical Wi-Fi success from local-process tests.

## Internet scope

A short code cannot locate a device across unrelated networks without a shared
lookup/rendezvous service. Home/carrier NAT can also block the actual connection.
V10 has no public directory, NAT traversal or relay service. It therefore targets
same-Wi-Fi play; different Wi-Fi networks / 4G / 5G are not automatically supported.
This limitation is visible in the connection UI. The user does not host an extra
server: only the game on the host device stays open for the temporary room.

## Gameplay and testing

The host simulates all movement/collisions/damage/rounds/wins at 60 Hz. Guest
controls are bounded and preserve fractional thumbstick axis. Reliable input
edges and 20 Hz state snapshots use separate ENet channels. Held inputs expire
after 350 ms without packets; an eight-second gameplay heartbeat timeout stops
lost sessions. Results/pause state are reliable; rematch epochs reject old data.
The guest smooths transforms without prediction/rollback.

python3 tools/test_network.py launches separate host, unknown-code guest and valid
guest processes. They use actual UDP broadcast discovery and direct ENet traffic,
not mocked RPCs or address injection. Tests exercise unknown-code timeout,
owned selection, countdown gate, melee/projectile damage, pause timer/votes,
matching results, mutual rematch and disconnect. Round-transition KOs are fixtures.
NETWORK_RENDERED=1 repeats with graphical peers. NETWORK_ARTIFACT_DIR retains
logs/combat screenshots without room invitations. Real Android/Wi-Fi, packet loss,
latency, carrier routers and physical two-human play remain manual acceptance.

V10 peers also synchronize resolved walk distance and locomotion speed so guest
gait follows the smoothed authoritative position. Both devices must run V10
(0.10.0); version checks reject mixed builds.

## V16 unlocks and snapshot transport

Each installation advertises its owned fighter indices at the handshake. A guest
sends an updated list with a selection after a purchase. The host checks each
slot against that device's list; a locked local fighter cannot be chosen or
readied through the ordinary UI/session API. There is no online account or
central anti-cheat server: coins and purchases are local saved progress.

The host remains authoritative for completed results. Each device pays its own
wallet once per local match ID: five for its winner, one for its loser. A rematch
creates a new ID. Quitting/disconnecting before completion does not pay.

Projectile snapshots use compact ordered records including the spawn index,
and unreliable state RPCs carry DEFLATE-compressed Variant bytes. Receive size
and decompression limits bound work. This avoids oversized unreliable packets
for the new multi-projectile moves. Pause/result RPCs stay reliable. The
three-hit escape rule can interrupt a volley following a previous hit; a clean
standalone volley still delivers its catalogue damage.

V16 tests force loopback unicast discovery, then run actual ENet host, wrong-code
and guest processes with Bamboo Blade and Sawtina and separate test wallets.
This demonstrates application behavior, not physical Android/router reachability.
