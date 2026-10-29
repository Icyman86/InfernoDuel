class_name SessionDiscovery
extends RefCounted
## LAN room lookup. Endpoints stay internal; the player sees only six symbols.
const PORT := 38747
const MAGIC := "inferno-room-v7"
var socket: PacketPeerUDP
var room := ""
var query := ""
var requested := ""
var host_port := 0
var host_token := ""
var started := 0.0
var retry_at := 0.0
var destinations := PackedStringArray(["255.255.255.255"])
var replies: Dictionary = {}

func stop() -> void:
	if socket: socket.close()
	socket = null
	room = ""
	requested = ""
	replies.clear()

func advertise(code: String, port: int, token: String) -> Error:
	stop()
	socket = PacketPeerUDP.new()
	var error := socket.bind(PORT, "0.0.0.0", 8192)
	if error != OK:
		stop()
		return error
	room = code
	host_port = port
	host_token = token
	return OK

func find(code: String) -> Error:
	stop()
	socket = PacketPeerUDP.new()
	var error := socket.bind(0, "0.0.0.0", 8192)
	if error != OK:
		stop()
		return error
	socket.set_broadcast_enabled(true)
	requested = code
	query = Crypto.new().generate_random_bytes(8).hex_encode()
	started = Time.get_ticks_msec()/1000.0
	retry_at = 0.0
	return OK

func poll() -> Dictionary:
	if not socket: return {}
	var now := Time.get_ticks_msec()/1000.0
	if requested != "" and now >= retry_at:
		retry_at = now + .65
		var request := JSON.stringify({"app":MAGIC,"room":requested,"query":query}).to_utf8_buffer()
		for address in destinations:
			socket.set_dest_address(address,PORT)
			socket.put_packet(request)
	# Bound work per frame and ignore malformed / oversized datagrams.
	for _packet in mini(32,socket.get_available_packet_count()):
		var raw := socket.get_packet()
		var address := socket.get_packet_ip()
		var port := socket.get_packet_port()
		if raw.size() > 512: continue
		var data: Variant = JSON.parse_string(raw.get_string_from_utf8())
		if not data is Dictionary or data.get("app") != MAGIC: continue
		if room != "" and data.get("room") == room and not data.has("port"):
			var challenge: Variant = data.get("query","")
			if not challenge is String or challenge.length() != 16 or not challenge.is_valid_hex_number(false): continue
			var source := address+":"+str(port)
			if now-float(replies.get(source,-1.0)) < .5: continue
			if replies.size() > 128: replies.clear()
			replies[source] = now
			socket.set_dest_address(address,port)
			socket.put_packet(JSON.stringify({"app":MAGIC,"room":room,"query":challenge,
				"port":host_port,"token":host_token,"version":ProjectSettings.get_setting("application/config/version")}).to_utf8_buffer())
		elif requested != "" and data.get("room") == requested and data.get("query") == query:
			if data.get("version") != ProjectSettings.get_setting("application/config/version"):
				return {"error":"Install the same V7 version on both devices."}
			var target_port: Variant = data.get("port",0)
			var nonce: Variant = data.get("token","")
			if typeof(target_port) not in [TYPE_INT,TYPE_FLOAT] or target_port < 1 or target_port > 65535: continue
			if not nonce is String or nonce.length() != 16 or not nonce.is_valid_hex_number(false): continue
			return {"address":address,"port":int(target_port),"token":nonce}
	if requested != "" and now-started > 8:
		return {"error":"Session not found. Check the six-character code, use the same Wi-Fi and keep the host open. Guest Wi-Fi isolation may block discovery."}
	return {}
