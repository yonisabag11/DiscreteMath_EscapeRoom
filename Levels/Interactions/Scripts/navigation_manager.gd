extends Node

# Manages scene transitions and player spawning between levels (autoload singleton)

signal on_trigger_player_spawn  # Signal emitted to tell the player where to spawn

var spawn_door_tag: String = ""  # The door where the player should spawn (set by Door, used by Level)

# Preload all level scenes for quick loading
const scene_Lobby = preload("res://Levels/Lobby.tscn")
const scene_Room1 = preload("res://Levels/Room1.tscn")
const scene_Room2 = preload("res://Levels/Room2.tscn")
const scene_Room3 = preload("res://Levels/Room3.tscn")

# Changes the current scene to the specified level
func go_to_level(level_tag: String) -> void:
	var scene_to_load
	# Match the level tag to the appropriate scene
	match level_tag:
		"Lobby":
			scene_to_load = scene_Lobby
		"Room1":
			scene_to_load = scene_Room1
		"Room2":
			scene_to_load = scene_Room2
		"Room3":
			scene_to_load = scene_Room3

	if scene_to_load != null:
		get_tree().change_scene_to_packed(scene_to_load)  # Load the new scene

# Emits a signal to spawn the player at a specific position and direction
func trigger_player_spawn(spawn_pos: Vector2, direction: String) -> void:
	emit_signal("on_trigger_player_spawn", spawn_pos, direction)  # Notify player to move
