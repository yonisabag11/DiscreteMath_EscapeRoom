extends Node

func _ready():
	# Only attempt to spawn if spawn_door_tag exists
	if NavigationManager.spawn_door_tag != "":
		# Defer spawn to ensure all doors exist
		call_deferred("_on_level_spawn", NavigationManager.spawn_door_tag)

func _on_level_spawn(destination_tag: String) -> void:
	var door_path = "Doors/Door_" + destination_tag
	if not has_node(door_path):
		push_warning("Door not found: " + door_path)
		return

	var door = get_node(door_path) as Door
	NavigationManager.trigger_player_spawn(door.spawn.global_position, door.spawn_direction)

	# Clear the tag so next scene doesn’t reuse it
	NavigationManager.spawn_door_tag = ""
