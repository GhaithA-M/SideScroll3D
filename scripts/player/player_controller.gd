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
@onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var mining_area: Area3D = $MiningArea
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Mining State
var is_mining: bool = false
var current_mining_target: Node3D = null
var mining_timer: float = 0.0
var mining_cooldown: float = 0.5

# Visual Effects
@onready var mining_particles: GPUParticles3D = $MiningParticles
@onready var damage_particles: GPUParticles3D = $DamageParticles

# Input
var input_vector: Vector3
var mouse_sensitivity: float = 0.002
var camera_rotation: Vector2

func _ready():
	current_health = max_health
	health_changed.emit(current_health)
	
	# Setup mining area
	mining_area.body_entered.connect(_on_mining_area_body_entered)
	mining_area.body_exited.connect(_on_mining_area_body_exited)
	
	# Connect to game manager signals
	GameManager.health_changed.connect(_on_game_manager_health_changed)
	
	# Setup camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	handle_input()
	handle_movement(delta)
	handle_mining(delta)
	update_depth()
	handle_camera(delta)

func handle_input():
	# Movement input
	input_vector = Vector3.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.z = Input.get_axis("move_backward", "move_forward")
	input_vector = input_vector.normalized()
	
	# Mouse look
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= Input.get_last_mouse_velocity().y * mouse_sensitivity
		camera_rotation.y -= Input.get_last_mouse_velocity().x * mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)

func handle_movement(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		AudioManager.play_sound("jump")
	
	# Handle horizontal movement
	var speed_multiplier = 1.0 + (GameManager.get_upgrade_level("movement_speed") * 0.2)
	var current_speed = move_speed * speed_multiplier
	
	# Transform input to camera space
	var camera_basis = camera.global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	velocity.x = (forward * input_vector.z + right * input_vector.x).x * current_speed
	velocity.z = (forward * input_vector.z + right * input_vector.x).z * current_speed
	
	move_and_slide()
	
	# Handle landing
	if is_on_floor() and velocity.y < 0:
		AudioManager.play_sound("land")

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

func handle_camera(delta):
	# Update camera rotation
	camera_arm.rotation.x = camera_rotation.x
	camera_arm.rotation.y = camera_rotation.y

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
	if enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed("interact") and current_mining_target:
		start_mining(current_mining_target)
