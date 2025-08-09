extends Node3D

# Underground Facility - Creates 3D industrial structures visible in cutaway view
class_name UndergroundFacility

signal facility_built(facility_type: String, position: Vector3)
signal material_processed(material_type: String, amount: int)

# Facility Types
enum FacilityType {
	MAIN_BASE,
	PROCESSING_PLANT,
	STORAGE_DEPOT,
	DRILL_RIG,
	CONVEYOR_HUB,
	POWER_STATION
}

# Facility Instances
var facilities: Dictionary = {}
var facility_meshes: Dictionary = {}

# Industrial Materials
var metal_material: StandardMaterial3D
var concrete_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var warning_material: StandardMaterial3D

func _ready():
	setup_materials()
	create_initial_facilities()

func setup_materials():
	# Industrial metal material
	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.4, 0.4, 0.45)
	metal_material.metallic = 0.8
	metal_material.roughness = 0.3
	
	# Concrete material
	concrete_material = StandardMaterial3D.new()
	concrete_material.albedo_color = Color(0.6, 0.6, 0.6)
	concrete_material.roughness = 0.9
	
	# Glass material
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.7, 0.9, 1.0, 0.3)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.roughness = 0.0
	
	# Warning/accent material
	warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = Color(1.0, 0.6, 0.0)
	warning_material.emission = Color(1.0, 0.6, 0.0) * 0.2

func create_initial_facilities():
	# Create main base at surface level
	build_facility(FacilityType.MAIN_BASE, Vector3(0, 0, 0))
	
	# Create processing plant underground
	build_facility(FacilityType.PROCESSING_PLANT, Vector3(0, -10, 0))
	
	# Create storage depot deeper
	build_facility(FacilityType.STORAGE_DEPOT, Vector3(0, -20, 0))
	
	# Create power station
	build_facility(FacilityType.POWER_STATION, Vector3(-15, -15, 0))

func build_facility(facility_type: FacilityType, position: Vector3) -> Node3D:
	var facility_node = Node3D.new()
	facility_node.name = "Facility_" + FacilityType.keys()[facility_type]
	facility_node.global_position = position
	
	match facility_type:
		FacilityType.MAIN_BASE:
			create_main_base(facility_node)
		FacilityType.PROCESSING_PLANT:
			create_processing_plant(facility_node)
		FacilityType.STORAGE_DEPOT:
			create_storage_depot(facility_node)
		FacilityType.POWER_STATION:
			create_power_station(facility_node)
		FacilityType.DRILL_RIG:
			create_drill_rig(facility_node)
		FacilityType.CONVEYOR_HUB:
			create_conveyor_hub(facility_node)
	
	add_child(facility_node)
	
	var facility_id = str(position)
	facilities[facility_id] = {
		"type": facility_type,
		"position": position,
		"node": facility_node,
		"operational": true
	}
	
	facility_built.emit(FacilityType.keys()[facility_type], position)
	return facility_node

func create_main_base(parent: Node3D):
	# Main building structure
	var main_building = create_building_mesh(Vector3(8, 6, 4), metal_material)
	main_building.position = Vector3(0, 3, 0)
	parent.add_child(main_building)
	
	# Glass windows
	var windows = create_building_mesh(Vector3(7, 2, 0.2), glass_material)
	windows.position = Vector3(0, 4, 2.1)
	parent.add_child(windows)
	
	# Entrance ramp
	var ramp = create_ramp_mesh(Vector3(4, 1, 3), concrete_material)
	ramp.position = Vector3(0, 0.5, 5)
	parent.add_child(ramp)
	
	# Communication tower
	var tower = create_tower_mesh(Vector3(0.5, 8, 0.5), metal_material)
	tower.position = Vector3(6, 10, 0)
	parent.add_child(tower)
	
	# Landing pad
	var landing_pad = create_circular_mesh(4.0, 0.2, warning_material)
	landing_pad.position = Vector3(-8, 0.1, 0)
	parent.add_child(landing_pad)

func create_processing_plant(parent: Node3D):
	# Main processing unit
	var processor = create_building_mesh(Vector3(6, 5, 3), metal_material)
	processor.position = Vector3(0, 2.5, 0)
	parent.add_child(processor)
	
	# Conveyor input/output ports
	for i in range(3):
		var port = create_cylinder_mesh(0.8, 1.5, metal_material)
		port.position = Vector3(-4 + i * 4, 1, 2.5)
		parent.add_child(port)
	
	# Processing tanks
	for i in range(2):
		var tank = create_cylinder_mesh(1.5, 4, concrete_material)
		tank.position = Vector3(-2 + i * 4, 2, -2)
		parent.add_child(tank)
	
	# Pipes connecting everything
	create_pipe_network(parent)
	
	# Control room
	var control_room = create_building_mesh(Vector3(3, 3, 2), glass_material)
	control_room.position = Vector3(5, 1.5, 0)
	parent.add_child(control_room)

