extends Camera3D

# Side-scrolling Camera for Dig n Rig style gameplay
class_name SideScrollCamera

@export var follow_target: Node3D
@export var follow_speed: float = 0.1
@export var offset: Vector3 = Vector3(15, 5, 0)
@export var camera_bounds: Rect2 = Rect2(-100, -200, 200, 400)  # X, Y bounds

var initial_position: Vector3

func _ready():
	initial_position = global_position
	
	# Set orthogonal projection for side-scrolling feel
	projection = PROJECTION_ORTHOGONAL
	size = 20
	
	# Find player if not set
	if not follow_target:
		follow_target = get_node("../Player")

func _process(delta):
	if follow_target:
		update_camera_position()

func update_camera_position():
	var target_pos = follow_target.global_position + offset
	
	# Clamp camera within bounds
	target_pos.x = clamp(target_pos.x, camera_bounds.position.x, camera_bounds.position.x + camera_bounds.size.x)
	target_pos.y = clamp(target_pos.y, camera_bounds.position.y, camera_bounds.position.y + camera_bounds.size.y)
	target_pos.z = 0  # Fixed Z for side-scrolling
	
	# Smooth follow
	global_position = global_position.lerp(target_pos, follow_speed)

func set_follow_target(target: Node3D):
	follow_target = target

func set_camera_bounds(bounds: Rect2):
	camera_bounds = bounds