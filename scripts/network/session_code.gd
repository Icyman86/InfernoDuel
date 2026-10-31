class_name SessionCode
extends RefCounted
## Six random, human-readable symbols. Room lookup is separate from transport.
const ALPHABET := "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
const PROTOCOL := 4

static func generate() -> String:
	var result := ""
	# Rejection sampling avoids modulo bias with this 30-symbol alphabet.
	while result.length() < 6:
		for byte in Crypto.new().generate_random_bytes(12):
			if byte < (256 / ALPHABET.length()) * ALPHABET.length():
				result += ALPHABET[byte % ALPHABET.length()]
				if result.length() == 6: break
	return result

static func normalize(code: String) -> String:
	return code.strip_edges().to_upper().replace(" ","").replace("-","")

static func valid(code: String) -> bool:
	var text := normalize(code)
	if text.length() != 6: return false
	for symbol in text:
		if not symbol in ALPHABET: return false
	return true
