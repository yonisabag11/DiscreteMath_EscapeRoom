extends StaticBody2D
class_name InteractableObject

# An object that shows a dialog when the player interacts with it
# Perfect for clues, notes, puzzles, or locked items in your escape room

@export_multiline var dialog_text: String = "This is a mysterious object..."  # The text to display
@export var one_time_only: bool = false  # If true, can only be interacted with once
@export var interaction_label: String = "examine"  # What shows in the [E] prompt
@export_group("Interaction Prompt Position")
@export var prompt_offset: Vector2 = Vector2(0, 0)  # Offset for the "[E] to examine" text position
@export_group("Dialog Position")
@export var custom_position: bool = false  # Enable custom position for dialog
@export var dialog_position: Vector2 = Vector2(0, 0)  # Custom position offset from default

var has_been_used: bool = false

@onready var interaction_area = $InteractionArea

# Set up the interaction when the scene loads
func _ready():
	if interaction_area:
		interaction_area.interact = Callable(self, "_on_interact")
		interaction_area.action_name = interaction_label
		# Apply custom prompt position offset
		interaction_area.label_offset_x = prompt_offset.x
		interaction_area.label_offset_y = prompt_offset.y

# Called when the player presses E near this object
func _on_interact():
	# Check if it's one-time only and already used
	if one_time_only and has_been_used:
		return
	
	# Show the dialog box with the text
	if custom_position:
		DialogBox.show_dialog(dialog_text, dialog_position)
	else:
		DialogBox.show_dialog(dialog_text)
	
	# Wait for the dialog to finish
	await DialogBox.dialog_finished
	
	# Mark as used if one-time only
	if one_time_only:
		has_been_used = true
		# Optionally change appearance or disable interaction
		if interaction_area:
			interaction_area.action_name = "already examined"
	
	# You can add custom logic here, like:
	# - Giving the player an item
	# - Unlocking a door
	# - Playing a sound effect
	# - Changing the sprite
