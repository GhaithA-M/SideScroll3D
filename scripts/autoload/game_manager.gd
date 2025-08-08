extends Node

# Game Manager - Main autoload for game state management
class_name GameManager

signal game_state_changed(new_state)
signal elements_changed(new_amount)
signal depth_changed(new_depth)
signal health_changed(new_health)
signal tutorial_progress_changed(step)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	BUILD_MODE
}

# Player Data
var player_data = {
	"elements": 0,
	"max_depth": 0,
	"health": 100,
	"max_health": 100,
	"upgrades": {},
	"inventory": {},
	"conveyor_belts": 0,
	"materials_mined": 0
}

# Game State
var current_state: GameState = GameState.MENU
var is_build_mode: bool = false
var tutorial_step: int = 0
var tutorial_completed: bool = false

# Game Settings
var game_settings = {
	"audio_master": 1.0,
	"audio_sfx": 1.0,
	"audio_music": 1.0,
	"graphics_quality": "medium",
	"fullscreen": false
}

# Material Types and Values
var material_types = {
	"dirt": {"value": 1, "color": Color.BROWN, "rarity": 0.8},
	"stone": {"value": 2, "color": Color.GRAY, "rarity": 0.6},
	"iron": {"value": 5, "color": Color.ORANGE, "rarity": 0.4},
	"gold": {"value": 10, "color": Color.YELLOW, "rarity": 0.2},
	"diamond": {"value": 25, "color": Color.CYAN, "rarity": 0.05},
	"fossil": {"value": 50, "color": Color.WHITE, "rarity": 0.02}
}

# Upgrade Costs
var upgrade_costs = {
	"mining_speed": [10, 25, 50, 100],
	"movement_speed": [15, 30, 60, 120],
	"health": [20, 40, 80, 160],
	"conveyor_speed": [12, 28, 55, 110],
	"belt_length": [8, 20, 45, 90]
}

func _ready():
	# Initialize game
	load_game_settings()
	load_save_data()

func change_game_state(new_state: GameState):
	current_state = new_state
	game_state_changed.emit(new_state)
	
	match new_state:
		GameState.PLAYING:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameState.PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.BUILD_MODE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_build_mode = true
		_:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_build_mode = false

func add_elements(amount: int):
	player_data.elements += amount
	elements_changed.emit(player_data.elements)
	AudioManager.play_sound("coin_collect")

func spend_elements(amount: int) -> bool:
	if player_data.elements >= amount:
		player_data.elements -= amount
		elements_changed.emit(player_data.elements)
		return true
	return false

func update_depth(depth: float):
	if depth > player_data.max_depth:
		player_data.max_depth = depth
		depth_changed.emit(depth)

func change_health(amount: int):
	player_data.health = clamp(player_data.health + amount, 0, player_data.max_health)
	health_changed.emit(player_data.health)
	
	if player_data.health <= 0:
		game_over()

func game_over():
	change_game_state(GameState.GAME_OVER)
	AudioManager.play_sound("game_over")
	SaveManager.save_game()

func restart_game():
	player_data = {
		"elements": 0,
		"max_depth": 0,
		"health": 100,
		"max_health": 100,
		"upgrades": {},
		"inventory": {},
		"conveyor_belts": 0,
		"materials_mined": 0
	}
	tutorial_step = 0
	tutorial_completed = false
	change_game_state(GameState.PLAYING)

func purchase_upgrade(upgrade_type: String) -> bool:
	if not upgrade_costs.has(upgrade_type):
		return false
	
	var current_level = player_data.upgrades.get(upgrade_type, 0)
	if current_level >= upgrade_costs[upgrade_type].size():
		return false
	
	var cost = upgrade_costs[upgrade_type][current_level]
	if spend_elements(cost):
		player_data.upgrades[upgrade_type] = current_level + 1
		AudioManager.play_sound("upgrade_purchase")
		return true
	return false

func get_upgrade_level(upgrade_type: String) -> int:
	return player_data.upgrades.get(upgrade_type, 0)

func get_upgrade_cost(upgrade_type: String) -> int:
	var current_level = get_upgrade_level(upgrade_type)
	if current_level >= upgrade_costs[upgrade_type].size():
		return -1
	return upgrade_costs[upgrade_type][current_level]

func advance_tutorial():
	tutorial_step += 1
	tutorial_progress_changed.emit(tutorial_step)
	
	if tutorial_step >= 10:  # Assuming 10 tutorial steps
		tutorial_completed = true

func load_game_settings():
	var file = FileAccess.open("user://settings.save", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			game_settings = json.data
		file.close()

func save_game_settings():
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_settings))
		file.close()

func load_save_data():
	# This will be handled by SaveManager
	pass

func _input(event):
	if event.is_action_pressed("pause") and current_state == GameState.PLAYING:
		change_game_state(GameState.PAUSED)
	elif event.is_action_pressed("pause") and current_state == GameState.PAUSED:
		change_game_state(GameState.PLAYING)
	
	if event.is_action_pressed("build_mode") and current_state == GameState.PLAYING:
		change_game_state(GameState.BUILD_MODE)
	elif event.is_action_pressed("build_mode") and current_state == GameState.BUILD_MODE:
		change_game_state(GameState.PLAYING)
