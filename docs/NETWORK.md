# V7 six-character direct sessions

The device hosting the game manages a temporary room. CREATE SESSION produces
six cryptographically random characters from a 30-symbol unambiguous alphabet.
The other player enters those six symbols and taps CONNECT. No network addresses
are displayed or typed, and no external service/account is required on the same
Wi-Fi. Both devices must run the exact same app version.

## Connect and leave

1. Open CONNECT · SESSION CODE on both devices on the same Wi-Fi.
2. Host: CREATE SESSION, then share the six-character code (COPY CODE is available).
3. Guest: enter the code and CONNECT. Lowercase normalizes to uppercase.
4. Each selects/readies their own fighter. Both ready starts the fight.
5. Android uses one thumbstick and skill pad per device. Desktop connected play
   uses A/D, W, S, F/G/H/J regardless of player side. Directional variants work.
6. Either may pause; all pause requests must be released to continue. Both must
   vote for a rematch. Leaving ends the match for the other player with a message.
7. CANCEL SESSION closes a pending room/search and permits creating a fresh code.
   A fresh room gets a new code. Leaving the app/network can invalidate the room.

## How lookup works

SessionDiscovery advertises only while the host waits. Guest queries the local
IPv4 broadcast domain on UDP 38747 with the requested code and a random query
challenge. Only the matching host replies to the guest's ephemeral port. Its
internal endpoint and independent random room nonce establish the existing ENet
handshake. No endpoint information appears in the player UI. The host uses a
random game UDP port from 20000 through 50000. Protocol and exact version are
checked. Discovery retries and has an eight-second not-found timeout; subsequent
ENet connection attempts have a separate timeout. Replies echo the query nonce;
malformed/oversized packets and excessive repeats are ignored. This is a LAN
invitation, not encrypted account authentication. Duplicate-code collision is
very unlikely, but there is no global directory reserving names across networks.

Guest/client isolation, VPN adapters and firewall policies can block broadcast or
direct peer traffic. Put both devices on a network permitting peer-to-peer Wi-Fi
and allow local UDP discovery/game traffic. No multicast lock is used or needed
for the broadcast protocol. If discovery fails, check the code and leave/recreate
the room. Do not infer physical Wi-Fi success from local-process tests.

## Internet scope

A short code cannot locate a device across unrelated networks without a shared
lookup/rendezvous service. Home/carrier NAT can also block the actual connection.
V7 has no public directory, NAT traversal or relay service. It therefore targets
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
