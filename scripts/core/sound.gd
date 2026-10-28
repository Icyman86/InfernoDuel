extends Node
## Original synthesized placeholder sounds; no third-party audio assets.
var tones: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0

func _ready() -> void:
	for entry in [["confirm", 660.0, 0.09], ["hit", 110.0, 0.12], ["block", 260.0, 0.08], ["round", 440.0, 0.3], ["ultimate", 75.0, 0.5]]:
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		var samples := PackedByteArray()
		var count := int(entry[2] * wav.mix_rate)
		samples.resize(count * 2)
		for i in count:
			var envelope := pow(1.0 - float(i) / count, 2.0)
			var value := sin(TAU * entry[1] * i / wav.mix_rate) * envelope * 0.3
			samples.encode_s16(i * 2, int(value * 32767))
		wav.data = samples
		tones[entry[0]] = wav

	for i in 12:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)

func play(cue: String) -> void:
	if not tones.has(cue) or voices.is_empty(): return
	var player := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	player.stop()
	player.stream = tones[cue]
	player.play()

func _exit_tree() -> void:
	for player in voices:
		player.stop()
		player.stream = null
