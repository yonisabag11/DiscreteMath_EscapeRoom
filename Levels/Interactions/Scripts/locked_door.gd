extends StaticBody2D
class_name LockedDoor

# A door that requires interaction and can be locked/unlocked for escape room puzzles

@export var destination_level_tag: String  # Which level to load
@export var destination_door_tag: String  # Which door in destination to spawn at
@export var spawn_direction = "up"  # Direction player faces after spawning

@export var is_locked: bool = true  # Whether the door is currently locked
@export_multiline var locked_message: String = "This door is locked. I need to find a key..."
@export_multiline var unlocked_message: String = "The door creaks open..."
@export var required_item: String = ""  # Name of item needed to unlock (if using inventory system)

@onready var interaction_area = $InteractionArea

# Set up the interaction
func _ready():
	if interaction_area:
		interaction_area.interact = Callable(self, "_on_interact")
		if is_locked:
			interaction_area.action_name = "try door"
		else:
			interaction_area.action_name = "open"

# Called when player presses E near the door
func _on_interact():
	if is_locked:
		# Show locked message
		DialogBox.show_dialog(locked_message)
		await DialogBox.dialog_finished
		# Could add logic here to check for key in inventory
	else:
		# Show unlock message (optional)
		if unlocked_message != "":
			DialogBox.show_dialog(unlocked_message)
			await DialogBox.dialog_finished
		
		# Transport player to next room
		NavigationManager.spawn_door_tag = destination_door_tag
		NavigationManager.go_to_level(destination_level_tag)

# Call this function to unlock the door (from another script, like when player finds key)
func unlock():
	is_locked = false
	if interaction_area:
		interaction_area.action_name = "open"
	# Optional: play unlock sound, change sprite, etc.

