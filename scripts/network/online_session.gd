extends Node
## Direct two-device sessions. The hosting phone is authoritative; the guest can
## send only its own choice, ready/pause votes and bounded button inputs.
signal lobby_changed
signal match_started(indices: Array[int], generation: int)
signal match_finished(scores: Array[int])
signal pause_changed(paused: bool)
signal disconnected(reason: String)
var build_version := str(ProjectSettings.get_setting("application/config/version", ""))
const INPUT_KEYS := ["jump", "light", "heavy", "special", "ultimate"]
var discovery := SessionDiscovery.new()
var peer: ENetMultiplayerPeer
var phase := "idle"
var local_slot := -1
var opponent := 0
var pending_peer := 0
var code := ""
var token := ""
var last_error := ""
var selected: Array[int] = [0,1]
var ready_players: Array[bool] = [false,false]
var pause_flags: Array[bool] = [false,false]
var rematch_flags: Array[bool] = [false,false]
var epoch := 0
var latest_snapshot: Dictionary = {}
var snapshot_revision := 0
var state_provider: Callable
var input_gate: Callable
var remote_held := {"axis": 0, "block": false}
var remote_edges: Dictionary = {}
var send_sequence := 0
var received_sequence := -1
var last_snapshot_sequence := -1
var last_input_time := 0.0
var last_state_time := 0.0
var connection_started := 0.0
var closing := false
var disconnect_pending := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): fail("Connection failed. Check the session code, Wi-Fi and firewall."))
	multiplayer.server_disconnected.connect(func(): fail("The host disconnected. The session has ended."))

func active() -> bool:
	return local_slot >= 0

func host(_address := "", requested_port := 0) -> String:
	close()
	var nonce := Crypto.new().generate_random_bytes(8)
	var port := requested_port
	var result := ERR_CANT_CREATE
	for attempt in 12:
		if requested_port == 0: port = 20000 + randi_range(0,30000)
		peer = ENetMultiplayerPeer.new()
		result = peer.create_server(port, 1, 3)
		if result == OK: break
	if result != OK:
		last_error = "Cannot open a session on this device. Try again."
		peer = null
		return ""
	code = SessionCode.generate()
	token = nonce.hex_encode()
	if discovery.advertise(code,port,token) != OK:
		close()
		last_error = "Cannot create a session. Another game session may already be open on this device."
		return ""
	local_slot = 0
	phase = "hosting"
	multiplayer.multiplayer_peer = peer
	connection_started = now()
	lobby_changed.emit()
	return code

func join(invitation: String) -> bool:
	if not SessionCode.valid(invitation):
		last_error = "Invalid session code. Enter the six letters/numbers from the host."
		return false
	close()
	code = SessionCode.normalize(invitation)
	if discovery.find(code) != OK:
		last_error = "Cannot search for the session. Check your Wi-Fi connection."
		return false
	local_slot = 1
	phase = "discovering"
	connection_started = now()
	lobby_changed.emit()
	return true

func _connect_target(target: Dictionary) -> bool:
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_client(target.address, target.port, 3)
	if result != OK:
		peer = null
		fail("Cannot connect to this session. Check your Wi-Fi connection.")
		return false
	token = target.token
	phase = "connecting"
	connection_started = now()
	multiplayer.multiplayer_peer = peer
	lobby_changed.emit()
	return true

func close() -> void:
	closing = true
	discovery.stop()
	if peer: peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer = null
	phase = "idle"
	local_slot = -1
	opponent = 0
	pending_peer = 0
	code = ""
	token = ""
	last_error = ""
	selected.assign([0,1])
	ready_players.assign([false,false])
	pause_flags.assign([false,false])
	rematch_flags.assign([false,false])
	epoch = 0
	latest_snapshot.clear()
	state_provider = Callable()
	input_gate = Callable()
	clear_inputs()
	closing = false
	disconnect_pending = false

func fail(reason: String) -> void:
	if closing or disconnect_pending or not active(): return
	# Peer signals are emitted inside SceneMultiplayer.poll(). Replacing its
	# ENet peer there can invalidate the engine's current packet iterator.
	disconnect_pending = true
	phase = "disconnecting"
	_finish_disconnect.call_deferred(reason)

func _finish_disconnect(reason: String) -> void:
	close()
	last_error = reason
	disconnected.emit(reason)

func now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _process(_delta: float) -> void:
	if phase in ["hosting","discovering"]:
		var found := discovery.poll()
		if found.has("error"):
			fail(found.error)
		elif found.has("address") and phase == "discovering":
			discovery.stop()
			_connect_target(found)
	if phase == "connecting" and now() - connection_started > 12:
		fail("Connection timed out. Both devices need the same reachable network.")
	elif phase == "hosting" and pending_peer != 0 and now() - connection_started > 5:
		peer.disconnect_peer(pending_peer)
		pending_peer = 0
	elif phase in ["fight", "finished"]:
		var last := last_input_time if local_slot == 0 else last_state_time
		if last > 0 and now()-last > 8: fail("Connection lost. The match was stopped; reconnect to play again.")

