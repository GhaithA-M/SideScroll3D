extends Node3D

# Terrain System - Handles procedural terrain generation and destruction
class_name TerrainSystem

signal terrain_chunk_generated(chunk_position: Vector3)
signal terrain_destroyed(position: Vector3, material_type: String)

# Terrain Generation
@export var chunk_size: int = 16
@export var chunk_height: int = 32
@export var world_size: int = 8  # Number of chunks in each direction
@export var surface_height: int = 5

# Material Generation
@export var material_spawn_chance: float = 0.1
@export var rare_material_chance: float = 0.02
@export var fossil_chance: float = 0.005

# Noise Generation
var noise: FastNoiseLite
var material_noise: FastNoiseLite
var rare_noise: FastNoiseLite

# Chunk Management
var chunks: Dictionary = {}
var active_chunks: Array[Vector3] = []
var chunk_meshes: Dictionary = {}

# Dig n Rig style layered materials by depth
var depth_materials = {
	0: ["grass", "dirt"],      # Surface layer (green/brown)
	5: ["dirt", "dirt"],       # Pure dirt layer (brown)
	15: ["stone", "stone"],    # Stone layer (gray)
	30: ["iron", "stone"],     # Iron deposits (orange/gray)
	50: ["gold", "iron"],      # Gold deposits (yellow/orange)
	80: ["diamond", "gold"],   # Diamond layer (cyan/yellow)
	120: ["fossil", "diamond"] # Deep fossils (white/cyan)
}

func _ready():
	setup_noise()
	generate_initial_terrain()

func setup_noise():
	# Main terrain noise
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	
	# Material distribution noise
	material_noise = FastNoiseLite.new()
	material_noise.seed = randi() + 1
	material_noise.frequency = 0.05
	
	# Rare material noise
	rare_noise = FastNoiseLite.new()
	rare_noise.seed = randi() + 2
	rare_noise.frequency = 0.1

func generate_initial_terrain():
	# Generate chunks around origin
	for x in range(-world_size/2, world_size/2):
		for z in range(-world_size/2, world_size/2):
			var chunk_pos = Vector3(x * chunk_size, 0, z * chunk_size)
			generate_chunk(chunk_pos)

func generate_chunk(chunk_position: Vector3):
	if chunks.has(chunk_position):
		return
	
	var chunk_data = generate_chunk_data(chunk_position)
	chunks[chunk_position] = chunk_data
	
	var chunk_mesh = create_chunk_mesh(chunk_data, chunk_position)
	chunk_meshes[chunk_position] = chunk_mesh
	add_child(chunk_mesh)
	
	active_chunks.append(chunk_position)
	terrain_chunk_generated.emit(chunk_position)

func generate_chunk_data(chunk_position: Vector3) -> Dictionary:
	var chunk_data = {
		"blocks": {},
		"materials": {},
		"height_map": {}
	}
	
	for x in range(chunk_size):
		for z in range(chunk_size):
			var world_x = chunk_position.x + x
			var world_z = chunk_position.z + z
			
			# Generate height using noise
			var height = generate_height(world_x, world_z)
			chunk_data.height_map[Vector2(x, z)] = height
			
			# Generate blocks from surface to height
			for y in range(height):
				var block_pos = Vector3(x, y, z)
				var material_type = determine_material_type(world_x, y, world_z)
				
				chunk_data.blocks[block_pos] = material_type
				
				# Add material drops
				if should_spawn_material(y, material_type):
					chunk_data.materials[block_pos] = material_type
	
	return chunk_data

func generate_height(x: float, z: float) -> int:
	var noise_value = noise.get_noise_2d(x, z)
	var height = int((noise_value + 1.0) * 0.5 * chunk_height) + surface_height
	return clamp(height, surface_height, chunk_height)

func determine_material_type(x: float, y: float, z: float) -> String:
	var depth = abs(y)  # Positive depth values
	
	# Dig n Rig style - clear layered materials by depth
	var material_type = "dirt"  # Default
	
	# Determine layer based on exact depth thresholds
	if depth < 5:
		material_type = "grass" if depth < 2 else "dirt"
	elif depth < 15:
		material_type = "dirt"
	elif depth < 30:
		material_type = "stone"
	elif depth < 50:
		# Mix of iron and stone
		var noise_value = material_noise.get_noise_3d(x, y, z)
		material_type = "iron" if noise_value > 0.2 else "stone"
	elif depth < 80:
		# Mix of gold and iron
		var noise_value = material_noise.get_noise_3d(x, y, z)
		material_type = "gold" if noise_value > 0.4 else "iron"
	elif depth < 120:
		# Mix of diamond and gold
		var noise_value = material_noise.get_noise_3d(x, y, z)
		material_type = "diamond" if noise_value > 0.6 else "gold"
	else:
		# Deep fossils and diamonds
		var noise_value = material_noise.get_noise_3d(x, y, z)
		material_type = "fossil" if noise_value > 0.8 else "diamond"
	
	return material_type

func should_spawn_material(y: int, material_type: String) -> bool:
	var depth = -y
	var base_chance = material_spawn_chance
	
	# Increase chance with depth
	base_chance += depth * 0.001
	
	# Special handling for rare materials
	if material_type == "diamond" or material_type == "fossil":
		base_chance *= 0.1
	
	return randf() < base_chance

