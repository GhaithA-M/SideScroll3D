extends Node3D

# Enemy Manager - Handles enemy spawning and AI coordination
class_name EnemyManager

signal enemy_spawned(enemy: Node3D)
signal enemy_died(enemy: Node3D)

@export var max_enemies: int = 10
@export var spawn_interval: float = 30.0
@export var spawn_depth_threshold: float = 20.0

# Enemy Management
var active_enemies: Array[Node3D] = []
var spawn_timer: float = 0.0
var last_spawn_depth: float = 0.0

# Enemy Types
var enemy_types = {
	"mole": {
		"health": 50,
		"damage": 20,
		"speed": 3.0,
		"spawn_chance": 0.8
	}
}

func _ready():
	# Initialize enemy manager
	pass

func _process(delta):
	# Handle enemy spawning
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and active_enemies.size() < max_enemies:
		attempt_spawn_enemy()
		spawn_timer = 0.0

func attempt_spawn_enemy():
	# Check if player is deep enough
	var player_depth = GameManager.player_data.max_depth
	if player_depth < spawn_depth_threshold:
		return
	
	# Don't spawn too close to last spawn
	if abs(player_depth - last_spawn_depth) < 5.0:
		return
	
	# Spawn enemy
	var spawn_position = get_spawn_position()
	if spawn_position != Vector3.ZERO:
		spawn_enemy(spawn_position)
		last_spawn_depth = player_depth

func get_spawn_position() -> Vector3:
	# Get player position
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return Vector3.ZERO
	
	var player_pos = player.global_position
	
	# Find suitable spawn position away from player
	for attempt in range(10):
		var angle = randf() * PI * 2
		var distance = randf_range(15.0, 30.0)
		var spawn_pos = player_pos + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		# Check if position is valid (not too close to player)
		if spawn_pos.distance_to(player_pos) > 10.0:
			# Adjust Y position based on depth
			spawn_pos.y = -GameManager.player_data.max_depth + randf_range(-5, 5)
			return spawn_pos
	
	return Vector3.ZERO

func spawn_enemy(position: Vector3, enemy_type: String = "mole"):
	if active_enemies.size() >= max_enemies:
		return
	
	# Create enemy instance
	var enemy_scene = preload("res://scenes/enemies/mole_enemy.tscn")
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = position
	
	# Configure enemy based on type
	if enemy_types.has(enemy_type):
		var config = enemy_types[enemy_type]
		enemy_instance.health = config.health
		enemy_instance.damage = config.damage
		enemy_instance.move_speed = config.speed
	
	# Add to scene
	add_child(enemy_instance)
	active_enemies.append(enemy_instance)
	
	# Connect signals
	enemy_instance.mole_died.connect(_on_enemy_died.bind(enemy_instance))
	
	# Emit signal
	enemy_spawned.emit(enemy_instance)
	
	# Play spawn sound
	AudioManager.play_sound("mole_attack")

func _on_enemy_died(enemy: Node3D):
	# Remove from active enemies
	active_enemies.erase(enemy)
	
	# Emit signal
	enemy_died.emit(enemy)
	
	# Add elements as reward
	GameManager.add_elements(5)

func get_active_enemy_count() -> int:
	return active_enemies.size()

func clear_all_enemies():
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

func get_enemies_near_player(radius: float) -> Array[Node3D]:
	var nearby_enemies: Array[Node3D] = []
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		return nearby_enemies
	
	var player_pos = player.global_position
	
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(player_pos) <= radius:
			nearby_enemies.append(enemy)
	
	return nearby_enemies

func set_spawn_interval(new_interval: float):
	spawn_interval = new_interval

func set_max_enemies(new_max: int):
	max_enemies = new_max

func get_enemy_config(enemy_type: String) -> Dictionary:
	return enemy_types.get(enemy_type, {})

func update_enemy_config(enemy_type: String, new_config: Dictionary):
	if enemy_types.has(enemy_type):
		enemy_types[enemy_type] = new_config
