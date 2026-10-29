extends Node
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error(label)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	check(GamePlatform.touch_enabled(),"mobile preview enables touch using the common iOS/Android platform helper")
	var nearby := SessionDiscovery.wifi_destinations(PackedStringArray(["192.168.4.17"]))
	check(nearby.size() == 253 and "192.168.4.1" in nearby and "192.168.4.254" in nearby,"iPhone discovery covers the nearby private /24")
	check("192.168.4.17" not in nearby and "192.168.4.255" not in nearby and "255.255.255.255" not in nearby,"discovery excludes its own address and all broadcast addresses")
	check(SessionDiscovery.wifi_destinations(PackedStringArray(["127.0.0.1","8.8.8.8","169.254.1.5","::1","bad"])).is_empty(),"discovery never probes public, loopback, link-local, IPv6 or invalid addresses")
	for address in ["10.0.0.11","172.16.2.9","172.31.0.44"]:
		check(SessionDiscovery.wifi_destinations(PackedStringArray([address])).size() == 253,"supports the private network containing "+address)
	check(SessionDiscovery.wifi_destinations(PackedStringArray(["172.15.1.1","172.32.1.1"])).is_empty(),"172 addresses outside RFC1918 are rejected")
	var combined := SessionDiscovery.wifi_destinations(PackedStringArray(["192.168.4.17","192.168.4.18","10.0.0.9","10.1.0.9"]))
	check(combined.size() == 505 and "10.1.0.1" not in combined,"discovery deduplicates and bounds lookup to two private /24 networks")
	var host := SessionDiscovery.new()
	var guest := SessionDiscovery.new()
	var code := SessionCode.generate()
	check(host.advertise(code,38748,"0123456789abcdef") == OK,"real UDP host opens its temporary code session")
	check(guest.find(code) == OK,"real lookup socket opens")
	var targets := PackedStringArray()
	for index in 100: targets.append("127.0.0.1")
	guest.destinations = targets
	guest.poll()
	check(guest.destination_cursor == 64,"unicast lookup sends at most 64 datagrams per batch")
	guest.retry_at = 0
	guest.poll()
	check(guest.destination_cursor == 128,"subsequent batches continue through the destination list")
	var reply := {}
	for tick in 120:
		host.poll()
		reply = guest.poll()
		if not reply.is_empty(): break
		await get_tree().process_frame
	check(reply.get("address") == "127.0.0.1" and reply.get("port") == 38748 and reply.get("token") == "0123456789abcdef","six-character lookup succeeds through actual unicast request/reply sockets")
	host.stop()
	guest.stop()
	var game := preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	check(game.touch_mode and game.touch_controls != null,"mobile route creates a real touch controller")
	game.show_select(false)
	check(game.route == "online","mobile local-versus request routes to code sessions")
	game.show_select(true)
	game.start_match()
	game.match_node.set_physics_process(false)
	game.match_node.phase = "fight"
	check(game.match_node.fighters[0].hp == 200 and game.touch_controls.sticks.size() == 1,"iPhone configuration retains 200 HP and a single player thumbstick")
	for button in game.touch_controls.buttons:
		check(button.radius > 0,"mobile combat target has a usable radius: "+button.action)
	var match_node: DuelMatch = game.match_node
	var remaining := match_node.remaining
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.route == "pause" and match_node.stopped and match_node.remaining == remaining,"background/focus loss pauses the mobile fight without consuming timer")
	game.show_menu()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.5).timeout
	print("IOS SOURCE RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
