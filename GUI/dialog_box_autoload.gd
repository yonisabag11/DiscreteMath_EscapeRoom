extends Node

# Autoload singleton for managing dialog boxes in the escape room
# This is a pure script autoload that creates UI on demand

var dialog_scene: PackedScene = preload("res://GUI/dialog_box.tscn")
var dialog_instance: CanvasLayer = null

var is_displaying: bool = false
signal dialog_finished

func _ready():
	# Create the dialog UI and add it to the tree
	dialog_instance = CanvasLayer.new()
	add_child(dialog_instance)
	
	# Create the UI elements
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(0, 100)  # Start with minimum height
	panel.offset_top = -100
	dialog_instance.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.custom_minimum_size = Vector2(0, 50)  # Minimum height for short text
	# Let the text label expand to fill available vertical space inside the VBoxContainer.
	# This ensures the continue label stays in a fixed position at the bottom regardless of text length.
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.scroll_following = true
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Add font
	var font = load("res://GUI/Font/PressStart2P-Regular.ttf")
	text_label.add_theme_font_override("normal_font", font)
	text_label.add_theme_font_size_override("normal_font_size", 8)
	text_label.name = "TextLabel"  # Name it so we can find it later
	vbox.add_child(text_label)
	
	var continue_label = Label.new()
	continue_label.text = "[Space] to continue..."
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.add_theme_font_override("font", font)
	continue_label.add_theme_font_size_override("font_size", 6)
	vbox.add_child(continue_label)
	
	# Store references
	set_meta("panel", panel)
	set_meta("text_label", text_label)
	
	# Hide initially
	panel.hide()

func show_dialog(text: String, position: Vector2 = Vector2(-1, -1)):
	var panel = get_meta("panel")
	var text_label = get_meta("text_label")
	
	# Freeze player movement
	var player = get_tree().get_first_node_in_group("player_cat")
	if player and player.has_method("freeze"):
		player.freeze()
	
	text_label.text = text
	
	# Calculate dynamic height based on text content
	# Wait one frame for the text to be processed
	await get_tree().process_frame
	
	# Get the content height from the text label
	var content_height = text_label.get_content_height()
	
	# Add margins and continue label (approximately 60px total for margins and continue button)
	var total_height = content_height + 60
	
	# Clamp between minimum (100) and maximum (400) to keep it reasonable
	total_height = clamp(total_height, 100, 400)
	
	# If custom position is provided (not -1, -1), use it
	if position != Vector2(-1, -1):
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.position = position
		panel.offset_top = 0
		panel.offset_bottom = 0
		panel.offset_left = 0
		panel.offset_right = 0
		panel.size = Vector2(400, total_height)  # Dynamic size for custom positioned dialogs
	else:
		# Default bottom position
		panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		panel.custom_minimum_size = Vector2(0, total_height)
		panel.offset_top = -total_height
		panel.offset_bottom = 0
		panel.offset_left = 0
		panel.offset_right = 0
	
	panel.show()
	is_displaying = true

func hide_dialog():
	var panel = get_meta("panel")
	panel.hide()
	is_displaying = false
	
	# Unfreeze player movement
	var player = get_tree().get_first_node_in_group("player_cat")
	if player and player.has_method("unfreeze"):
		player.unfreeze()
	
	dialog_finished.emit()

func _input(event):
	if is_displaying and event.is_action_pressed("ui_accept"):
		hide_dialog()
