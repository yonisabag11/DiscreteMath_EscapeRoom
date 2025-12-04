extends Node

## Autoload singleton to manage player hearts/HP and update the HUD
## Add to Project Settings -> Autoload as "HealthManager"
## Each heart represents 2 HP, so 3 hearts = 6 max HP

signal hp_changed(current_hp: int, max_hp: int)  # Emitted when player's HP changes
signal hearts_empty  # Emitted when player loses all hearts (game over condition)

@export var max_hp: int = 6  # 3 hearts x 2 HP each
var current_hp: int = max_hp  # Current HP - starts at maximum

## Initialize the HUD display when the health manager loads
func _ready():
	_update_gui()

## Reset hearts to maximum HP (call when restarting game)
func reset_hearts():
	current_hp = max_hp
	_update_gui()

## Check if the player will lose their last heart with the next hit
## Returns true if current HP is 2 or less (1 heart remaining)
func will_lose_last_heart() -> bool:
	return current_hp <= 2

## Deduct one heart (2 HP) from the player
## Emits hearts_empty signal if player loses all HP
func lose_heart():
	# Lose one heart = 2 HP
	if current_hp <= 0:
		return  # Already at 0 HP, can't lose more
	current_hp = max(0, current_hp - 2)  # Reduce HP by 2, but don't go below 0
	_update_gui()
	if current_hp <= 0:
		hearts_empty.emit()  # Notify that player has no hearts left

## Update the HUD display to reflect current HP
## Searches for any node in the "HUD" group that has an update_hp method
func _update_gui():
	# Look for any node in the HUD group that implements update_hp
	if get_tree():
		var hud_nodes = get_tree().get_nodes_in_group("HUD")
		for hud in hud_nodes:
			if hud and hud.has_method("update_hp"):
				hud.update_hp(current_hp, max_hp)
				break  # Only update the first valid HUD node
	hp_changed.emit(current_hp, max_hp)  # Notify any listeners of HP change
