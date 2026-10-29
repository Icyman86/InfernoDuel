class_name SessionCode
extends RefCounted
## A self-contained direct-connect invitation: protocol, IPv4, UDP port, random
## room nonce and checksum. No public directory, credentials or discovery service.
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const PREFIX := "ID6"
const PROTOCOL := 1

static func encode(address: String, port: int, nonce: PackedByteArray) -> String:
	if not address.is_valid_ip_address() or address.contains(":") or nonce.size() != 8 or port < 1 or port > 65535: return ""
	if int(address.get_slice(".",0)) == 0 or int(address.get_slice(".",0)) >= 224: return ""
	var payload := PackedByteArray([PROTOCOL])
	for part in address.split("."): payload.append(int(part))
	payload.append(port >> 8)
	payload.append(port & 255)
	payload.append_array(nonce)
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(payload)
	payload.append_array(digest.finish().slice(0,2))
	var buffer := 0
	var bits := 0
	var encoded := ""
	for byte in payload:
		buffer = (buffer << 8) | byte
		bits += 8
		while bits >= 5:
			bits -= 5
			encoded += ALPHABET[(buffer >> bits) & 31]
		buffer &= (1 << bits) - 1
	if bits > 0: encoded += ALPHABET[(buffer << (5-bits)) & 31]
	var groups := PackedStringArray()
	for i in range(0, encoded.length(), 4): groups.append(encoded.substr(i,4))
	return PREFIX + "-" + "-".join(groups)

static func decode(code: String) -> Dictionary:
	var text := code.strip_edges().to_upper().replace(" ", "").replace("\n", "").replace("-", "")
	if not text.begins_with(PREFIX): return {}
	text = text.substr(PREFIX.length()).replace("O","0").replace("I","1").replace("L","1")
	if text.length() != 28: return {}
	var buffer := 0
	var bits := 0
	var payload := PackedByteArray()
	for letter in text:
		var value := ALPHABET.find(letter)
		if value < 0: return {}
		buffer = (buffer << 5) | value
		bits += 5
		if bits >= 8:
			bits -= 8
			payload.append((buffer >> bits) & 255)
		buffer &= (1 << bits) - 1
	if payload.size() != 17 or buffer != 0 or payload[0] != PROTOCOL: return {}
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(payload.slice(0,15))
	if payload.slice(15,17) != digest.finish().slice(0,2): return {}
	var address := "%d.%d.%d.%d" % [payload[1],payload[2],payload[3],payload[4]]
	var port := (payload[5] << 8) | payload[6]
	if payload[1] == 0 or payload[1] >= 224 or port == 0: return {}
	return {"address": address, "port": port, "token": payload.slice(7,15).hex_encode()}

static func local_addresses() -> PackedStringArray:
	var result := PackedStringArray()
	# Prefer Wi-Fi over a simultaneously connected mobile/VPN adapter.
	for interface in IP.get_local_interfaces():
		var name: String = str(interface.get("name", "")).to_lower()
		if "wlan" in name or "wifi" in name or "wi-fi" in name:
			for address in interface.get("addresses",[]):
				if address.is_valid_ip_address() and not address.contains(":") and not address.begins_with("169.254."):
					if not result.has(address): result.append(address)
	for address in IP.get_local_addresses():
		if address.is_valid_ip_address() and not address.contains(":") and not address.begins_with("127.") and not address.begins_with("169.254.") and address != "0.0.0.0":
			if not result.has(address): result.append(address)
	return result
