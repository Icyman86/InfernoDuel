class_name GamePlatform
extends RefCounted

static func handheld() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

static func touch_enabled() -> bool:
	return handheld() or "--touch" in OS.get_cmdline_user_args()
