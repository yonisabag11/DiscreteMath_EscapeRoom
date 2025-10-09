extends Area2D
class_name Door

@export var destination_level_tag: String
@export var destination_door_tag: String
@export var spawn_direction = "up"

@onready var spawn = $Spawn

func _on_body_entered(body: Node2D) -> void:
	if body is player_cat:
		# Use call_deferred to avoid physics callback issues
		call_deferred("_deferred_go_to_level")

func _deferred_go_to_level() -> void:
	# Tell NavigationManager which level and door to spawn at
	NavigationManager.spawn_door_tag = destination_door_tag
	NavigationManager.go_to_level(destination_level_tag)
