extends Control

# Tool Panel - Left-side industrial UI panel matching Dig n Rig style
class_name ToolPanel

signal tool_selected(tool_name: String)
signal inventory_slot_clicked(slot_index: int)

# Tool types
enum ToolType {
	DIG_TOOL,
	DRILL_RIG,
	CONVEYOR_BELT,
	VAC_PAK,
	SCANNER,
	EXPLOSIVES
}

# UI Elements
var tool_buttons: Array[Button] = []
var inventory_slots: Array[Button] = []
var element_display: Label
var materials_counter: Label
var depth_meter: Label
var status_panel: Panel

# Tool data
var tool_data = {
	ToolType.DIG_TOOL: {"name": "Dig Tool", "icon": null, "available": true},
	ToolType.DRILL_RIG: {"name": "Drill Rig", "icon": null, "available": false},
	ToolType.CONVEYOR_BELT: {"name": "Conveyor", "icon": null, "available": true},
	ToolType.VAC_PAK: {"name": "VAC PAK", "icon": null, "available": false},
	ToolType.SCANNER: {"name": "Scanner", "icon": null, "available": false},
	ToolType.EXPLOSIVES: {"name": "Explosives", "icon": null, "available": false}
}

var selected_tool: ToolType = ToolType.DIG_TOOL
var inventory_items: Array = []

func _ready():
	setup_panel_layout()
	apply_theme()
	connect_signals()
	update_displays()

func setup_panel_layout():
	# Set panel size and position (left side of screen)
	custom_minimum_size = Vector2(220, 600)
	anchors_preset = Control.PRESET_TOP_LEFT
	position = Vector2(10, 10)
	
	# Create main container
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	# Create elements display at top
	create_elements_display(main_vbox)
	
	# Create tool selection section
	create_tool_selection(main_vbox)
	
	# Create inventory section
	create_inventory_section(main_vbox)
	
	# Create status section
	create_status_section(main_vbox)
	
	# Create depth meter
	create_depth_meter(main_vbox)

func create_elements_display(parent: Container):
	var elements_panel = DigNRigTheme.create_tool_panel(Vector2(200, 60))
	parent.add_child(elements_panel)
	
	var elements_vbox = VBoxContainer.new()
	elements_vbox.position = Vector2(10, 5)
	elements_panel.add_child(elements_vbox)
	
	# Elements counter with industrial styling
	element_display = DigNRigTheme.create_status_label("Elements: 0", DigNRigTheme.TEXT_ACCENT)
	element_display.add_theme_font_size_override("font_size", 16)
	elements_vbox.add_child(element_display)
	
	# Materials mined counter
	materials_counter = DigNRigTheme.create_status_label("Mined: 0", DigNRigTheme.TEXT_NORMAL)
	materials_counter.add_theme_font_size_override("font_size", 12)
	elements_vbox.add_child(materials_counter)

func create_tool_selection(parent: Container):
	var tools_label = DigNRigTheme.create_status_label("TOOLS", DigNRigTheme.WARNING_COLOR)
	tools_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(tools_label)
	
	var tools_panel = DigNRigTheme.create_tool_panel(Vector2(200, 240))
	parent.add_child(tools_panel)
	
	var tools_grid = GridContainer.new()
	tools_grid.columns = 2
	tools_grid.add_theme_constant_override("h_separation", 4)
	tools_grid.add_theme_constant_override("v_separation", 4)
	tools_grid.position = Vector2(10, 10)
	tools_panel.add_child(tools_grid)
	
	# Create tool buttons
	for tool_type in ToolType.values():
		var button = create_tool_button(tool_type)
		tools_grid.add_child(button)
		tool_buttons.append(button)

func create_tool_button(tool_type: ToolType) -> Button:
	var tool_info = tool_data[tool_type]
	var button = DigNRigTheme.create_industrial_button(tool_info.name, Vector2(90, 35))
	
	# Customize button based on tool type
	match tool_type:
		ToolType.DIG_TOOL:
			button.modulate = Color(0.8, 1.0, 0.8)  # Green tint for active tool
		ToolType.CONVEYOR_BELT:
			button.modulate = Color(0.8, 0.8, 1.0)  # Blue tint
		_:
			if not tool_info.available:
				button.modulate = Color(0.5, 0.5, 0.5)  # Grayed out
				button.disabled = true
	
	button.pressed.connect(_on_tool_button_pressed.bind(tool_type))
	return button

func create_inventory_section(parent: Container):
	var inventory_label = DigNRigTheme.create_status_label("INVENTORY", DigNRigTheme.WARNING_COLOR)
	inventory_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(inventory_label)
	
	var inventory_panel = DigNRigTheme.create_tool_panel(Vector2(200, 160))
	parent.add_child(inventory_panel)
	
	var inventory_grid = GridContainer.new()
	inventory_grid.columns = 4
	inventory_grid.add_theme_constant_override("h_separation", 2)
	inventory_grid.add_theme_constant_override("v_separation", 2)
	inventory_grid.position = Vector2(10, 10)
	inventory_panel.add_child(inventory_grid)
	
	# Create inventory slots (4x3 grid = 12 slots)
	for i in range(12):
		var slot = DigNRigTheme.create_inventory_slot(Vector2(42, 42))
		slot.pressed.connect(_on_inventory_slot_clicked.bind(i))
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)

