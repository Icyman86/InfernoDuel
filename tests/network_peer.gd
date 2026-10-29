extends Node
## Launched in separate OS processes by test_network.py: real ENet traffic,
## ordinary lobby ownership, real input/damage, pause, results and rematch.
var role := ""
var directory := ""
var game: Control
var elapsed := 0.0
var fight_started := -1.0
var paused_at := -1.0
var timer_at_pause := 0.0
var resumed := false
var flags: Dictionary = {}
var passed := 0
var failed := 0

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/"+role+"-"+name+".png")

func check(ok: bool, text: String) -> void:
	if ok:
		passed += 1
		print("PASS ",role," ",text)
	else:
		failed += 1
		push_error(role+" "+text)

func once(key: String) -> bool:
	if flags.has(key): return false
	flags[key] = true
	return true

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="): role = arg.get_slice("=",1)
		if arg.begins_with("--directory="): directory = arg.get_slice("=",1)
	call_deferred("run")

func run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	game.show_online()
	if role == "host":
		var code := OnlineSession.host()
		check(code != "","real UDP host opens and produces a session code")
		var file := FileAccess.open(directory+"/code.txt",FileAccess.WRITE)
		file.store_string(code)
		file.close()
	elif role in ["guest","bad"]:
		var code := FileAccess.get_file_as_string(directory+"/code.txt")
		if role == "bad":
			code = ("2" if code[0] != "2" else "3")+code.substr(1)
		check(OnlineSession.join(code),"real client starts a session-code connection")
	set_process(true)

func _process(delta: float) -> void:
	if not game: return
	elapsed += delta
	if elapsed > 42:
		check(false,"network lifecycle completed before timeout; phase="+OnlineSession.phase+" route="+game.route)
		finish()
		return
	if role == "bad":
		if not OnlineSession.active() and elapsed > .5:
			check(game.route == "online" and OnlineSession.last_error != "","unknown six-character code times out without a match")
			finish()
		return
	if OnlineSession.phase == "lobby" and once("ready"):
		check(game.route == "network_select" and game.screen.online_slot == (0 if role == "host" else 1),"connection enters owned fighter selection")
		OnlineSession.choose(0 if role == "host" else 3)
		# These ordered RPCs use the normal selection and ready protocol.
		OnlineSession.ready_up(true)
	if is_instance_valid(game.match_node) and OnlineSession.epoch == 1:
		var duel: DuelMatch = game.match_node
		if duel.phase == "countdown":
			if role == "guest":
				InputRouter.held[0].move_left = true
				InputRouter.pressed[0].light = true
			elif duel.phase_time < 1.5 and once("countdown"):
				check(duel.fighters[1].position.x == 890 and duel.fighters[0].hp == 100,"guest input cannot move or attack during the host countdown")
		if duel.phase == "fight" and fight_started < 0:
			fight_started = elapsed
			check(game.networked and not duel.solo,"session starts a genuine two-device fight without CPU")
		if fight_started >= 0:
			var t := elapsed - fight_started
			if role == "guest":
				if t < 1.3: InputRouter.held[0].move_left = true
				elif once("stop_walk"): InputRouter.held[0].move_left = false
				if t >= 1.55 and once("light"): InputRouter.pressed[0].light = true
				if t >= 2.3 and once("special"): InputRouter.pressed[0].special = true
				if t >= 4.0 and once("pause"): OnlineSession.request_pause(true)
			else:
				if t >= 3.2 and once("heavy"): InputRouter.pressed[0].heavy = true
				if t >= 3.9 and once("damage"):
					check(duel.fighters[0].hp == 78,"guest movement, light and projectile damage reach authoritative host")
					check(duel.fighters[1].hp == 88,"host attack applies authoritative guest damage")
					capture("fight")
			if true in OnlineSession.pause_flags:
				if paused_at < 0:
					paused_at = elapsed
					timer_at_pause = duel.remaining
					check(game.route == "pause" and duel.stopped,"pause propagates to both gameplay and UI")
					capture("pause")
				if elapsed-paused_at > .25 and once("timer"):
					check(absf(duel.remaining-timer_at_pause) < .08,"network pause freezes the authoritative timer")
					if role == "host": OnlineSession.request_pause(true)
				if role == "guest" and elapsed-paused_at > .7 and once("guest_resume"):
					OnlineSession.request_pause(false)
				if role == "host" and elapsed-paused_at > 1.0 and once("host_resume"):
					check(OnlineSession.pause_flags == [true,false] and duel.stopped,"one resume vote cannot override the other player's pause")
					OnlineSession.request_pause(false)
			elif paused_at >= 0 and not resumed:
				resumed = true
				check(game.route == "fight" and not duel.stopped,"both resume votes restart the shared fight")
				if role == "guest": check(duel.fighters[0].hp == 78 and duel.fighters[1].hp == 88,"guest renders the host's exact health state")
			if role == "host" and resumed and t > 6 and duel.phase == "fight":
				# Two normal round transitions; only the test fixture sets final KO HP.
				if once("ko_"+str(duel.round_number)):
					duel.fighters[1].hp = 0
	if OnlineSession.phase == "finished" and once("rematch"):
		check(game.route == "result" and game.match_node.wins == [2,0],"host and guest agree on the best-of-three result")
		OnlineSession.request_rematch()
	if OnlineSession.epoch == 2 and once("epoch2"):
		check(game.route == "fight" and game.match_node.phase == "countdown" and game.match_node.fighters[0].hp == 100,"mutual rematch starts a fresh synchronized match generation")
		if role == "host":
			await get_tree().create_timer(.7).timeout
			game.show_menu()
			check(not OnlineSession.active(),"leaving closes the host session")
			finish()
	if role == "guest" and flags.has("epoch2") and not OnlineSession.active():
		check(game.route == "online" and OnlineSession.last_error != "","host disconnect stops the guest match and shows a recoverable connection screen")
		finish()

func finish() -> void:
	set_process(false)
	OnlineSession.close()
	game.show_menu()
	var result := {"role":role,"passed":passed,"failed":failed}
	var file := FileAccess.open(directory+"/"+role+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("NETWORK PEER RESULT: ",JSON.stringify(result))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.6).timeout
	get_tree().quit(0 if failed == 0 else 1)
