extends Node

signal on_trigger_player_spawn

var spawn_door_tag: String = ""  # The door where the player should spawn

const scene_Lobby = preload("res://Levels/Lobby.tscn")
const scene_Room1 = preload("res://Levels/Room1.tscn")

func go_to_level(level_tag: String) -> void:
	var scene_to_load
	match level_tag:
		"Lobby":
			scene_to_load = scene_Lobby
		"Room1":
			scene_to_load = scene_Room1

	if scene_to_load != null:
		get_tree().change_scene_to_packed(scene_to_load)

func trigger_player_spawn(spawn_pos: Vector2, direction: String) -> void:
	emit_signal("on_trigger_player_spawn", spawn_pos, direction)