func _peer_connected(id: int) -> void:
	if local_slot == 0:
		pending_peer = id
		connection_started = now()

func _connected() -> void:
	if local_slot == 1: _hello.rpc_id(1, token, SessionCode.PROTOCOL, build_version)

@rpc("any_peer", "call_remote", "reliable")
func _hello(room_token: String, protocol: int, build: String) -> void:
	if local_slot != 0 or phase != "hosting": return
	var sender := multiplayer.get_remote_sender_id()
	if sender != pending_peer or room_token != token or protocol != SessionCode.PROTOCOL or build != build_version:
		_rejected.rpc_id(sender,"Game versions differ. Install the same game version on both devices." if build != build_version or protocol != SessionCode.PROTOCOL else "This session code does not match the host. Copy a new code.")
		peer.get_host().flush()
		_reject_peer(sender)
		return
	opponent = sender
	pending_peer = 0
	phase = "lobby"
	discovery.stop()
	last_input_time = now()
	_accept.rpc_id(opponent, selected, ready_players)
	lobby_changed.emit()

func _reject_peer(id: int) -> void:
	# Let the reliable RPC acknowledgement leave before dropping the peer.
	# Dropping it inside its RPC callback makes ENet target a removed peer.
	await get_tree().create_timer(.1).timeout
	if peer and phase == "hosting" and id in multiplayer.get_peers():
		peer.disconnect_peer(id)

@rpc("authority", "call_remote", "reliable")
func _rejected(reason: String) -> void:
	if local_slot == 1 and phase == "connecting": fail(reason)

@rpc("authority", "call_remote", "reliable")
func _accept(indices: Array, flags: Array) -> void:
	if local_slot != 1 or phase != "connecting": return
	opponent = 1
	phase = "lobby"
	selected.assign(indices)
	ready_players.assign(flags)
	last_state_time = now()
	lobby_changed.emit()

func _peer_disconnected(id: int) -> void:
	if closing: return
	if id == pending_peer:
		pending_peer = 0
	elif id == opponent:
		fail("Your opponent left the session. Create or join a new session.")

func choose(index: int) -> void:
	if local_slot == 0: _choose(0, index)
	elif local_slot == 1 and phase == "lobby": _choice.rpc_id(1,index)

func ready_up(value: bool) -> void:
	if local_slot == 0: _ready_up(0,value)
	elif local_slot == 1 and phase == "lobby": _ready_vote.rpc_id(1,value)

@rpc("any_peer", "call_remote", "reliable")
func _choice(index: int) -> void:
	if local_slot == 0 and multiplayer.get_remote_sender_id() == opponent: _choose(1,index)

@rpc("any_peer", "call_remote", "reliable")
func _ready_vote(value: bool) -> void:
	if local_slot == 0 and multiplayer.get_remote_sender_id() == opponent: _ready_up(1,value)

func _choose(slot: int, index: int) -> void:
	if phase != "lobby" or ready_players[slot] or index < 0 or index >= 10: return
	selected[slot] = index
	_publish_lobby()

func _ready_up(slot: int, value: bool) -> void:
	if phase != "lobby": return
	ready_players[slot] = value
	_publish_lobby()
	if ready_players[0] and ready_players[1]: _begin_match()

func _publish_lobby() -> void:
	_lobby.rpc_id(opponent, selected, ready_players)
	lobby_changed.emit()

@rpc("authority", "call_remote", "reliable")
func _lobby(indices: Array, flags: Array) -> void:
	if local_slot != 1 or phase != "lobby": return
	selected.assign(indices)
	ready_players.assign(flags)
	lobby_changed.emit()

func _begin_match() -> void:
	epoch += 1
	phase = "fight"
	pause_flags.assign([false,false])
	rematch_flags.assign([false,false])
	clear_inputs()
	last_input_time = now()
	_start.rpc_id(opponent, selected, epoch)
	match_started.emit(selected.duplicate(), epoch)

@rpc("authority", "call_remote", "reliable")
func _start(indices: Array, generation: int) -> void:
	if local_slot != 1 or generation <= epoch or phase not in ["lobby", "finished"]: return
	selected.assign(indices)
	epoch = generation
	phase = "fight"
	pause_flags.assign([false,false])
	rematch_flags.assign([false,false])
	clear_inputs()
	last_state_time = now()
	match_started.emit(selected.duplicate(), epoch)

