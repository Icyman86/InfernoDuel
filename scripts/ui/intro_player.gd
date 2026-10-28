class_name FighterIntroPlayer
extends Control
signal back_requested
var profile: Dictionary = {}
var video: VideoStreamPlayer
var status: Label

func _ready() -> void:
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	add_child(UI.place(bg,0,0,1280,720))
	video = VideoStreamPlayer.new()
	video.expand = true
	video.bus = "SFX"
	video.stream = load("res://"+profile.intro.video_path)
	add_child(UI.place(video,0,0,1280,720))
	video.finished.connect(func(): status.text = profile.display_name.to_upper()+" · INTRO COMPLETE")
	status = UI.label("",16,UI.MUTED)
	add_child(UI.place(status,250,675,780,32))
	var back := UI.button("BACK",func(): back_requested.emit())
	add_child(UI.place(back,28,674,180,38))
	add_child(UI.place(UI.button("REPLAY",replay,true),1072,674,180,38))
	back.grab_focus()
	video.play()

func replay() -> void:
	video.stop()
	status.text = ""
	video.play()

func _exit_tree() -> void:
	if video: video.stop()
