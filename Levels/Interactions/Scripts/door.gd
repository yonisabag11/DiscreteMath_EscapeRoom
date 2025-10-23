extends Area2D
class_name Door

# Represents a door that transports the player to another room/level

@export var destination_level_tag: String  # Which level to load (e.g., "Room1", "Lobby")
@export var destination_door_tag: String  # Which door in the destination to spawn at
@export var spawn_direction = "up"  # Direction the player should face after spawning

@onready var spawn = $Spawn  # The position where the player will appear at this door

# Called when the player walks into the door trigger area
func _on_body_entered(body: Node2D) -> void:
	if body is player_cat:
		# Use call_deferred to avoid physics callback issues
		call_deferred("_deferred_go_to_level")

# Handles the actual level transition (deferred to avoid physics timing issues)
func _deferred_go_to_level() -> void:
	# Tell NavigationManager which level and door to spawn at
	NavigationManager.spawn_door_tag = destination_door_tag  # Set which door to spawn at
	NavigationManager.go_to_level(destination_level_tag)  # Load the destination level
