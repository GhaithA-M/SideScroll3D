extends Node3D

# Conveyor System - Handles belt placement and material transport
class_name ConveyorSystem

signal belt_placed(position: Vector3, belt_type: String)
signal material_transported(material: Node3D, from_pos: Vector3, to_pos: Vector3)

# Belt Types
enum BeltType {
	STRAIGHT,
	CORNER,
	ELEVATOR,
	JUNCTION
}

# Belt Properties
@export var belt_speed: float = 2.0
@export var belt_length: float = 1.0
@export var max_belts: int = 100

# Belt Management
var belts: Dictionary = {}
var belt_network: Dictionary = {}
var materials_on_belts: Dictionary = {}

# Placement System
var is_placing: bool = false
var current_belt_type: BeltType = BeltType.STRAIGHT
var placement_preview: Node3D = null
var placement_position: Vector3 = Vector3.ZERO

# Belt Models
var belt_models = {
	BeltType.STRAIGHT: null,
	BeltType.CORNER: null,
	BeltType.ELEVATOR: null,
	BeltType.JUNCTION: null
}

func _ready():
	load_belt_models()
	setup_placement_system()

func _process(delta):
	if is_placing:
		update_placement_preview()
	
	transport_materials(delta)

func load_belt_models():
	# Create industrial-style belt models matching Dig n Rig aesthetic
	
	for belt_type in BeltType.values():
		var belt_node = Node3D.new()
		
		# Main belt surface
		var belt_surface = MeshInstance3D.new()
		var surface_mesh = BoxMesh.new()
		surface_mesh.size = Vector3(belt_length, 0.1, 0.8)
		belt_surface.mesh = surface_mesh
		
		# Industrial blue conveyor material like Dig n Rig
		var surface_material = StandardMaterial3D.new()
		surface_material.albedo_color = Color(0.2, 0.4, 0.8)  # Industrial blue
		surface_material.metallic = 0.3
		surface_material.roughness = 0.7
		belt_surface.material_override = surface_material
		belt_node.add_child(belt_surface)
		
		# Side rails
		var left_rail = MeshInstance3D.new()
		var rail_mesh = BoxMesh.new()
		rail_mesh.size = Vector3(belt_length, 0.2, 0.1)
		left_rail.mesh = rail_mesh
		left_rail.position = Vector3(0, 0.05, 0.45)
		
		var right_rail = MeshInstance3D.new()
		right_rail.mesh = rail_mesh
		right_rail.position = Vector3(0, 0.05, -0.45)
		
		# Rail material - darker gray
		var rail_material = StandardMaterial3D.new()
		rail_material.albedo_color = Color(0.3, 0.3, 0.3)
		rail_material.metallic = 0.8
		rail_material.roughness = 0.4
		left_rail.material_override = rail_material
		right_rail.material_override = rail_material
		
		belt_node.add_child(left_rail)
		belt_node.add_child(right_rail)
		
		# Type-specific modifications
		match belt_type:
			BeltType.CORNER:
				# Add corner indicator
				surface_material.albedo_color = Color(0.2, 0.6, 0.8)
			BeltType.ELEVATOR:
				# Make it more vertical looking
				surface_material.albedo_color = Color(0.8, 0.8, 0.2)
			BeltType.JUNCTION:
				# Add junction indicator
				surface_material.albedo_color = Color(0.8, 0.2, 0.2)
		
		belt_models[belt_type] = belt_node

func setup_placement_system():
	# Create placement preview
	placement_preview = MeshInstance3D.new()
	placement_preview.mesh = BoxMesh.new()
	placement_preview.material_override = StandardMaterial3D.new()
	placement_preview.material_override.albedo_color = Color.WHITE
	placement_preview.material_override.albedo_color.a = 0.5
	placement_preview.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_child(placement_preview)
	placement_preview.visible = false

func start_placement(belt_type: BeltType):
	is_placing = true
	current_belt_type = belt_type
	placement_preview.visible = true
	update_placement_preview()

func stop_placement():
	is_placing = false
	placement_preview.visible = false

func update_placement_preview():
	if not is_placing:
		return
	
	# Get mouse position in 3D space
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Terrain layer
	
	var result = space_state.intersect_ray(query)
	
	if result:
		placement_position = result.position
		placement_position.y += 0.1  # Slightly above surface
		placement_preview.global_position = placement_position
		
		# Update preview based on belt type
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(belt_length, 0.1, 0.8)
		placement_preview.mesh = box_mesh
		
		# Set preview color based on belt type
		match current_belt_type:
			BeltType.STRAIGHT:
				placement_preview.material_override.albedo_color = Color(0.2, 0.4, 0.8, 0.5)
			BeltType.CORNER:
				placement_preview.material_override.albedo_color = Color(0.2, 0.6, 0.8, 0.5)
			BeltType.ELEVATOR:
				placement_preview.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.5)
			BeltType.JUNCTION:
				placement_preview.material_override.albedo_color = Color(0.8, 0.2, 0.2, 0.5)

func place_belt(position: Vector3, belt_type: BeltType, direction: Vector3 = Vector3.FORWARD) -> bool:
	if belts.size() >= max_belts:
		return false
	
	# Check if position is valid
	if not is_valid_placement_position(position):
		return false
	
	# Create belt instance
	var belt_instance = create_belt_instance(belt_type, direction)
	belt_instance.global_position = position
	add_child(belt_instance)
	
	# Store belt data
	var belt_id = str(position)
	belts[belt_id] = {
		"instance": belt_instance,
		"type": belt_type,
		"position": position,
		"direction": direction,
		"connections": []
	}
	
	# Update network
	update_belt_network(belt_id)
	
	belt_placed.emit(position, BeltType.keys()[belt_type])
	AudioManager.play_sound("conveyor_place")
	
	return true

