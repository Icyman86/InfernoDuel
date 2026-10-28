class_name FighterPortrait
extends TextureRect
## A view into the original sheet, never a modified source image.
func setup(profile: Dictionary) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://" + profile.reference_art_path)
	var r: Array = profile.portrait_region
	atlas.region = Rect2(r[0],r[1],r[2],r[3])
	atlas.filter_clip = true
	texture = atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
