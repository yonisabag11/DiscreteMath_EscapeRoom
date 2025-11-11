extends Node

## Autoload singleton to manage player hearts/HP and update the HUD
## Add to Project Settings -> Autoload as "HealthManager"

signal hp_changed(current_hp: int, max_hp: int)
signal hearts_empty

@export var max_hp: int = 6  # 3 hearts x 2 HP each
var current_hp: int = max_hp

func _ready():
	_update_gui()

func reset_hearts():
	current_hp = max_hp
	_update_gui()

func will_lose_last_heart() -> bool:
	return current_hp <= 2

func lose_heart():
	# Lose one heart = 2 HP
	if current_hp <= 0:
		return
	current_hp = max(0, current_hp - 2)
	_update_gui()
	if current_hp <= 0:
		hearts_empty.emit()

func _update_gui():
	# Look for any node in the HUD group that implements update_hp
	if get_tree():
		var hud_nodes = get_tree().get_nodes_in_group("HUD")
		for hud in hud_nodes:
			if hud and hud.has_method("update_hp"):
				hud.update_hp(current_hp, max_hp)
				break
	hp_changed.emit(current_hp, max_hp)
