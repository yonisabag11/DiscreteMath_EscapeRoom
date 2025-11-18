extends Area2D
class_name InteractionArea

# Represents an area that the player can interact with (doors, items, NPCs, etc.)

@export var action_name: String = "interact"  # Text shown in the interaction prompt (e.g., "open", "talk")
@export var label_offset_x: float = 0.0  # Horizontal offset for the interaction label
@export var label_offset_y: float = 0.0  # Vertical offset for the interaction label

var interact: Callable = func():  # Function to call when player presses E (set by parent object)
	pass

# Called when the player enters the interaction area
func _on_body_entered(_body: Node2D) -> void:
	InteractionManager.register_area(self)  # Add this area to the active interactions

# Called when the player leaves the interaction area
func _on_body_exited(_body: Node2D) -> void:
	InteractionManager.unregister_area(self)  # Remove this area from active interactions
