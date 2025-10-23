extends Node

# Handles spawning the player at the correct location when a level loads

# Called when the level is first loaded
func _ready():
	# Only attempt to spawn if spawn_door_tag exists (coming from another room)
	if NavigationManager.spawn_door_tag != "":
		# Defer spawn to ensure all doors exist in the scene tree
		call_deferred("_on_level_spawn", NavigationManager.spawn_door_tag)

# Spawns the player at the specified door's spawn point
func _on_level_spawn(destination_tag: String) -> void:
	var door_path = "Doors/Door_" + destination_tag  # Build the door node path
	if not has_node(door_path):
		push_warning("Door not found: " + door_path)  # Log error if door doesn't exist
		return

	var door = get_node(door_path) as Door  # Get the door node
	NavigationManager.trigger_player_spawn(door.spawn.global_position, door.spawn_direction)  # Spawn player

	# Clear the tag so next scene doesn't reuse it
	NavigationManager.spawn_door_tag = ""
