extends RigidBody3D

# Material Drop - Individual material item with physics
class_name MaterialDrop

signal collected(material_type: String, value: int)

@export var material_type: String = "dirt"
@export var value: int = 1
@export var collect_range: float = 2.0
@export var magnet_range: float = 5.0

# Components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var collection_area: Area3D = $CollectionArea
@onready var particles: GPUParticles3D = $Particles

# Physics
var is_collected: bool = false
var is_magnetized: bool = false
var magnet_target: Node3D = null
var magnet_speed: float = 10.0

# Visual
var original_color: Color
var pulse_tween: Tween

func _ready():
	setup_material()
	setup_physics()
	setup_visual_effects()
	
	# Connect signals
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	collection_area.body_exited.connect(_on_collection_area_body_exited)

func setup_material():
	# Set material properties based on type
	var material_data = GameManager.material_types.get(material_type, {})
	value = material_data.get("value", 1)
	
	# Create mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	mesh_instance.mesh = sphere_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = material_data.get("color", Color.GRAY)
	material.metallic = 0.3
	material.roughness = 0.7
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.2
	mesh_instance.material_override = material
	
	original_color = material.albedo_color

func setup_physics():
	# Set collision layer/mask
	collision_layer = 4  # Materials layer
	collision_mask = 1 | 2 | 4  # Terrain, Player, Materials
	
	# Set mass based on material type
	match material_type:
		"dirt":
			mass = 1.0
		"stone":
			mass = 2.0
		"iron":
			mass = 3.0
		"gold":
			mass = 4.0
		"diamond":
			mass = 5.0
		"fossil":
			mass = 6.0
		_:
			mass = 1.0

func setup_visual_effects():
	# Setup collection area
	var area_shape = SphereShape3D.new()
	area_shape.radius = collect_range
	collection_area.get_child(0).shape = area_shape
	
	# Setup particles
	particles.emitting = false
	
	# Start pulse effect
	start_pulse_effect()

func start_pulse_effect():
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(mesh_instance, "scale", Vector3(1.2, 1.2, 1.2), 1.0)
	pulse_tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 1.0)

func _physics_process(delta):
	if is_collected:
		return
	
	if is_magnetized and magnet_target:
		# Move towards magnet target
		var direction = (magnet_target.global_position - global_position).normalized()
		linear_velocity = direction * magnet_speed
		
		# Check if close enough to collect
		if global_position.distance_to(magnet_target.global_position) < 1.0:
			collect(magnet_target)
	else:
		# Normal physics
		apply_central_force(Vector3.DOWN * 20.0)  # Gravity

func _on_collection_area_body_entered(body: Node3D):
	if body.has_method("take_damage"):  # Player
		magnet_target = body
		is_magnetized = true
		start_magnet_effect()

func _on_collection_area_body_exited(body: Node3D):
	if magnet_target == body:
		magnet_target = null
		is_magnetized = false
		stop_magnet_effect()

func start_magnet_effect():
	# Visual feedback for magnetization
	var magnet_tween = create_tween()
	magnet_tween.tween_property(mesh_instance, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	
	# Change color
	var material = mesh_instance.material_override as StandardMaterial3D
	material.emission = material.albedo_color * 0.8

func stop_magnet_effect():
	# Reset visual effects
	var magnet_tween = create_tween()
	magnet_tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
	
	# Reset color
	var material = mesh_instance.material_override as StandardMaterial3D
	material.emission = material.albedo_color * 0.2

func collect(collector: Node3D):
	if is_collected:
		return
	
	is_collected = true
	
	# Visual effects
	particles.emitting = true
	AudioManager.play_sound("coin_collect")
	
	# Add elements to game manager
	GameManager.add_elements(value)
	
	# Emit signal
	collected.emit(material_type, value)
	
	# Animate collection
	var collect_tween = create_tween()
	collect_tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	collect_tween.tween_callback(queue_free)

func get_material_type() -> String:
	return material_type

func get_value() -> int:
	return value

func set_material_type(new_type: String):
	material_type = new_type
	setup_material()

func _on_body_entered(body: Node3D):
	# Play impact sound
	if body.has_method("take_damage"):  # Player collision
		AudioManager.play_sound("material_drop")
	elif body.has_method("mine"):  # Terrain collision
		AudioManager.play_sound("material_drop")

func _exit_tree():
	if pulse_tween:
		pulse_tween.kill()