func create_belt_instance(belt_type: BeltType, direction: Vector3) -> Node3D:
	var belt_node = Node3D.new()
	belt_node.name = "Belt_" + BeltType.keys()[belt_type]
	
	# Add the industrial belt model
	var belt_model = belt_models[belt_type].duplicate()
	belt_node.add_child(belt_model)
	
	# Add collision for material detection
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(belt_length, 0.3, 1.0)  # Match visual size
	collision_shape.shape = box_shape
	
	var area = Area3D.new()
	area.add_child(collision_shape)
	area.body_entered.connect(_on_belt_body_entered.bind(belt_node))
	area.body_exited.connect(_on_belt_body_exited.bind(belt_node))
	belt_node.add_child(area)
	
	# Rotate based on direction for side-scrolling layout
	if direction != Vector3.FORWARD:
		var angle = direction.angle_to(Vector3.FORWARD)
		belt_node.rotate_y(angle)
	
	return belt_node

func is_valid_placement_position(position: Vector3) -> bool:
	# Check if position is already occupied
	var belt_id = str(position)
	if belts.has(belt_id):
		return false
	
	# Check if position is on solid ground
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(position + Vector3.UP * 2, position - Vector3.UP * 2)
	query.collision_mask = 2  # Terrain layer
	
	var result = space_state.intersect_ray(query)
	return result != null

func update_belt_network(belt_id: String):
	var belt_data = belts[belt_id]
	var position = belt_data.position
	
	# Find nearby belts for connections
	for other_id in belts.keys():
		if other_id == belt_id:
			continue
		
		var other_data = belts[other_id]
		var distance = position.distance_to(other_data.position)
		
		if distance <= belt_length * 1.5:
			# Check if belts can connect
			if can_connect_belts(belt_data, other_data):
				belt_data.connections.append(other_id)
				other_data.connections.append(belt_id)

func can_connect_belts(belt1: Dictionary, belt2: Dictionary) -> bool:
	# Simple connection logic - can be expanded for complex networks
	var direction_diff = belt1.direction.dot(belt2.direction)
	return abs(direction_diff) > 0.5

func transport_materials(delta):
	var speed_multiplier = 1.0 + (GameManager.get_upgrade_level("conveyor_speed") * 0.2)
	var current_speed = belt_speed * speed_multiplier
	
	for belt_id in materials_on_belts.keys():
		var materials = materials_on_belts[belt_id]
		
		for material in materials:
			if not is_instance_valid(material):
				materials.erase(material)
				continue
			
			# Move material along belt
			var belt_data = belts[belt_id]
			var target_pos = belt_data.position + belt_data.direction * belt_length
			
			var direction = (target_pos - material.global_position).normalized()
			material.global_position += direction * current_speed * delta
			
			# Check if material reached end of belt
			if material.global_position.distance_to(target_pos) < 0.1:
				# Try to transfer to next belt
				var transferred = transfer_to_next_belt(material, belt_id)
				if not transferred:
					# Drop material if no next belt
					material.linear_velocity = Vector3.ZERO
					materials.erase(material)

func transfer_to_next_belt(material: Node3D, current_belt_id: String) -> bool:
	var belt_data = belts[current_belt_id]
	
	for connection_id in belt_data.connections:
		var next_belt = belts[connection_id]
		var distance = material.global_position.distance_to(next_belt.position)
		
		if distance < belt_length:
			# Transfer to next belt
			if not materials_on_belts.has(connection_id):
				materials_on_belts[connection_id] = []
			
			materials_on_belts[connection_id].append(material)
			
			# Remove from current belt
			if materials_on_belts.has(current_belt_id):
				materials_on_belts[current_belt_id].erase(material)
			
			material_transported.emit(material, belt_data.position, next_belt.position)
			return true
	
	return false

func add_material_to_belt(material: Node3D, belt_id: String):
	if not materials_on_belts.has(belt_id):
		materials_on_belts[belt_id] = []
	
	materials_on_belts[belt_id].append(material)
	
	# Position material on belt
	var belt_data = belts[belt_id]
	material.global_position = belt_data.position

func _on_belt_body_entered(body: Node3D, belt_node: Node3D):
	if body.has_method("get_material_type"):
		# Find belt ID
		for belt_id in belts.keys():
			if belts[belt_id].instance == belt_node:
				add_material_to_belt(body, belt_id)
				break

func _on_belt_body_exited(body: Node3D, belt_node: Node3D):
	# Remove material from belt
	for belt_id in materials_on_belts.keys():
		var materials = materials_on_belts[belt_id]
		if body in materials:
			materials.erase(body)

func get_belt_at_position(position: Vector3) -> Dictionary:
	var belt_id = str(position)
	return belts.get(belt_id, {})

func remove_belt(position: Vector3) -> bool:
	var belt_id = str(position)
	
	if not belts.has(belt_id):
		return false
	
	var belt_data = belts[belt_id]
	
	# Remove belt instance
	belt_data.instance.queue_free()
	
	# Remove from network
	for connection_id in belt_data.connections:
		if belts.has(connection_id):
			belts[connection_id].connections.erase(belt_id)
	
	# Remove materials
	if materials_on_belts.has(belt_id):
		for material in materials_on_belts[belt_id]:
			material.linear_velocity = Vector3.ZERO
		materials_on_belts.erase(belt_id)
	
	belts.erase(belt_id)
	return true

func get_belt_count() -> int:
	return belts.size()

func get_total_materials_transported() -> int:
	var total = 0
	for materials in materials_on_belts.values():
		total += materials.size()
	return total