func create_status_section(parent: Container):
	var status_label = DigNRigTheme.create_status_label("STATUS", DigNRigTheme.WARNING_COLOR)
	status_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(status_label)
	
	status_panel = DigNRigTheme.create_tool_panel(Vector2(200, 80))
	parent.add_child(status_panel)
	
	var status_vbox = VBoxContainer.new()
	status_vbox.position = Vector2(10, 5)
	status_panel.add_child(status_vbox)
	
	# Health status
	var health_label = DigNRigTheme.create_status_label("Health: 100%", DigNRigTheme.SUCCESS_COLOR)
	health_label.add_theme_font_size_override("font_size", 12)
	status_vbox.add_child(health_label)
	
	# Robot status
	var robot_status = DigNRigTheme.create_status_label("Robot: Online", DigNRigTheme.SUCCESS_COLOR)
	robot_status.add_theme_font_size_override("font_size", 12)
	status_vbox.add_child(robot_status)

func create_depth_meter(parent: Container):
	var depth_label_header = DigNRigTheme.create_status_label("DEPTH", DigNRigTheme.WARNING_COLOR)
	depth_label_header.add_theme_font_size_override("font_size", 14)
	parent.add_child(depth_label_header)
	
	var depth_panel = DigNRigTheme.create_tool_panel(Vector2(200, 50))
	parent.add_child(depth_panel)
	
	depth_meter = DigNRigTheme.create_status_label("0m", DigNRigTheme.TEXT_ACCENT)
	depth_meter.add_theme_font_size_override("font_size", 18)
	depth_meter.position = Vector2(10, 15)
	depth_panel.add_child(depth_meter)

func apply_theme():
	# Apply the industrial theme to the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DigNRigTheme.PANEL_DARK
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = DigNRigTheme.WARNING_COLOR
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	
	add_theme_stylebox_override("panel", panel_style)

func connect_signals():
	# Connect to game manager signals
	GameManager.elements_changed.connect(_on_elements_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.depth_changed.connect(_on_depth_changed)

func update_displays():
	# Update all display elements
	_on_elements_changed(GameManager.player_data.elements)
	_on_health_changed(GameManager.player_data.health)
	_on_depth_changed(GameManager.player_data.max_depth)

func _on_tool_button_pressed(tool_type: ToolType):
	if tool_data[tool_type].available:
		selected_tool = tool_type
		tool_selected.emit(tool_data[tool_type].name)
		update_tool_selection_visual()

func _on_inventory_slot_clicked(slot_index: int):
	inventory_slot_clicked.emit(slot_index)
	print("Inventory slot clicked: ", slot_index)

func _on_elements_changed(new_amount: int):
	element_display.text = "Elements: " + str(new_amount)

func _on_health_changed(new_health: int):
	var health_percent = int((float(new_health) / float(GameManager.player_data.max_health)) * 100)
	var health_label = status_panel.get_child(0).get_child(0)
	health_label.text = "Health: " + str(health_percent) + "%"
	
	# Change color based on health
	if health_percent > 60:
		health_label.add_theme_color_override("font_color", DigNRigTheme.SUCCESS_COLOR)
	elif health_percent > 30:
		health_label.add_theme_color_override("font_color", DigNRigTheme.WARNING_COLOR)
	else:
		health_label.add_theme_color_override("font_color", DigNRigTheme.DANGER_COLOR)

func _on_depth_changed(new_depth: float):
	depth_meter.text = str(int(new_depth)) + "m"
	materials_counter.text = "Mined: " + str(GameManager.player_data.materials_mined)

func update_tool_selection_visual():
	# Update visual state of tool buttons
	for i in range(tool_buttons.size()):
		var button = tool_buttons[i]
		if i == selected_tool:
			button.modulate = Color(1.0, 1.0, 0.8)  # Highlight selected tool
		else:
			var tool_info = tool_data[i]
			if tool_info.available:
				match i:
					ToolType.DIG_TOOL:
						button.modulate = Color(0.8, 1.0, 0.8)
					ToolType.CONVEYOR_BELT:
						button.modulate = Color(0.8, 0.8, 1.0)
					_:
						button.modulate = Color(1.0, 1.0, 1.0)
			else:
				button.modulate = Color(0.5, 0.5, 0.5)

func unlock_tool(tool_type: ToolType):
	tool_data[tool_type].available = true
	tool_buttons[tool_type].disabled = false
	update_tool_selection_visual()

func add_inventory_item(item_name: String, icon_texture: Texture2D = null):
	# Find first empty slot
	for i in range(inventory_slots.size()):
		if inventory_items.size() <= i or inventory_items[i] == null:
			if inventory_items.size() <= i:
				inventory_items.resize(i + 1)
			inventory_items[i] = item_name
			
			# Update slot visual
			var slot = inventory_slots[i]
			if icon_texture:
				slot.icon = icon_texture
			else:
				slot.text = item_name.substr(0, 2).to_upper()  # Show first 2 letters
			break

func get_selected_tool() -> ToolType:
	return selected_tool

func is_tool_available(tool_type: ToolType) -> bool:
	return tool_data[tool_type].available
