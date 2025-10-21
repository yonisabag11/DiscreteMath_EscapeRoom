extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"
@export var label_offset_x: float = 0.0
@export var label_offset_y: float = 0.0

var interact: Callable = func():
	pass

func _on_body_entered(body: Node2D) -> void:
	InteractionManager.register_area(self)

func _on_body_exited(body: Node2D) -> void:
	InteractionManager.unregister_area(self)
