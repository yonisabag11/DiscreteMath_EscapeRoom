extends CanvasLayer

# Manages the player's health HUD display using heart sprites

var hearts : Array[ HeartGUI ] = []  # Array of heart GUI elements


# Initialize the hearts array and set up initial display
func _ready():
	# Collect all HeartGUI children from the HFlowContainer
	for child in $Control/HFlowContainer.get_children():
		if child is HeartGUI:
			hearts.append( child )
			child.visible = false  # Hide hearts initially
	update_hp(6, 6)  # Show all hearts with full health



# Main function to update the health display
func update_hp(_hp: int, _max_hp: int) -> void:
	update_max_hp(_max_hp)  # Show/hide hearts based on max HP
	for i in range(hearts.size()):
		update_heart(i, _hp)  # Update each heart's appearance


# Updates a single heart's display (full, half, or empty)
func update_heart(_index: int, _hp: int) -> void:
	var _value: int = clampi(_hp - _index * 2, 0, 2)  # Calculate heart value (0-2)
	hearts[_index].value = _value  # Set the heart's sprite frame


# Shows or hides hearts based on the maximum health
func update_max_hp(_max_hp: int) -> void:
	var _heart_count: int = int(round(_max_hp * 0.5))  # Each heart = 2 HP
	for i in range(hearts.size()):
		hearts[i].visible = i < _heart_count  # Show only needed hearts