func create_storage_depot(parent: Node3D):
	# Large storage silos
	for i in range(4):
		var silo = create_cylinder_mesh(2, 8, concrete_material)
		silo.position = Vector3(-6 + i * 4, 4, 0)
		parent.add_child(silo)
		
		# Silo tops
		var top = create_cone_mesh(2.2, 1.5, metal_material)
		top.position = Vector3(-6 + i * 4, 8.5, 0)
		parent.add_child(top)
	
	# Material sorting facility
	var sorter = create_building_mesh(Vector3(8, 3, 6), metal_material)
	sorter.position = Vector3(0, 1.5, -5)
	parent.add_child(sorter)
	
	# Conveyor infrastructure
	for i in range(5):
		var support = create_tower_mesh(Vector3(0.3, 4, 0.3), metal_material)
		support.position = Vector3(-8 + i * 4, 2, 4)
		parent.add_child(support)

func create_power_station(parent: Node3D):
	# Main reactor housing
	var reactor = create_cylinder_mesh(3, 6, concrete_material)
	reactor.position = Vector3(0, 3, 0)
	parent.add_child(reactor)
	
	# Cooling towers
	for i in range(2):
		var tower = create_cylinder_mesh(2, 8, concrete_material)
		tower.position = Vector3(-5 + i * 10, 4, 3)
		parent.add_child(tower)
	
	# Power lines and supports
	for i in range(3):
		var support = create_tower_mesh(Vector3(0.2, 6, 0.2), metal_material)
		support.position = Vector3(-4 + i * 4, 3, -4)
		parent.add_child(support)
	
	# Generator building
	var generator = create_building_mesh(Vector3(4, 4, 4), metal_material)
	generator.position = Vector3(6, 2, 0)
	parent.add_child(generator)

func create_drill_rig(parent: Node3D):
	# Drill tower
	var tower = create_tower_mesh(Vector3(1, 12, 1), metal_material)
	tower.position = Vector3(0, 6, 0)
	parent.add_child(tower)
	
	# Drill platform
	var platform = create_building_mesh(Vector3(6, 1, 6), concrete_material)
	platform.position = Vector3(0, 0.5, 0)
	parent.add_child(platform)
	
	# Drill apparatus
	var drill = create_cylinder_mesh(0.5, 8, metal_material)
	drill.position = Vector3(0, -4, 0)
	parent.add_child(drill)

func create_conveyor_hub(parent: Node3D):
	# Central hub building
	var hub = create_building_mesh(Vector3(4, 4, 4), metal_material)
	hub.position = Vector3(0, 2, 0)
	parent.add_child(hub)
	
	# Conveyor supports radiating outward
	for i in range(8):
		var angle = i * PI / 4
		var pos = Vector3(cos(angle) * 6, 1, sin(angle) * 6)
		var support = create_tower_mesh(Vector3(0.3, 2, 0.3), metal_material)
		support.position = pos
		parent.add_child(support)

# Utility functions for creating building components
func create_building_mesh(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	return mesh_instance

func create_cylinder_mesh(radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = material
	return mesh_instance

func create_cone_mesh(radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = material
	return mesh_instance

func create_tower_mesh(size: Vector3, material: Material) -> MeshInstance3D:
	return create_building_mesh(size, material)

func create_ramp_mesh(size: Vector3, material: Material) -> MeshInstance3D:
	# Create a simple ramp using a rotated box
	var mesh_instance = create_building_mesh(size, material)
	mesh_instance.rotation.x = deg_to_rad(-15)
	return mesh_instance

func create_circular_mesh(radius: float, height: float, material: Material) -> MeshInstance3D:
	return create_cylinder_mesh(radius, height, material)

func create_pipe_network(parent: Node3D):
	# Create industrial pipe connections
	for i in range(3):
		var pipe = create_cylinder_mesh(0.2, 6, metal_material)
		pipe.rotation.z = deg_to_rad(90)
		pipe.position = Vector3(-3 + i * 3, 3, 1)
		parent.add_child(pipe)

func get_facility_at_position(position: Vector3) -> Dictionary:
	var facility_id = str(position)
	return facilities.get(facility_id, {})

func remove_facility(position: Vector3) -> bool:
	var facility_id = str(position)
	if facilities.has(facility_id):
		var facility_data = facilities[facility_id]
		facility_data.node.queue_free()
		facilities.erase(facility_id)
		return true
	return false

func process_materials(materials: Array) -> int:
	# Process materials at the processing plant
	var total_value = 0
	for material in materials:
		var material_data = GameManager.material_types.get(material, {})
		total_value += material_data.get("value", 1)
	
	material_processed.emit("mixed", total_value)
	return total_value

func get_facility_count() -> int:
	return facilities.size()

func get_operational_facilities() -> Array:
	var operational = []
	for facility_data in facilities.values():
		if facility_data.operational:
			operational.append(facility_data)
	return operational
