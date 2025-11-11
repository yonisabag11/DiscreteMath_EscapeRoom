extends Node2D

# Manages all interactive areas in the game and displays interaction prompts

@onready var player = get_tree().get_first_node_in_group("player_cat")  # Reference to player
@onready var label = $Label  # The "[E] to interact" label

const base_text = "[E] to "  # Base text for interaction prompts

var active_areas = []  # List of interaction areas the player is currently near
var can_interact = true  # Whether the player can currently interact (prevents spam)

# Public function to force re-enable interactions (useful for debugging or after mini-games)
func enable_interaction():
	can_interact = true
	print("InteractionManager: Interactions manually enabled")

# Set up the label styling
func _ready():
	var font = load("res://GUI/Font/PressStart2P-Regular.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 4)

# Add an interaction area to the active list when player enters it
func register_area(area: InteractionArea):
	active_areas.push_back(area)

# Remove an interaction area from the active list when player exits it
func unregister_area(area: InteractionArea):
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)

# Update the interaction label position and text every frame
func _process(delta):
	if active_areas.size() > 0 and can_interact:
		active_areas.sort_custom(_sort_by_distance_to_player)  # Sort by closest first
		var area = active_areas[0]  # Get the closest interaction area
		label.text = base_text + area.action_name  # Update label text (e.g., "[E] to open")

		# Position the label above the interaction area
		var collision_shape = area.get_node("CollisionShape2D")
		if collision_shape and collision_shape.shape:
			var shape = collision_shape.shape
			var shape_height = 0
			# Calculate shape height based on type
			if shape is RectangleShape2D:
				shape_height = shape.extents.y * 2
			elif shape is CapsuleShape2D:
				shape_height = shape.height
			elif shape is CircleShape2D:
				shape_height = shape.radius * 2

			# Apply custom offset and position label
			label.global_position = collision_shape.global_position
			label.global_position.x += area.label_offset_x - (label.size.x / 2)
			label.global_position.y += area.label_offset_y + (shape_height / 2) - 10
		else:
			label.global_position = area.global_position + Vector2(area.label_offset_x, area.label_offset_y)

		label.show()  # Display the label
	else:
		label.hide()  # Hide label if no active areas or can't interact

# Sorting function to find the closest interaction area to the player
func _sort_by_distance_to_player(area1, area2):
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	return area1_to_player < area2_to_player	

# Handle interaction input (E key)
func _input(event):
	if event.is_action_pressed("Interact") and can_interact:
		if active_areas.size() > 0:
			get_viewport().set_input_as_handled()  # Consume the input
			can_interact = false  # Disable interaction temporarily
			label.hide()  # Hide the label
			await active_areas[0].interact.call()  # Execute the interaction
			can_interact = true  # Re-enable interaction
			print("Interaction completed, can_interact set to true")