static func sanitize_input(data: Dictionary) -> Dictionary:
	if data.size() > 8: return {}
	var axis: Variant = data.get("axis",0)
	if typeof(axis) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(axis)): return {}
	var guard: Variant = data.get("block",false)
	var result := {"axis": clampf(float(axis),-1.0,1.0), "block": typeof(guard) == TYPE_BOOL and guard}
	for key in INPUT_KEYS:
		var value: Variant = data.get(key,false)
		result[key] = typeof(value) == TYPE_BOOL and value
	return result

func send_input(data: Dictionary) -> void:
	if local_slot != 1 or phase not in ["fight", "finished"]: return
	send_sequence += 1
	_input_packet.rpc_id(1, sanitize_input(data), send_sequence, epoch)

@rpc("any_peer", "call_remote", "reliable", 2)
func _input_packet(data: Dictionary, sequence: int, generation: int) -> void:
	if local_slot != 0 or multiplayer.get_remote_sender_id() != opponent or generation != epoch or sequence <= received_sequence or phase not in ["fight", "finished"]: return
	var clean := sanitize_input(data)
	if clean.is_empty(): return
	received_sequence = sequence
	last_input_time = now()
	if phase != "fight" or true in pause_flags or (input_gate.is_valid() and not input_gate.call()): return
	remote_held = {"axis": clean.axis, "block": clean.block}
	for key in INPUT_KEYS:
		if clean[key]: remote_edges[key] = true

func consume_remote_input() -> Dictionary:
	var result := remote_held.duplicate() if now()-last_input_time < 0.35 else {"axis":0,"block":false}
	for key in INPUT_KEYS: result[key] = remote_edges.get(key,false) if now()-last_input_time < 0.35 else false
	remote_edges.clear()
	return result

func clear_inputs() -> void:
	remote_held = {"axis":0,"block":false}
	remote_edges.clear()
	send_sequence = 0
	received_sequence = -1
	last_snapshot_sequence = -1
	snapshot_revision = 0
	latest_snapshot.clear()
	InputRouter.clear()

func send_snapshot(state: Dictionary, sequence: int) -> void:
	if local_slot == 0 and opponent != 0 and phase in ["fight", "finished"]:
		_state.rpc_id(opponent, state, sequence, epoch)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _state(state: Dictionary, sequence: int, generation: int) -> void:
	if local_slot != 1 or generation != epoch or sequence <= last_snapshot_sequence or phase not in ["fight","finished"]: return
	last_snapshot_sequence = sequence
	last_state_time = now()
	latest_snapshot = state
	snapshot_revision += 1

func request_pause(value: bool) -> void:
	if local_slot == 0: _set_pause(0,value)
	elif local_slot == 1 and phase == "fight":
		_pause_vote.rpc_id(1,value)
		peer.get_host().flush()

@rpc("any_peer", "call_remote", "reliable")
func _pause_vote(value: bool) -> void:
	if local_slot == 0 and multiplayer.get_remote_sender_id() == opponent: _set_pause(1,value)

func _set_pause(slot: int, value: bool) -> void:
	if phase != "fight": return
	pause_flags[slot] = value
	remote_held = {"axis":0,"block":false}
	remote_edges.clear()
	InputRouter.clear()
	pause_changed.emit(true in pause_flags)
	var state: Dictionary = state_provider.call() if state_provider.is_valid() else {}
	_paused.rpc_id(opponent,pause_flags,state)

@rpc("authority", "call_remote", "reliable")
func _paused(flags: Array, state: Dictionary) -> void:
	if local_slot != 1 or phase != "fight": return
	pause_flags.assign(flags)
	if not state.is_empty():
		latest_snapshot = state
		snapshot_revision += 1
		last_state_time = now()
	InputRouter.clear()
	pause_changed.emit(true in pause_flags)

func complete_match(scores: Array[int]) -> void:
	if local_slot != 0 or phase != "fight": return
	phase = "finished"
	_finish.rpc_id(opponent,scores)
	match_finished.emit(scores)

@rpc("authority", "call_remote", "reliable")
func _finish(scores: Array) -> void:
	if local_slot != 1 or phase != "fight": return
	phase = "finished"
	var result: Array[int] = []
	result.assign(scores)
	match_finished.emit(result)

func request_rematch() -> void:
	if local_slot == 0: _rematch(0)
	elif local_slot == 1 and phase == "finished": _rematch_vote.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rematch_vote() -> void:
	if local_slot == 0 and multiplayer.get_remote_sender_id() == opponent: _rematch(1)

func _rematch(slot: int) -> void:
	if phase != "finished": return
	rematch_flags[slot] = true
	if rematch_flags[0] and rematch_flags[1]: _begin_match()

func _exit_tree() -> void:
	discovery.stop()
	if peer: peer.close()
