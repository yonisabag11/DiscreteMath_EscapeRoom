extends CharacterBody2D
class_name player_cat

# Movement and stats configuration
@export var move_speed: float = 100  # Player movement speed in pixels per second
@export var starting_direction: Vector2 = Vector2(0, 1)  # Initial facing direction (down)
@export var max_hp: int = 6  # Maximum health points
var current_hp: int = max_hp  # Current health points

# Movement control
var can_move: bool = true  # Controls whether the player can move

# References to player's animation system and GUI
@onready var animation_tree = $AnimationTree  # Controls sprite animations
@onready var state_machine = animation_tree.get("parameters/playback")  # Manages animation states
@onready var gui = get_tree().root.get_node("/GUI")  # Reference to the health GUI

# Called when the player is added to the scene
func _ready() -> void:
	update_animation_parameters(starting_direction)  # Set initial animation direction
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)  # Listen for room transitions

# Handles spawning the player at a specific position and direction when changing rooms
func _on_spawn(spawn_pos: Vector2, direction: String) -> void:
	global_position = spawn_pos  # Move player to spawn point

	# Set animation state and facing direction
	state_machine.travel("Idle")  # Start in Idle animation
	animation_tree.set("parameters/Idle/blend_position", _vector_from_direction(direction))  # Face correct direction

# Called every physics frame (60 times per second) - handles movement
func _physics_process(_delta: float) -> void:
	# Don't process movement if player can't move
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		pick_new_state()
		return
	
	# Get player input from WASD/arrow keys
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)

	update_animation_parameters(input_direction)  # Update sprite direction

	velocity = input_direction * move_speed  # Calculate movement velocity
	move_and_slide()  # Move the player and handle collisions
	pick_new_state()  # Update animation state (Walk or Idle)

# Updates the animation blend positions based on movement direction
func update_animation_parameters(move_input: Vector2) -> void:
	if move_input != Vector2.ZERO:
		animation_tree.set("parameters/Walk/blend_position", move_input)  # Set walking direction
		animation_tree.set("parameters/Idle/blend_position", move_input)  # Set idle facing direction

# Determines whether to play Walk or Idle animation based on movement
func pick_new_state() -> void:
	if velocity != Vector2.ZERO:
		state_machine.travel("Walk")  # Play walk animation if moving
	else:
		state_machine.travel("Idle")  # Play idle animation if stationary

# Helper function to convert "up"/"down"/"left"/"right" to Vector2
func _vector_from_direction(dir: String) -> Vector2:
	match dir:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
	return Vector2(0, 1)  # Default to down if invalid direction

# Reduces player health and updates the GUI
func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)  # Decrease HP, minimum 0
	gui.update_hp(current_hp, max_hp)  # Update health display

# Freeze player movement (called during dialogs/minigames)
func freeze():
	can_move = false
	velocity = Vector2.ZERO
	print("Player frozen")

# Unfreeze player movement
func unfreeze():
	can_move = true
	print("Player unfrozen")
