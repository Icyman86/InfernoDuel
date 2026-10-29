class_name ActionPoseFields
extends RefCounted
## Whole attacks, including anticipation and return, with a fixed support foot.
static var data: Dictionary = {}
static var textures: Dictionary = {}

static func available(id: String, animation: String) -> bool:
	if data.is_empty(): data = JSON.parse_string(FileAccess.get_file_as_string("res://data/action_motion_fields.json"))
	return data.profiles.has(id) and data.profiles[id].clips.has(animation)

static func texture(id: String, pair: String) -> Texture2D:
	var key := id+"/"+pair
	if not textures.has(key):
		var packed := Marshalls.base64_to_raw(data.profiles[id].fields[pair])
		var bytes := packed.decompress(int(data.grid[0])*int(data.grid[1])*4,FileAccess.COMPRESSION_DEFLATE)
		var image := Image.create_from_data(int(data.grid[0]),int(data.grid[1]),false,Image.FORMAT_RGBA8,bytes)
		textures[key] = ImageTexture.create_from_image(image)
	return textures[key]

static func prime(id: String) -> void:
	if not available(id,"heavy"): return
	for pair in data.profiles[id].fields: texture(id,pair)

static func sample(id: String, animation: String, progress: float) -> Dictionary:
	var clip: Dictionary = data.profiles[id].clips[animation]
	var phase := clampf(progress,0,.99999)
	for i in range(1,clip.times.size()):
		if phase <= float(clip.times[i]):
			return {"base":clip["keys"][i-1],"next":clip["keys"][i],"pair":clip.pairs[i-1],
				"mix":smoothstep(float(clip.times[i-1]),float(clip.times[i]),phase),
				"offset":Vector2(clip.root_offset[0],clip.root_offset[1])}
	return {}
