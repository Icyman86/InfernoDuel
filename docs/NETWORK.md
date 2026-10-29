# V6 direct sessions

V6 connects two devices using a self-contained session code. It is a direct IPv4
UDP connection, intended for the same Wi-Fi / reachable network. No account,
public matchmaking directory, relay, automatic NAT traversal or Internet hosting
is included. Both devices must run the exact same application version.

## Connect

1. Put both devices on the same Wi-Fi and open CONNECT · SESSION CODE.
2. Host: select the Wi-Fi IPv4 address and tap CREATE SESSION. COPY CODE copies
   the complete ID6 invitation. Share it privately with the other player.
3. Guest: paste the complete code, then CONNECT. The invitation contains the host
   endpoint and room nonce. It is longer than a directory-backed short room ID.
4. Each player chooses their own fighter and taps their own READY. Both ready
   starts the arena. Each device controls one player; on desktop connected play
   uses A/D, W, S, F/G/H/J regardless of the assigned player side.
5. Either can pause. Each resume button releases that player's pause request;
   play continues when no player requests pause. Rematch needs both votes.
6. BACK / MAIN MENU leaves the session. The other device returns to connection
   with a reason, rather than continuing against a vanished player.

## Connection problems

Choose the Wi-Fi address, rather than a mobile/VPN/virtual adapter address.
The host chooses a random UDP port between 20000 and 50000; it is embedded in
the code. Permit that host port in the device/network firewall if applicable.
Router guest/client isolation can prevent devices on the same SSID from reaching
each other. Disable that isolation or use a network allowing peer-to-peer traffic.
Keep both apps open. A bad/expired code, version mismatch or timeout gives an
error; return and create a fresh invitation after changing networks.

Different Wi-Fi networks, mobile carriers and carrier-grade NAT generally prevent
direct inbound access. The code does not make a private address public. V6 does
not deploy a relay; public Internet sessions require a separately designed and
hosted relay/NAT-traversal service or an already routed network/VPN between peers.
The UI makes this limitation visible. Direct invitation transport is not encrypted;
the nonce restricts joining to invitation holders, and is not an account identity.

## Implementation and validation

The host is authoritative for movement, collisions, damage, time, rounds and wins.
The guest sends only bounded controls for its own player. Reliable input edges
and 20 Hz state snapshots use separate ENet channels. Snapshots are smoothed on
the guest; no rollback or latency compensation is claimed. Guest held inputs
expire after 350 ms without fresh packets, and an eight-second gameplay heartbeat
timeout stops a lost match. Epochs reject packets from a previous rematch.

Run python3 tools/test_network.py for three separate Godot processes over real
loopback UDP. Set NETWORK_RENDERED=1 for graphical peers (DISPLAY required), and
NETWORK_ARTIFACT_DIR to retain logs and combat/pause screenshots. Invitations
remain temporary and are not copied to validation artifacts. The test exercises
wrong-nonce rejection/recovery, owned selection, both-ready start, countdown input
lock, remote move/melee/projectile damage, host damage, shared pause votes and
frozen timer, matching round/result state, mutual rematch and clean host disconnect.
Round-transition fixtures set low HP for deterministic KOs; this is not a human
full-match or a physical Wi-Fi/Android acceptance claim.
