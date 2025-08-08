extends Node

# Test script to verify project setup
func _ready():
	print("SideScroll3D Project Test")
	print("=========================")
	
	# Test autoloads
	if GameManager:
		print("✓ GameManager autoload found")
	else:
		print("✗ GameManager autoload missing")
	
	if AudioManager:
		print("✓ AudioManager autoload found")
	else:
		print("✗ AudioManager autoload missing")
	
	if SaveManager:
		print("✓ SaveManager autoload found")
	else:
		print("✗ SaveManager autoload missing")
	
	# Test project structure
	var dir = DirAccess.open("res://")
	if dir:
		print("✓ Project directory accessible")
		
		# Check for required directories
		var required_dirs = ["scripts", "scenes", "assets"]
		for dir_name in required_dirs:
			if dir.dir_exists(dir_name):
				print("✓ Directory found: " + dir_name)
			else:
				print("✗ Directory missing: " + dir_name)
		
		# Check for required script files
		var required_scripts = [
			"scripts/autoload/game_manager.gd",
			"scripts/autoload/audio_manager.gd", 
			"scripts/autoload/save_manager.gd",
			"scripts/player/player_controller.gd",
			"scripts/terrain/terrain_system.gd",
			"scripts/conveyor/conveyor_system.gd",
			"scripts/materials/material_drop.gd",
			"scripts/enemies/mole_enemy.gd",
			"scripts/enemies/enemy_manager.gd",
			"scripts/ui/game_ui.gd",
			"scripts/main_game.gd"
		]
		
		for script_path in required_scripts:
			if FileAccess.file_exists("res://" + script_path):
				print("✓ Script found: " + script_path)
			else:
				print("✗ Script missing: " + script_path)
		
		# Check for scene files
		var required_scenes = [
			"scenes/main_game.tscn",
			"scenes/materials/material_drop.tscn",
			"scenes/enemies/mole_enemy.tscn"
		]
		
		for scene_path in required_scenes:
			if FileAccess.file_exists("res://" + scene_path):
				print("✓ Scene found: " + scene_path)
			else:
				print("✗ Scene missing: " + scene_path)
	else:
		print("✗ Cannot access project directory")
	
	print("\nProject Test Complete!")
	print("If all checks passed, the project should be ready to run in Godot 4.4.1")
