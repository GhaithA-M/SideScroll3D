extends Node3D

# Main Game - Coordinates all game systems
class_name MainGame

# Game Systems
@onready var player: PlayerController = $Player
@onready var terrain_system: TerrainSystem = $TerrainSystem
@onready var conveyor_system: ConveyorSystem = $ConveyorSystem
@onready var enemy_manager: Node3D = $EnemyManager
@onready var base: Node3D = $Base
@onready var ui: GameUI = $UI
@onready var side_scroll_camera: Camera3D = $SideScrollCamera

# Game State
var is_game_initialized: bool = false
var auto_save_timer: float = 0.0
var auto_save_interval: float = 60.0  # Save every minute

func _ready():
	# Initialize game systems
	initialize_game()
	
	# Connect signals
	connect_game_signals()
	
	# Start game
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	AudioManager.play_music("main_theme")

func initialize_game():
	# Initialize terrain
	terrain_system.terrain_destroyed.connect(_on_terrain_destroyed)
	
	# Initialize conveyor system
	conveyor_system.belt_placed.connect(_on_belt_placed)
	conveyor_system.material_transported.connect(_on_material_transported)
	
	# Initialize player
	player.mining_completed.connect(_on_mining_completed)
	player.health_changed.connect(_on_player_health_changed)
	player.depth_changed.connect(_on_player_depth_changed)
	
	# Initialize base processing
	setup_base_processing()
	
	is_game_initialized = true

func connect_game_signals():
	# Connect to game manager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
	# Connect to UI signals
	ui.menu_opened.connect(_on_menu_opened)

func setup_base_processing():
	# Create base processing area
	var base_area = Area3D.new()
	var base_shape = SphereShape3D.new()
	base_shape.radius = 3.0
	var base_collision = CollisionShape3D.new()
	base_collision.shape = base_shape
	base_area.add_child(base_collision)
	base.add_child(base_area)
	
	# Connect base area signals
	base_area.body_entered.connect(_on_base_body_entered)

func _process(delta):
	if not is_game_initialized:
		return
	
	# Auto save
	auto_save_timer += delta
	if auto_save_timer >= auto_save_interval:
		SaveManager.auto_save()
		auto_save_timer = 0.0

func _on_terrain_destroyed(position: Vector3, material_type: String):
	# Handle terrain destruction
	AudioManager.play_sound("dig")
	
	# Spawn material drop
	spawn_material_drop(position, material_type)

func _on_mining_completed(position: Vector3, material_type: String):
	# Handle mining completion
	GameManager.player_data.materials_mined += 1
	
	# Add elements based on material value
	var material_value = GameManager.material_types.get(material_type, {}).get("value", 1)
	GameManager.add_elements(material_value)

func _on_belt_placed(position: Vector3, belt_type: String):
	# Handle belt placement
	GameManager.player_data.conveyor_belts += 1
	AudioManager.play_sound("conveyor_place")

func _on_material_transported(material: Node3D, from_pos: Vector3, to_pos: Vector3):
	# Handle material transport
	AudioManager.play_sound("conveyor_operate")

func _on_base_body_entered(body: Node3D):
	# Handle materials reaching base
	if body.has_method("get_material_type"):
		var material_type = body.get_material_type()
		var material_value = body.get_value()
		
		# Process material
		GameManager.add_elements(material_value)
		AudioManager.play_sound("base_process")
		
		# Remove material
		body.queue_free()

func _on_player_health_changed(new_health: int):
	# Handle player health changes
	if new_health <= 0:
		GameManager.game_over()

func _on_player_depth_changed(new_depth: float):
	# Handle depth changes
	GameManager.update_depth(new_depth)
	
	# Spawn enemies at deeper levels
	if new_depth > 20 and enemy_manager.has_method("spawn_enemy"):
		enemy_manager.spawn_enemy(Vector3(randf_range(-10, 10), -new_depth, randf_range(-10, 10)))

func _on_game_state_changed(new_state: GameManager.GameState):
	match new_state:
		GameManager.GameState.PLAYING:
			# Resume game
			get_tree().paused = false
			AudioManager.play_music("main_theme")
		GameManager.GameState.PAUSED:
			# Pause game
			get_tree().paused = true
		GameManager.GameState.GAME_OVER:
			# Game over
			get_tree().paused = true
			AudioManager.play_music("danger_theme")
		GameManager.GameState.BUILD_MODE:
			# Enter build mode
			player.set_build_mode(true)
			conveyor_system.start_placement(ConveyorSystem.BeltType.STRAIGHT)

func _on_menu_opened(menu_name: String):
	match menu_name:
		"upgrade":
			# Show upgrade menu
			pass
		"build":
			# Enter build mode
			pass

func spawn_material_drop(position: Vector3, material_type: String):
	# Create material drop
	var material_scene = preload("res://scenes/materials/material_drop.tscn")
	var material_instance = material_scene.instantiate()
	material_instance.material_type = material_type
	material_instance.global_position = position
	add_child(material_instance)
	
	# Connect material signals
	material_instance.collected.connect(_on_material_collected)

func _on_material_collected(material_type: String, value: int):
	# Handle material collection
	AudioManager.play_sound("coin_collect")

func save_game():
	SaveManager.save_game()

func load_game():
	SaveManager.load_game()

func restart_game():
	# Reset all systems
	GameManager.restart_game()
	
	# Clear terrain
	for child in terrain_system.get_children():
		child.queue_free()
	
	# Clear conveyor system
	for child in conveyor_system.get_children():
		child.queue_free()
	
	# Clear enemies
	for child in enemy_manager.get_children():
		child.queue_free()
	
	# Reset player position
	player.global_position = Vector3(0, 5, 0)
	
	# Regenerate terrain
	terrain_system.generate_initial_terrain()
	
	# Resume game
	GameManager.change_game_state(GameManager.GameState.PLAYING)

func _input(event):
	if event.is_action_pressed("build_mode"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.change_game_state(GameManager.GameState.BUILD_MODE)
		elif GameManager.current_state == GameManager.GameState.BUILD_MODE:
			GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	if event.is_action_pressed("interact") and GameManager.current_state == GameManager.GameState.BUILD_MODE:
		# Place belt at mouse position
		var camera = get_viewport().get_camera_3d()
		var mouse_pos = get_viewport().get_mouse_position()
		
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 2  # Terrain layer
		
		var result = space_state.intersect_ray(query)
		
		if result:
			conveyor_system.place_belt(result.position, ConveyorSystem.BeltType.STRAIGHT)
