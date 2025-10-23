class_name HeartGUI extends Control

# Represents a single heart in the health UI (can show full, half, or empty)

@onready var sprite = $Sprite2D  # Reference to the sprite displaying the heart

# The heart's current value (0 = empty, 1 = half, 2 = full)
var value : int = 2 : 
	set( _value ) :
		value = _value
		update_sprite()  # Automatically update the sprite when value changes



# Updates the sprite frame to match the current heart value
func update_sprite() -> void:
	sprite.frame = value  # Frame 0 = empty, 1 = half, 2 = full
	
