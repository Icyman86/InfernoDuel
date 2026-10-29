extends Node
## Rendered native-size workload; software-host measurements are not phone results.
var game: Control
var duel: DuelMatch
var elapsed := 0.0
var started_at := 0
var previous_at := 0
var engine_samples: Array[float] = []
var samples: Array[float] = []
var cpu: Array[float] = []
var geometry_start := 0
var baseline := false
var size := Vector2i(1280,720)
var views: Array = []

func _ready() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var pair := arg.trim_prefix("--size=").split("x")
			size = Vector2i(int(pair[0]),int(pair[1]))
	started_at = Time.get_ticks_usec()
	previous_at = started_at
	Engine.max_fps = 60
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	get_window().size = size
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.announcement.text = ""
	for f in duel.fighters:
		if baseline:
			f.visual.visible = false
			f.visual.set_process(false)
			var old: Node2D = load("res://builds/v8-benchmark/baseline_visual.gd").new()
			old.profile = f.profile
			old.actor = f
			old.accent = f.tint
			f.add_child(old)
			views.append(old)
		else: views.append(f.visual)

func percentile(values: Array[float], p: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size()-1,int((sorted.size()-1)*p))]

func _physics_process(delta: float) -> void:
	if not duel: return
	var direction := 1 if fmod(elapsed,1.6) < .8 else -1
	var commands: Array[Dictionary] = [{"axis":direction},{"axis":direction}]
	duel.advance_fight(delta,commands)

func _process(delta: float) -> void:
	if not duel: return
	var now := Time.get_ticks_usec()
	var actual_ms := (now-previous_at)/1000.0
	previous_at = now
	elapsed = (now-started_at)/1000000.0
	if elapsed > 2 and elapsed < 8:
		samples.append(actual_ms)
		engine_samples.append(delta*1000)
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	if elapsed >= 8:
		var result := {"baseline":baseline,"size":[size.x,size.y],"frames":samples.size(),
			"average_actual_fps":1000.0/(samples.reduce(func(a,b):return a+b,0.0)/samples.size()),
			"median_engine_delta_ms":percentile(engine_samples,.5),"median_frame_ms":percentile(samples,.5),"p95_frame_ms":percentile(samples,.95),
			"p99_frame_ms":percentile(samples,.99),"median_cpu_process_ms":percentile(cpu,.5),
			"p95_cpu_process_ms":percentile(cpu,.95),
			"target_fps":60,"renderer":RenderingServer.get_video_adapter_name(),
			"scope":"Linux X11 software-rendered scripted movement; not physical Android acceptance"}
		if not baseline:
			result["cached_geometry_builds"] = int(views[0].geometry_builds)+int(views[1].geometry_builds)
		var output := "/tmp/inferno-v8-"+("baseline" if baseline else "current")+"-%dx%d.json" % [size.x,size.y]
		var file := FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"  ")+"\n")
		print("MOTION BENCHMARK: ",JSON.stringify(result))
		set_process(false)
		set_physics_process(false)
		game.show_menu()
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(.6).timeout
		get_tree().quit()
