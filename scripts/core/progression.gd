class_name PlayerProgression
extends Node
## One wallet per installation. Only completed best-of-three matches pay out.
signal changed
const MAX_COINS := 2000000000
var save_path := "user://progression.cfg"
var coins := 0
var unlocked: Array[String] = []
var rewarded: Array[String] = []
var last_error := ""
var prices: Dictionary = {}
var fighter_ids: Array[String] = []

func _ready() -> void:
	var roster: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	for fighter in roster:
		fighter_ids.append(fighter.id)
		if int(fighter.get("unlock_cost",0)) > 0: prices[fighter.id] = int(fighter.unlock_cost)
	load_progress()

func available(id: String) -> bool:
	return id in fighter_ids and (not prices.has(id) or id in unlocked)

func owned_indices() -> Array[int]:
	var result: Array[int] = []
	for i in fighter_ids.size():
		if available(fighter_ids[i]): result.append(i)
	return result

func match_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func award_match(id: String, scores: Array[int], local_slot: int) -> int:
	if id.is_empty() or id in rewarded or local_slot not in [0,1] or scores.size() != 2: return 0
	if maxi(scores[0],scores[1]) != 2 or mini(scores[0],scores[1]) < 0 or mini(scores[0],scores[1]) >= 2: return 0
	var amount := 5 if scores[local_slot] == 2 else 1
	var old_coins := coins
	var old_rewards := rewarded.duplicate()
	coins = mini(MAX_COINS,coins+amount)
	rewarded.append(id)
	if rewarded.size() > 256: rewarded.pop_front()
	if not save_progress():
		coins = old_coins
		rewarded.assign(old_rewards)
		return 0
	changed.emit()
	return amount

func purchase(id: String) -> bool:
	last_error = ""
	if not prices.has(id) or available(id): return false
	var price: int = prices[id]
	if coins < price:
		last_error = "%d / %d COINS · Win +5 · Lose +1" % [coins,price]
		return false
	coins -= price
	unlocked.append(id)
	if not save_progress():
		coins += price
		unlocked.erase(id)
		return false
	changed.emit()
	return true

func _read(path: String) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK or config.get_value("progress","version",0) != 1: return false
	var balance: Variant = config.get_value("progress","coins",-1)
	var owned: Variant = config.get_value("progress","unlocked",[])
	var history: Variant = config.get_value("progress","rewarded",[])
	if typeof(balance) != TYPE_INT or balance < 0 or balance > MAX_COINS or not owned is Array or not history is Array: return false
	coins = balance
	unlocked.clear()
	for id in owned:
		if id is String and prices.has(id) and id not in unlocked: unlocked.append(id)
	rewarded.clear()
	for id in history.slice(-256):
		if id is String: rewarded.append(id)
	return true

func load_progress() -> void:
	coins = 0
	unlocked.clear()
	rewarded.clear()
	last_error = ""
	if (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")) and not _read(save_path):
		if not _read(save_path+".bak"): last_error = "Could not read coin save. Keep this app installed and try again."

func save_progress() -> bool:
	var config := ConfigFile.new()
	config.set_value("progress","version",1)
	config.set_value("progress","coins",coins)
	config.set_value("progress","unlocked",unlocked)
	config.set_value("progress","rewarded",rewarded)
	var path := ProjectSettings.globalize_path(save_path)
	if config.save(save_path+".tmp") != OK:
		last_error = "Could not save coins. Free storage space and try again."
		return false
	var had_save := FileAccess.file_exists(save_path)
	if had_save and DirAccess.rename_absolute(path,path+".bak") != OK:
		last_error = "Could not update coin save. Try again."
		return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK:
		if had_save: DirAccess.rename_absolute(path+".bak",path)
		last_error = "Could not update coin save. Try again."
		return false
	last_error = ""
	return true
