extends Node

# Game Manager - Main autoload for game state management

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
	"elements": 64,  # Start with some elements like Dig n Rig
	"max_depth": 0,
	"health": 100,
	"max_health": 100,
	"upgrades": {},
	"inventory": {},
	"conveyor_belts": 0,
	"materials_mined": 0,
	"selected_tool": 0,  # Currently selected dig tool
	"vac_pak_capacity": 100
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

# Dig n Rig style material types and values
var material_types = {
	"grass": {"value": 0, "color": Color(0.2, 0.8, 0.2), "rarity": 1.0},      # Green surface
	"dirt": {"value": 1, "color": Color(0.6, 0.4, 0.2), "rarity": 0.8},       # Brown dirt
	"stone": {"value": 2, "color": Color(0.5, 0.5, 0.5), "rarity": 0.6},      # Gray stone
	"iron": {"value": 5, "color": Color(0.8, 0.5, 0.2), "rarity": 0.4},       # Orange iron
	"gold": {"value": 10, "color": Color(1.0, 0.8, 0.0), "rarity": 0.2},      # Bright yellow gold
	"diamond": {"value": 25, "color": Color(0.4, 0.8, 1.0), "rarity": 0.05},  # Light blue diamond
	"fossil": {"value": 50, "color": Color(0.9, 0.9, 0.9), "rarity": 0.02}    # Off-white fossil
=======
# Material Types and Values (Authentic Dig-N-Rig style)
var material_types = {
	# Surface materials
	"grass": {"value": 1, "color": Color(0.2, 0.6, 0.2), "rarity": 0.95, "layer": 0, "description": "Surface vegetation"},
	"dirt": {"value": 2, "color": Color(0.55, 0.35, 0.15), "rarity": 0.9, "layer": 0, "description": "Common earth"},
	
	# Shallow materials
	"clay": {"value": 3, "color": Color(0.7, 0.5, 0.3), "rarity": 0.7, "layer": 1, "description": "Moldable clay deposits"},
	"stone": {"value": 4, "color": Color(0.45, 0.45, 0.45), "rarity": 0.8, "layer": 1, "description": "Basic stone"},
	"limestone": {"value": 5, "color": Color(0.8, 0.8, 0.7), "rarity": 0.6, "layer": 1, "description": "Sedimentary rock"},
	
	# Medium depth materials  
	"iron": {"value": 12, "color": Color(0.55, 0.5, 0.45), "rarity": 0.4, "layer": 2, "description": "Iron ore deposits"},
	"copper": {"value": 10, "color": Color(0.7, 0.45, 0.2), "rarity": 0.5, "layer": 2, "description": "Copper veins"},
	"coal": {"value": 8, "color": Color(0.2, 0.2, 0.2), "rarity": 0.6, "layer": 2, "description": "Fossil fuel"},
	
	# Deep precious materials
	"silver": {"value": 25, "color": Color(0.8, 0.8, 0.9), "rarity": 0.2, "layer": 3, "description": "Precious silver"},
	"gold": {"value": 40, "color": Color(1.0, 0.84, 0.0), "rarity": 0.15, "layer": 3, "description": "Pure gold veins"},
	"platinum": {"value": 60, "color": Color(0.9, 0.9, 0.95), "rarity": 0.1, "layer": 3, "description": "Rare platinum"},
	
	# Ultra deep materials
	"diamond": {"value": 100, "color": Color(0.7, 0.9, 1.0), "rarity": 0.05, "layer": 4, "description": "Precious diamonds"},
	"emerald": {"value": 120, "color": Color(0.2, 0.8, 0.4), "rarity": 0.03, "layer": 4, "description": "Rare emeralds"},
	"ruby": {"value": 110, "color": Color(0.9, 0.2, 0.3), "rarity": 0.04, "layer": 4, "description": "Blood red rubies"},
	
	# Core materials (ultra rare)
	"fossil": {"value": 200, "color": Color(0.6, 0.4, 0.8), "rarity": 0.01, "layer": 5, "description": "Ancient fossils"},
	"meteorite": {"value": 300, "color": Color(0.3, 0.3, 0.4), "rarity": 0.005, "layer": 5, "description": "Alien meteorite"},
	"crystal": {"value": 500, "color": Color(1.0, 0.8, 1.0), "rarity": 0.002, "layer": 5, "description": "Energy crystals"}
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

func get_materials_for_layer(layer: int) -> Array:
	var layer_materials = []
	for material_name in material_types.keys():
		var material_data = material_types[material_name]
		if material_data.get("layer", 0) == layer:
			layer_materials.append(material_name)
	return layer_materials

func get_material_layer(material_name: String) -> int:
	return material_types.get(material_name, {}).get("layer", 0)

func get_material_description(material_name: String) -> String:
	return material_types.get(material_name, {}).get("description", "Unknown material")

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
