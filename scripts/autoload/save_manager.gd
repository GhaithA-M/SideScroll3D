extends Node

# Save Manager - Handles game save/load functionality
class_name SaveManager

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".save"
const MAX_SAVE_SLOTS = 3

# Save data structure
var save_data_template = {
	"version": "1.0.0",
	"timestamp": 0,
	"player_data": {},
	"game_progress": {},
	"settings": {}
}

func _ready():
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		save_failed.emit(slot, "Invalid save slot")
		return false
	
	var save_data = save_data_template.duplicate(true)
	save_data.timestamp = Time.get_unix_time_from_system()
	save_data.player_data = GameManager.player_data.duplicate(true)
	save_data.game_progress = {
		"tutorial_step": GameManager.tutorial_step,
		"tutorial_completed": GameManager.tutorial_completed,
		"current_state": GameManager.current_state
	}
	save_data.settings = GameManager.game_settings.duplicate(true)
	
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		save_failed.emit(slot, "Could not create save file")
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	save_completed.emit(slot)
	return true

func load_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		load_failed.emit(slot, "Invalid save slot")
		return false
	
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(file_path):
		load_failed.emit(slot, "Save file does not exist")
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		load_failed.emit(slot, "Could not open save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		load_failed.emit(slot, "Invalid save file format")
		return false
	
	var save_data = json.data
	
	# Validate save data
	if not save_data.has("version") or not save_data.has("player_data"):
		load_failed.emit(slot, "Save file is corrupted")
		return false
	
	# Load player data
	GameManager.player_data = save_data.player_data.duplicate(true)
	
	# Load game progress
	if save_data.has("game_progress"):
		GameManager.tutorial_step = save_data.game_progress.get("tutorial_step", 0)
		GameManager.tutorial_completed = save_data.game_progress.get("tutorial_completed", false)
		if save_data.game_progress.has("current_state"):
			GameManager.current_state = save_data.game_progress.current_state
	
	# Load settings
	if save_data.has("settings"):
		GameManager.game_settings = save_data.settings.duplicate(true)
	
	load_completed.emit(slot)
	return true

func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		return true
	
	return false

func save_exists(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	return FileAccess.file_exists(file_path)

func get_save_info(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {}
	
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	
	return {
		"timestamp": save_data.get("timestamp", 0),
		"version": save_data.get("version", "Unknown"),
		"elements": save_data.get("player_data", {}).get("elements", 0),
		"max_depth": save_data.get("player_data", {}).get("max_depth", 0),
		"materials_mined": save_data.get("player_data", {}).get("materials_mined", 0)
	}

func get_all_save_info() -> Array:
	var save_info = []
	
	for slot in range(MAX_SAVE_SLOTS):
		var info = get_save_info(slot)
		if info.is_empty():
			save_info.append({
				"slot": slot,
				"exists": false,
				"timestamp": 0,
				"version": "",
				"elements": 0,
				"max_depth": 0,
				"materials_mined": 0
			})
		else:
			info["slot"] = slot
			info["exists"] = true
			save_info.append(info)
	
	return save_info

func format_timestamp(timestamp: int) -> String:
	var date = Time.get_datetime_string_from_unix_time(timestamp)
	return date

func auto_save():
	# Auto-save to slot 0
	save_game(0)

func quick_save():
	# Quick save to slot 1
	save_game(1)

func quick_load():
	# Quick load from slot 1
	if save_exists(1):
		load_game(1)
	else:
		# If no quick save exists, load from slot 0
		if save_exists(0):
			load_game(0)
