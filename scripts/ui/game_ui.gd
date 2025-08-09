extends CanvasLayer

# Game UI - Main user interface controller
class_name GameUI

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

# UI Panels
@onready var left_sidebar: Panel = $LeftSidebar
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var upgrade_menu: Control = $UpgradeMenu
@onready var build_menu: Control = $BuildMenu
@onready var tutorial_panel: Control = $TutorialPanel

# Sidebar Elements - Dig n Rig style
@onready var elements_value: Label = $LeftSidebar/ElementsPanel/ElementsValue
@onready var health_bar: ProgressBar = $LeftSidebar/HealthBar
@onready var depth_label: Label = $LeftSidebar/DepthLabel
@onready var vac_pak_bar: ProgressBar = $LeftSidebar/VacPakPanel/VacPakBar
@onready var vac_pak_label: Label = $LeftSidebar/VacPakPanel/VacPakLabel
@onready var tool_grid: GridContainer = $LeftSidebar/DigToolsPanel/ToolGrid
@onready var item_grid: GridContainer = $LeftSidebar/ItemsPanel/ItemGrid

# Menu Elements
@onready var pause_resume_button: Button = $PauseMenu/ResumeButton
@onready var pause_settings_button: Button = $PauseMenu/SettingsButton
@onready var pause_quit_button: Button = $PauseMenu/QuitButton

@onready var game_over_restart_button: Button = $GameOverMenu/RestartButton
@onready var game_over_main_menu_button: Button = $GameOverMenu/MainMenuButton

@onready var upgrade_buttons: Array[Button] = []
@onready var upgrade_labels: Array[Label] = []

# Tutorial
@onready var tutorial_text: Label = $TutorialPanel/TutorialText
@onready var tutorial_next_button: Button = $TutorialPanel/NextButton

# Current state
var current_menu: String = ""
var tutorial_messages = [
	"Welcome to SideScroll3D! You control Diggit 6400, an advanced mining robot.",
	"Use WASD to move and SPACE to jump. The robot automatically mines materials it touches.",
	"Press B to enter build mode and place conveyor belts to transport materials.",
	"Materials are converted to Elements (currency) at the base. Use them for upgrades!",
	"Watch out for ferocious moles that patrol the underground tunnels.",
	"Dig deeper to find more valuable materials like gold, diamonds, and fossils.",
	"Build efficient conveyor systems to maximize your mining operation.",
	"Upgrade your robot's speed, mining efficiency, and health in the upgrade menu.",
	"Remember to save your progress regularly!",
	"Good luck, miner! The Earth's core awaits your discovery."
]

func _ready():
	setup_ui()
	connect_signals()
	update_hud()
	
	# Show tutorial if not completed
	if not GameManager.tutorial_completed:
		show_tutorial()

func setup_ui():
	# Setup HUD
	hud_panel.visible = true
	pause_menu.visible = false
	game_over_menu.visible = false
	upgrade_menu.visible = false
	build_menu.visible = false
	tutorial_panel.visible = false
	
	# Setup upgrade buttons
	setup_upgrade_buttons()
	
	# Setup build menu
	setup_build_menu()

func connect_signals():
	# Connect to game manager signals
	GameManager.elements_changed.connect(_on_elements_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.depth_changed.connect(_on_depth_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.tutorial_progress_changed.connect(_on_tutorial_progress_changed)
	
	# Connect button signals
	pause_resume_button.pressed.connect(_on_resume_pressed)
	pause_settings_button.pressed.connect(_on_settings_pressed)
	pause_quit_button.pressed.connect(_on_quit_pressed)
	
	game_over_restart_button.pressed.connect(_on_restart_pressed)
	game_over_main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	tutorial_next_button.pressed.connect(_on_tutorial_next_pressed)

func setup_upgrade_buttons():
	# Create upgrade buttons dynamically
	var upgrade_types = ["mining_speed", "movement_speed", "health", "conveyor_speed", "belt_length"]
	
	for i in range(upgrade_types.size()):
		var upgrade_type = upgrade_types[i]
		
		# Create button
		var button = Button.new()
		button.text = upgrade_type.replace("_", " ").capitalize()
		button.custom_minimum_size = Vector2(200, 50)
		button.position = Vector2(50, 100 + i * 60)
		button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_type))
		upgrade_menu.add_child(button)
		upgrade_buttons.append(button)
		
		# Create cost label
		var label = Label.new()
		label.text = "Cost: 10 Elements"
		label.position = Vector2(260, 100 + i * 60)
		upgrade_menu.add_child(label)
		upgrade_labels.append(label)

