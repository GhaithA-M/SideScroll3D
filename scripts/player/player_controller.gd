extends CharacterBody3D

# Player Controller - Diggit 6400 Mining Robot
class_name PlayerController

signal mining_started(position: Vector3)
signal mining_completed(position: Vector3, material_type: String)
signal health_changed(new_health: int)
signal depth_changed(new_depth: float)

# Movement
@export var move_speed: float = 8.0
@export var jump_force: float = 12.0
@export var gravity: float = 20.0

# Mining
@export var mining_range: float = 2.0
@export var mining_speed: float = 1.0
@export var auto_mining: bool = true

# Health and Stats
@export var max_health: int = 100
var current_health: int
var is_invulnerable: bool = false
var invulnerability_time: float = 1.0

# Components
@onready var mining_area: Area3D = $MiningArea
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# Mining State
var is_mining: bool = false
var current_mining_target: Node3D = null
var mining_timer: float = 0.0
var mining_cooldown: float = 0.5

# Visual Effects
@onready var mining_particles: GPUParticles3D = $MiningParticles
@onready var damage_particles: GPUParticles3D = $DamageParticles

# Input - Side-scrolling 2.5D style
var input_vector: Vector2  # Only X/Y movement for side-scrolling
var last_facing_direction: int = 1  # 1 for right, -1 for left

func _ready():
	current_health = max_health
	health_changed.emit(current_health)
	
	# Setup mining area
	mining_area.body_entered.connect(_on_mining_area_body_entered)
	mining_area.body_exited.connect(_on_mining_area_body_exited)
	
	# Connect to game manager signals
	GameManager.health_changed.connect(_on_game_manager_health_changed)
	
	# Side-scrolling doesn't need captured mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	handle_input()
	handle_movement(delta)
	handle_mining(delta)
	update_depth()

func handle_input():
	# Side-scrolling 2.5D movement input
	input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_backward", "move_forward")  # Forward/back becomes up/down in side view
	
	# Track facing direction for sprite flipping
	if input_vector.x > 0:
		last_facing_direction = 1
	elif input_vector.x < 0:
		last_facing_direction = -1

func handle_movement(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		AudioManager.play_sound("jump")
	
	# Handle side-scrolling movement
	var speed_multiplier = 1.0 + (GameManager.get_upgrade_level("movement_speed") * 0.2)
	var current_speed = move_speed * speed_multiplier
	
	# Side-scrolling 2.5D movement - X is left/right, Z is depth (limited)
	velocity.x = input_vector.x * current_speed
	velocity.z = input_vector.y * current_speed * 0.3  # Limited depth movement for 2.5D effect
	
	move_and_slide()
	
	# Handle landing
	if is_on_floor() and velocity.y < 0:
		AudioManager.play_sound("land")
	
	# Update mesh rotation based on facing direction
	if mesh_instance:
		mesh_instance.scale.x = abs(mesh_instance.scale.x) * last_facing_direction

func handle_mining(delta):
	if not auto_mining or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	mining_timer -= delta
	
	if mining_timer <= 0 and current_mining_target:
		start_mining(current_mining_target)

func start_mining(target: Node3D):
	if not target or not target.has_method("mine"):
		return
	
	is_mining = true
	mining_timer = mining_cooldown
	
	# Visual feedback
	mining_particles.emitting = true
	AudioManager.play_sound("dig")
	
	# Mining effect
	var mining_speed_multiplier = 1.0 + (GameManager.get_upgrade_level("mining_speed") * 0.3)
	var actual_mining_speed = mining_speed * mining_speed_multiplier
	
	# Call target's mine method
	var material_type = target.mine(actual_mining_speed)
	
	if material_type:
		mining_completed.emit(target.global_position, material_type)
		GameManager.player_data.materials_mined += 1
		
		# Add elements based on material value
		var material_value = GameManager.material_types.get(material_type, {}).get("value", 1)
		GameManager.add_elements(material_value)
	
	is_mining = false
	mining_particles.emitting = false

func update_depth():
	var depth = -global_position.y
	GameManager.update_depth(depth)
	depth_changed.emit(depth)



func take_damage(amount: int, source: String = "unknown"):
	if is_invulnerable:
		return
	
	current_health -= amount
	health_changed.emit(current_health)
	
	# Visual feedback
	damage_particles.emitting = true
	AudioManager.play_sound("robot_damage")
	
	# Invulnerability period
	is_invulnerable = true
	var tween = create_tween()
	tween.tween_callback(func(): is_invulnerable = false).set_delay(invulnerability_time)
	
	# Flash effect
	var flash_tween = create_tween()
	flash_tween.set_loops(4)
	flash_tween.tween_property(mesh_instance, "transparency", 0.5, 0.1)
	flash_tween.tween_property(mesh_instance, "transparency", 0.0, 0.1)
	
	# Update game manager
	GameManager.change_health(-amount)

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health)
	GameManager.change_health(amount)

func _on_mining_area_body_entered(body: Node3D):
	if body.has_method("mine") and auto_mining:
		current_mining_target = body

func _on_mining_area_body_exited(body: Node3D):
	if current_mining_target == body:
		current_mining_target = null

func _on_game_manager_health_changed(new_health: int):
	current_health = new_health
	health_changed.emit(current_health)

func get_mining_efficiency() -> float:
	var base_efficiency = 1.0
	var upgrade_level = GameManager.get_upgrade_level("mining_speed")
	return base_efficiency + (upgrade_level * 0.3)

func set_build_mode(enabled: bool):
	# In side-scrolling mode, mouse is always visible
	# This function can be used for other build mode setup in the future
	pass

func _input(event):
	if event.is_action_pressed("interact") and current_mining_target:
		start_mining(current_mining_target)
