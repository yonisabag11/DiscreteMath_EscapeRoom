extends Node2D

@onready var player = get_tree().get_first_node_in_group("player_cat")
@onready var label = $Label

const base_text = "[E] to "

var active_areas = []
var can_interact = true

func _ready():
	var font = load("res://GUI/Font/PressStart2P-Regular.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 4)

func register_area(area: InteractionArea):
	active_areas.push_back(area)

func unregister_area(area: InteractionArea):
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)

func _process(delta):
	if active_areas.size() > 0 and can_interact:
		active_areas.sort_custom(_sort_by_distance_to_player)
		label.text = base_text + active_areas[0].action_name

		var area = active_areas[0]
		var collision_shape = area.get_node("CollisionShape2D")
		if collision_shape and collision_shape.shape:
			var shape = collision_shape.shape
			var shape_height = 0
			if shape is RectangleShape2D:
				shape_height = shape.extents.y * 2
			elif shape is CapsuleShape2D:
				shape_height = shape.height
			elif shape is CircleShape2D:
				shape_height = shape.radius * 2
			# Add other shape types as needed

			label.global_position = collision_shape.global_position
			label.global_position.y += shape_height / 2 - 10
			label.global_position.x -= label.size.x / 2
		else:
			label.global_position = area.global_position
		label.show()
	else:
		label.hide()

func _sort_by_distance_to_player(area1, area2):
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	return area1_to_player < area2_to_player	

func _input(event):
	if event.is_action_pressed("Interact") and can_interact:
		if active_areas.size() > 0:
			can_interact = false
			label.hide()
			await active_areas[0].interact.call()
			can_interact = true