func create_chunk_mesh(chunk_data: Dictionary, chunk_position: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Chunk_" + str(chunk_position)
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(chunk_size, chunk_height, chunk_size)
	collision_shape.shape = box_shape
	
	var static_body = StaticBody3D.new()
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	
	# Create mesh from chunk data
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for block_pos in chunk_data.blocks.keys():
		var material_type = chunk_data.blocks[block_pos]
		var world_pos = chunk_position + block_pos
		
		# Create cube mesh for this block
		create_block_mesh(surface_tool, world_pos, material_type)
	
	surface_tool.index()
	mesh_instance.mesh = surface_tool.commit()
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	return mesh_instance

func create_block_mesh(surface_tool: SurfaceTool, position: Vector3, material_type: String):
	var color = GameManager.material_types.get(material_type, {}).get("color", Color.GRAY)
	var size = 1.0
	
	# Define cube vertices
	var vertices = [
		Vector3(-size/2, -size/2, -size/2),  # 0
		Vector3(size/2, -size/2, -size/2),   # 1
		Vector3(size/2, size/2, -size/2),    # 2
		Vector3(-size/2, size/2, -size/2),   # 3
		Vector3(-size/2, -size/2, size/2),   # 4
		Vector3(size/2, -size/2, size/2),    # 5
		Vector3(size/2, size/2, size/2),     # 6
		Vector3(-size/2, size/2, size/2)     # 7
	]
	
	# Define faces (triangles)
	var faces = [
		[0, 1, 2], [0, 2, 3],  # Front
		[1, 5, 6], [1, 6, 2],  # Right
		[5, 4, 7], [5, 7, 6],  # Back
		[4, 0, 3], [4, 3, 7],  # Left
		[3, 2, 6], [3, 6, 7],  # Top
		[4, 5, 1], [4, 1, 0]   # Bottom
	]
	
	# Add vertices and faces
	for face in faces:
		for vertex_index in face:
			surface_tool.set_color(color)
			surface_tool.add_vertex(vertices[vertex_index] + position)

func mine_block(world_position: Vector3) -> String:
	var chunk_pos = get_chunk_position(world_position)
	var local_pos = world_position - chunk_pos
	
	if not chunks.has(chunk_pos):
		return ""
	
	var chunk_data = chunks[chunk_pos]
	var block_key = Vector3(local_pos.x, local_pos.y, local_pos.z)
	
	if not chunk_data.blocks.has(block_key):
		return ""
	
	var material_type = chunk_data.blocks[block_key]
	
	# Remove block
	chunk_data.blocks.erase(block_key)
	
	# Check for material drop
	if chunk_data.materials.has(block_key):
		var material_drop = chunk_data.materials[block_key]
		spawn_material_drop(world_position, material_drop)
		chunk_data.materials.erase(block_key)
	
	# Regenerate chunk mesh
	regenerate_chunk_mesh(chunk_pos)
	
	terrain_destroyed.emit(world_position, material_type)
	return material_type

func get_chunk_position(world_position: Vector3) -> Vector3:
	return Vector3(
		floor(world_position.x / chunk_size) * chunk_size,
		0,
		floor(world_position.z / chunk_size) * chunk_size
	)

func regenerate_chunk_mesh(chunk_position: Vector3):
	if not chunks.has(chunk_position):
		return
	
	var chunk_data = chunks[chunk_position]
	
	# Remove old mesh
	if chunk_meshes.has(chunk_position):
		var old_mesh = chunk_meshes[chunk_position]
		old_mesh.queue_free()
		chunk_meshes.erase(chunk_position)
	
	# Create new mesh
	var new_mesh = create_chunk_mesh(chunk_data, chunk_position)
	chunk_meshes[chunk_position] = new_mesh
	add_child(new_mesh)

func spawn_material_drop(position: Vector3, material_type: String):
	var material_scene = preload("res://scenes/materials/material_drop.tscn")
	var material_instance = material_scene.instantiate()
	material_instance.material_type = material_type
	material_instance.global_position = position
	get_parent().add_child(material_instance)

func get_block_at_position(world_position: Vector3) -> String:
	var chunk_pos = get_chunk_position(world_position)
	var local_pos = world_position - chunk_pos
	
	if not chunks.has(chunk_pos):
		return ""
	
	var chunk_data = chunks[chunk_pos]
	var block_key = Vector3(local_pos.x, local_pos.y, local_pos.z)
	
	return chunk_data.blocks.get(block_key, "")

func is_position_solid(world_position: Vector3) -> bool:
	return get_block_at_position(world_position) != ""

func get_height_at_position(x: float, z: float) -> float:
	var chunk_pos = get_chunk_position(Vector3(x, 0, z))
	var local_x = int(x - chunk_pos.x)
	var local_z = int(z - chunk_pos.z)
	
	if not chunks.has(chunk_pos):
		return surface_height
	
	var chunk_data = chunks[chunk_pos]
	var height_key = Vector2(local_x, local_z)
	
	return chunk_data.height_map.get(height_key, surface_height)