func setup_build_menu():
	# Create belt type buttons
	var belt_types = ["Straight", "Corner", "Elevator", "Junction"]
	
	for i in range(belt_types.size()):
		var button = Button.new()
		button.text = belt_types[i]
		button.custom_minimum_size = Vector2(150, 40)
		button.position = Vector2(50, 50 + i * 50)
		button.pressed.connect(_on_belt_button_pressed.bind(i))
		build_menu.add_child(button)

func update_hud():
	# Update elements
	elements_label.text = "Elements: " + str(GameManager.player_data.elements)
	
	# Update health bar
	var health_percent = float(GameManager.player_data.health) / float(GameManager.player_data.max_health)
	health_bar.value = health_percent * 100
	
	# Update depth
	depth_label.text = "Depth: " + str(int(GameManager.player_data.max_depth)) + "m"
	
	# Update materials mined
	materials_label.text = "Materials: " + str(GameManager.player_data.materials_mined)

func update_upgrade_buttons():
	for i in range(upgrade_buttons.size()):
		var upgrade_type = ["mining_speed", "movement_speed", "health", "conveyor_speed", "belt_length"][i]
		var current_level = GameManager.get_upgrade_level(upgrade_type)
		var cost = GameManager.get_upgrade_cost(upgrade_type)
		
		if cost == -1:
			upgrade_buttons[i].text = upgrade_type.replace("_", " ").capitalize() + " (MAX)"
			upgrade_buttons[i].disabled = true
			upgrade_labels[i].text = "Max Level"
		else:
			upgrade_buttons[i].text = upgrade_type.replace("_", " ").capitalize() + " (Lv " + str(current_level + 1) + ")"
			upgrade_buttons[i].disabled = cost > GameManager.player_data.elements
			upgrade_labels[i].text = "Cost: " + str(cost) + " Elements"

func show_menu(menu_name: String):
	hide_all_menus()
	
	match menu_name:
		"pause":
			pause_menu.visible = true
		"game_over":
			game_over_menu.visible = true
		"upgrade":
			upgrade_menu.visible = true
			update_upgrade_buttons()
		"build":
			build_menu.visible = true
	
	current_menu = menu_name
	menu_opened.emit(menu_name)

func hide_all_menus():
	pause_menu.visible = false
	game_over_menu.visible = false
	upgrade_menu.visible = false
	build_menu.visible = false
	tutorial_panel.visible = false
	current_menu = ""

func show_tutorial():
	tutorial_panel.visible = true
	update_tutorial_text()

func update_tutorial_text():
	if GameManager.tutorial_step < tutorial_messages.size():
		tutorial_text.text = tutorial_messages[GameManager.tutorial_step]
	else:
		tutorial_text.text = "Tutorial completed!"

func _on_elements_changed(new_amount: int):
	elements_label.text = "Elements: " + str(new_amount)
	update_upgrade_buttons()

func _on_health_changed(new_health: int):
	var health_percent = float(new_health) / float(GameManager.player_data.max_health)
	health_bar.value = health_percent * 100

func _on_depth_changed(new_depth: float):
	depth_label.text = "Depth: " + str(int(new_depth)) + "m"

func _on_game_state_changed(new_state: GameManager.GameState):
	match new_state:
		GameManager.GameState.PLAYING:
			hide_all_menus()
		GameManager.GameState.PAUSED:
			show_menu("pause")
		GameManager.GameState.GAME_OVER:
			show_menu("game_over")
		GameManager.GameState.BUILD_MODE:
			show_menu("build")

func _on_tutorial_progress_changed(step: int):
	update_tutorial_text()

func _on_resume_pressed():
	GameManager.change_game_state(GameManager.GameState.PLAYING)

func _on_settings_pressed():
	# TODO: Implement settings menu
	pass

func _on_quit_pressed():
	get_tree().quit()

func _on_restart_pressed():
	GameManager.restart_game()

func _on_main_menu_pressed():
	# TODO: Return to main menu
	GameManager.change_game_state(GameManager.GameState.MENU)

func _on_tutorial_next_pressed():
	GameManager.advance_tutorial()
	
	if GameManager.tutorial_completed:
		tutorial_panel.visible = false

func _on_upgrade_button_pressed(upgrade_type: String):
	if GameManager.purchase_upgrade(upgrade_type):
		update_upgrade_buttons()

func _on_belt_button_pressed(belt_type: int):
	# TODO: Implement belt placement
	pass

func _input(event):
	if event.is_action_pressed("pause") and current_menu == "pause":
		GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	if event.is_action_pressed("build_mode") and current_menu == "build":
		GameManager.change_game_state(GameManager.GameState.PLAYING)
