extends CharacterBody2D
class_name player_cat

@export var move_speed: float = 100
@export var starting_direction: Vector2 = Vector2(0, 1)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

func _ready() -> void:
	update_animation_parameters(starting_direction)
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)

func _on_spawn(spawn_pos: Vector2, direction: String) -> void:
	global_position = spawn_pos

	# Set animation state and facing direction
	state_machine.travel("Idle")  # Start in Idle
	animation_tree.set("parameters/Idle/blend_position", _vector_from_direction(direction))

func _physics_process(_delta: float) -> void:
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)

	update_animation_parameters(input_direction)

	velocity = input_direction * move_speed
	move_and_slide()
	pick_new_state()

func update_animation_parameters(move_input: Vector2) -> void:
	if move_input != Vector2.ZERO:
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Idle/blend_position", move_input)

func pick_new_state() -> void:
	if velocity != Vector2.ZERO:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

# Helper function to convert "up"/"down"/"left"/"right" to Vector2
func _vector_from_direction(dir: String) -> Vector2:
	match dir:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
	return Vector2(0, 1)
