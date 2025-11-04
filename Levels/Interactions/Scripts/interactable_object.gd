extends StaticBody2D
class_name InteractableObject

# An object that shows a dialog or mini-game when the player interacts with it
# Perfect for clues, notes, puzzles, or locked items in your escape room

enum InteractionType { TEXT_ONLY, MINI_GAME_ONLY, TEXT_THEN_MINI_GAME }

@export var interaction_type: InteractionType = InteractionType.TEXT_ONLY
@export_multiline var dialog_text: String = "This is a mysterious object..."  # The text to display
@export var mini_game_scene: PackedScene  # The mini-game to show (if using mini-game)
@export var one_time_only: bool = false  # If true, can only be interacted with once
@export var interaction_label: String = "examine"  # What shows in the [E] prompt
@export var require_success: bool = true  # If true, mini-game must be completed successfully

@export_group("Interaction Prompt Position")
@export var prompt_offset: Vector2 = Vector2(0, 0)  # Offset for the "[E] to examine" text position

@export_group("Dialog Position")
@export var custom_position: bool = false  # Enable custom position for dialog
@export var dialog_position: Vector2 = Vector2(0, 0)  # Custom position offset from default

var has_been_used: bool = false
var mini_game_completed: bool = false

@onready var interaction_area = $InteractionArea

signal puzzle_solved
signal puzzle_failed

# Set up the interaction when the scene loads
func _ready():
	if interaction_area:
		interaction_area.interact = Callable(self, "_on_interact")
		interaction_area.action_name = interaction_label
		# Apply custom prompt position offset
		interaction_area.label_offset_x = prompt_offset.x
		interaction_area.label_offset_y = prompt_offset.y

# Called when the player presses E near this object
func _on_interact():
	# Check if it's one-time only and already used
	if one_time_only and has_been_used:
		return
	
	match interaction_type:
		InteractionType.TEXT_ONLY:
			await _show_text_dialog()
			_mark_as_used()
			
		InteractionType.MINI_GAME_ONLY:
			var result = await _show_mini_game()
			# Only mark as used if the game was actually completed (not just closed)
			if result["completed"] and (result["success"] or not require_success):
				_mark_as_used()
				
		InteractionType.TEXT_THEN_MINI_GAME:
			await _show_text_dialog()
			var result = await _show_mini_game()
			# Only mark as used if the game was actually completed (not just closed)
			if result["completed"] and (result["success"] or not require_success):
				_mark_as_used()

# Show the text dialog
func _show_text_dialog():
	if custom_position:
		DialogBox.show_dialog(dialog_text, dialog_position)
	else:
		DialogBox.show_dialog(dialog_text)
	
	await DialogBox.dialog_finished

# Show the mini-game
func _show_mini_game() -> Dictionary:
	if not mini_game_scene:
		push_error("No mini-game scene assigned to " + name)
		return {"completed": false, "success": false}
	
	# Show the mini-game
	var game = MiniGameManager.show_mini_game(mini_game_scene)
	
	# Wait for completion or closure
	var result = await race([
		MiniGameManager.mini_game_completed,
		MiniGameManager.mini_game_closed
	])
	
	if result[0] == 0:  # game_completed signal
		var success = result[1]  # success parameter
		mini_game_completed = true
		
		if success:
			puzzle_solved.emit()
			_on_puzzle_solved()
		else:
			puzzle_failed.emit()
			_on_puzzle_failed()
		
		return {"completed": true, "success": success}
	else:  # game_closed signal (ESC pressed, closed early)
		return {"completed": false, "success": false}

# Helper function to race multiple signals
func race(signals: Array) -> Array:
	var result = []
	var settled = false
	
	for i in range(signals.size()):
		var sig = signals[i]
		var callable = func(args = null):
			if not settled:
				settled = true
				result = [i, args]
		
		if sig is Signal:
			sig.connect(callable, CONNECT_ONE_SHOT)
	
	while not settled:
		await get_tree().process_frame
	
	return result

# Mark the object as used
func _mark_as_used():
	if one_time_only:
		has_been_used = true
		if interaction_area:
			interaction_area.action_name = "already examined"

# Override these in extended scripts for custom behavior
func _on_puzzle_solved():
	print(name + " puzzle solved!")
	# Add custom logic here, like:
	# - Giving the player an item
	# - Unlocking a door
	# - Playing a sound effect

func _on_puzzle_failed():
	print(name + " puzzle failed!")
	# Add custom logic here
