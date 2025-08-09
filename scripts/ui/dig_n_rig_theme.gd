extends Resource

# Dig n Rig Authentic UI Theme
class_name DigNRigTheme

# Color Palette (based on reference images)
const PANEL_DARK = Color(0.15, 0.15, 0.2, 0.95)
const PANEL_LIGHT = Color(0.25, 0.25, 0.3, 0.9)
const BUTTON_NORMAL = Color(0.2, 0.3, 0.5, 1.0)
const BUTTON_HOVER = Color(0.3, 0.4, 0.6, 1.0)
const BUTTON_PRESSED = Color(0.1, 0.2, 0.4, 1.0)
const TEXT_NORMAL = Color(0.9, 0.9, 0.95, 1.0)
const TEXT_ACCENT = Color(0.4, 0.8, 1.0, 1.0)
const WARNING_COLOR = Color(1.0, 0.6, 0.0, 1.0)
const SUCCESS_COLOR = Color(0.2, 0.8, 0.2, 1.0)
const DANGER_COLOR = Color(0.9, 0.2, 0.2, 1.0)

# Create the complete theme
static func create_theme() -> Theme:
	var theme = Theme.new()
	
	# Create fonts
	var main_font = create_main_font()
	var small_font = create_small_font()
	var large_font = create_large_font()
	
	# Setup button styles
	setup_button_styles(theme, main_font)
	
	# Setup panel styles
	setup_panel_styles(theme)
	
	# Setup label styles
	setup_label_styles(theme, main_font, small_font, large_font)
	
	# Setup progress bar styles
	setup_progress_bar_styles(theme)
	
	# Setup line edit styles
	setup_line_edit_styles(theme, main_font)
	
	return theme

static func create_main_font() -> Font:
	# In a real implementation, load a retro/industrial font
	# For now, use default font with styling
	var font = SystemFont.new()
	font.font_names = ["Courier", "Consolas", "monospace"]
	return font

static func create_small_font() -> Font:
	var font = create_main_font()
	return font

static func create_large_font() -> Font:
	var font = create_main_font()
	return font

static func setup_button_styles(theme: Theme, font: Font):
	# Normal button style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = BUTTON_NORMAL
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = TEXT_NORMAL
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	# Hover button style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = BUTTON_HOVER
	hover_style.border_color = TEXT_ACCENT
	
	# Pressed button style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = BUTTON_PRESSED
	pressed_style.border_color = WARNING_COLOR
	
	# Apply to theme
	theme.set_stylebox("normal", "Button", normal_style)
	theme.set_stylebox("hover", "Button", hover_style)
	theme.set_stylebox("pressed", "Button", pressed_style)
	theme.set_font("font", "Button", font)
	theme.set_font_size("font_size", "Button", 14)
	theme.set_color("font_color", "Button", TEXT_NORMAL)
	theme.set_color("font_hover_color", "Button", TEXT_ACCENT)

static func setup_panel_styles(theme: Theme):
	# Main panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = PANEL_DARK
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = TEXT_NORMAL
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	
	# Light panel variant
	var light_panel = panel_style.duplicate()
	light_panel.bg_color = PANEL_LIGHT
	
	theme.set_stylebox("panel", "Panel", panel_style)
	theme.set_stylebox("panel", "PanelContainer", light_panel)

static func setup_label_styles(theme: Theme, main_font: Font, small_font: Font, large_font: Font):
	# Normal label
	theme.set_font("font", "Label", main_font)
	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("font_color", "Label", TEXT_NORMAL)
	
	# Create custom label variants
	var accent_label = theme.duplicate()
	theme.set_color("font_color", "AccentLabel", TEXT_ACCENT)
	
	var warning_label = theme.duplicate()
	theme.set_color("font_color", "WarningLabel", WARNING_COLOR)

static func setup_progress_bar_styles(theme: Theme):
	# Progress bar background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = PANEL_DARK
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = TEXT_NORMAL
	
	# Progress bar fill
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = SUCCESS_COLOR
	fill_style.border_width_left = 1
	fill_style.border_width_right = 1
	fill_style.border_width_top = 1
	fill_style.border_width_bottom = 1
	fill_style.border_color = TEXT_ACCENT
	
	theme.set_stylebox("background", "ProgressBar", bg_style)
	theme.set_stylebox("fill", "ProgressBar", fill_style)

static func setup_line_edit_styles(theme: Theme, font: Font):
	# Line edit style
	var edit_style = StyleBoxFlat.new()
	edit_style.bg_color = PANEL_LIGHT
	edit_style.border_width_left = 2
	edit_style.border_width_right = 2
	edit_style.border_width_top = 2
	edit_style.border_width_bottom = 2
	edit_style.border_color = TEXT_NORMAL
	edit_style.corner_radius_top_left = 4
	edit_style.corner_radius_top_right = 4
	edit_style.corner_radius_bottom_left = 4
	edit_style.corner_radius_bottom_right = 4
	
	var focus_style = edit_style.duplicate()
	focus_style.border_color = TEXT_ACCENT
	
	theme.set_stylebox("normal", "LineEdit", edit_style)
	theme.set_stylebox("focus", "LineEdit", focus_style)
	theme.set_font("font", "LineEdit", font)
	theme.set_font_size("font_size", "LineEdit", 14)
	theme.set_color("font_color", "LineEdit", TEXT_NORMAL)

# Utility functions for custom UI elements
static func create_industrial_button(text: String, size: Vector2 = Vector2(120, 40)) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = size
	
	# Apply custom styling
	var style = StyleBoxFlat.new()
	style.bg_color = BUTTON_NORMAL
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = TEXT_NORMAL
	button.add_theme_stylebox_override("normal", style)
	
	return button

static func create_tool_panel(size: Vector2 = Vector2(200, 400)) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = size
	
	# Apply industrial panel style
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_DARK
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = WARNING_COLOR
	panel.add_theme_stylebox_override("panel", style)
	
	return panel

static func create_status_label(text: String, color: Color = TEXT_NORMAL) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label

static func create_inventory_slot(size: Vector2 = Vector2(48, 48)) -> Button:
	var slot = Button.new()
	slot.custom_minimum_size = size
	
	# Inventory slot style
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_LIGHT
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = TEXT_NORMAL
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	
	slot.add_theme_stylebox_override("normal", style)
	
	return slot
