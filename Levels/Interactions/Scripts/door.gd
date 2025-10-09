extends Area2D
class_name Door

@export var destination_level_tag: String
@export var destination_door_tag: String
@export var spawn_direction = "up"

@onready var spawn = $Spawn

func _on_body_entered(body: Node2D) -> void:
	if body is player_cat:
		# Check velocity direction before triggering
		var vel = body.velocity if body.has_method("get_velocity") else body.velocity
		var should_trigger := false
		match spawn_direction:
			"up":
				should_trigger = vel.y < 0
			"down":
				should_trigger = vel.y > 0
			"left":
				should_trigger = vel.x < 0
			"right":
				should_trigger = vel.x > 0
			_:
				should_trigger = true # fallback: always trigger
		if should_trigger:
			# Store the player's facing direction before changing room
			NavigationManager.last_player_direction = _get_player_facing_direction(body)
			call_deferred("_deferred_go_to_level")

# Helper to get player's facing direction as string
func _get_player_facing_direction(player) -> String:
	var dir = player.velocity
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	elif abs(dir.y) > 0:
		return "down" if dir.y > 0 else "up"
	return spawn_direction

func _deferred_go_to_level() -> void:
	# Tell NavigationManager which level and door to spawn at
	NavigationManager.spawn_door_tag = destination_door_tag
	NavigationManager.go_to_level(destination_level_tag)
