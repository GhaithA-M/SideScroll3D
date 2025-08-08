extends CharacterBody3D

# Mole Enemy - Ferocious underground creature
class_name MoleEnemy

signal player_detected(player: Node3D)
signal player_lost()
signal mole_died()

@export var health: int = 50
@export var damage: int = 20
@export var move_speed: float = 3.0
@export var detection_range: float = 8.0
@export var attack_range: float = 2.0
@export var patrol_radius: float = 10.0

# AI States
enum AIState {
	PATROL,
	CHASE,
	ATTACK,
	RETREAT
}

# Components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particles: GPUParticles3D = $Particles

# AI Variables
var current_state: AIState = AIState.PATROL
var target_player: Node3D = null
var patrol_center: Vector3
var patrol_target: Vector3
var last_attack_time: float = 0.0
var attack_cooldown: float = 2.0
var is_dead: bool = false

# Movement
var gravity: float = 20.0

func _ready():
	setup_mole()
	setup_ai()
	
	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func setup_mole():
	# Create mole mesh
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.5
	capsule_mesh.height = 1.0
	mesh_instance.mesh = capsule_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.DARK_GRAY
	material.roughness = 0.9
	mesh_instance.material_override = material
	
	# Setup collision
	collision_layer = 16  # Enemies layer
	collision_mask = 1 | 2 | 4  # Terrain, Player, Materials
	
	# Setup detection area
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_area.get_child(0).shape = detection_shape
	
	# Setup attack area
	var attack_shape = SphereShape3D.new()
	attack_shape.radius = attack_range
	attack_area.get_child(0).shape = attack_shape

func setup_ai():
	patrol_center = global_position
	generate_patrol_target()

func _physics_process(delta):
	if is_dead:
		return
	
	update_ai_state(delta)
	apply_gravity(delta)
	move_and_slide()

func update_ai_state(delta):
	match current_state:
		AIState.PATROL:
			handle_patrol(delta)
		AIState.CHASE:
			handle_chase(delta)
		AIState.ATTACK:
			handle_attack(delta)
		AIState.RETREAT:
			handle_retreat(delta)

func handle_patrol(delta):
	# Move towards patrol target
	var direction = (patrol_target - global_position).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Check if reached patrol target
	if global_position.distance_to(patrol_target) < 1.0:
		generate_patrol_target()

func handle_chase(delta):
	if not target_player or not is_instance_valid(target_player):
		current_state = AIState.PATROL
		player_lost.emit()
		return
	
	# Move towards player
	var direction = (target_player.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed * 1.5
	velocity.z = direction.z * move_speed * 1.5
	
	# Check if close enough to attack
	if global_position.distance_to(target_player.global_position) <= attack_range:
		current_state = AIState.ATTACK

func handle_attack(delta):
	if not target_player or not is_instance_valid(target_player):
		current_state = AIState.PATROL
		return
	
	var current_time = Time.get_time_dict_from_system()
	if current_time - last_attack_time >= attack_cooldown:
		perform_attack()
		last_attack_time = current_time
	
	# Return to chase if player moved away
	if global_position.distance_to(target_player.global_position) > attack_range:
		current_state = AIState.CHASE

func handle_retreat(delta):
	# Move back to patrol center
	var direction = (patrol_center - global_position).normalized()
	velocity.x = direction.x * move_speed * 0.5
	velocity.z = direction.z * move_speed * 0.5
	
	# Return to patrol when close enough
	if global_position.distance_to(patrol_center) < 2.0:
		current_state = AIState.PATROL

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func generate_patrol_target():
	var angle = randf() * PI * 2
	var distance = randf_range(2.0, patrol_radius)
	patrol_target = patrol_center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)

func perform_attack():
	if not target_player or not is_instance_valid(target_player):
		return
	
	# Play attack animation
	if animation_player:
		animation_player.play("attack")
	
	# Deal damage to player
	if target_player.has_method("take_damage"):
		target_player.take_damage(damage, "mole")
		AudioManager.play_sound("mole_attack")
	
	# Visual feedback
	particles.emitting = true

func take_damage(amount: int, source: String = "unknown"):
	if is_dead:
		return
	
	health -= amount
	
	# Visual feedback
	var damage_tween = create_tween()
	damage_tween.tween_property(mesh_instance, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	damage_tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	
	AudioManager.play_sound("robot_damage")
	
	if health <= 0:
		die()
	else:
		# Aggro on damage
		if source == "player":
			current_state = AIState.CHASE

func die():
	is_dead = true
	
	# Play death animation
	if animation_player:
		animation_player.play("death")
	
	# Disable collision
	collision_shape.disabled = true
	detection_area.monitoring = false
	attack_area.monitoring = false
	
	# Visual effects
	particles.emitting = true
	
	# Emit signal
	mole_died.emit()
	
	# Remove after delay
	var death_timer = get_tree().create_timer(2.0)
	death_timer.timeout.connect(queue_free)

func _on_detection_area_body_entered(body: Node3D):
	if body.has_method("take_damage"):  # Player detected
		target_player = body
		current_state = AIState.CHASE
		player_detected.emit(body)
		AudioManager.play_sound("mole_attack")

func _on_detection_area_body_exited(body: Node3D):
	if target_player == body:
		target_player = null
		current_state = AIState.RETREAT
		player_lost.emit()

func _on_attack_area_body_entered(body: Node3D):
	if body.has_method("take_damage") and current_state == AIState.CHASE:
		current_state = AIState.ATTACK

func get_ai_state() -> AIState:
	return current_state

func set_patrol_center(center: Vector3):
	patrol_center = center
	generate_patrol_target()

func is_player_in_range() -> bool:
	return target_player != null and is_instance_valid(target_player)

func get_distance_to_player() -> float:
	if not target_player or not is_instance_valid(target_player):
		return INF
	return global_position.distance_to(target_player.global_position)
