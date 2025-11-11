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
# Tracks if the mini-game finished (either success or failure). Closing doesn't set this.
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
	
	# Block re-entry ONLY if the mini-game was actually finished (success or failure).
	# If the player closed the game without finishing, allow trying again.
	if (interaction_type == InteractionType.MINI_GAME_ONLY or interaction_type == InteractionType.TEXT_THEN_MINI_GAME):
		if mini_game_completed:
			# Already finished this mini-game, show completion message as a dialog
			DialogBox.show_dialog("This puzzle has already been completed!")
			await DialogBox.dialog_finished
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
	
	# If game is null, it means the MiniGameManager detected it's already completed
	# This is a fallback - normally we should have caught this earlier
	if game == null:
		mini_game_completed = true
		DialogBox.show_dialog("This puzzle has already been completed!")
		await DialogBox.dialog_finished
		return {"completed": true, "success": true}
	
	# Wait for completion or closure
	var completed_signal_fired = false
	var closed_signal_fired = false
	var result_success = false
	
	var on_completed = func(success: bool):
		if not closed_signal_fired:
			completed_signal_fired = true
			result_success = success
	
	var on_closed = func():
		if not completed_signal_fired:
			closed_signal_fired = true
	
	MiniGameManager.mini_game_completed.connect(on_completed, CONNECT_ONE_SHOT)
	MiniGameManager.mini_game_closed.connect(on_closed, CONNECT_ONE_SHOT)
	
	# Wait for either signal
	while not completed_signal_fired and not closed_signal_fired:
		if not is_instance_valid(self) or not is_inside_tree():
			# Node is being freed, return early
			return {"completed": false, "success": false}
		await get_tree().process_frame
	
	if completed_signal_fired:
		# Only block future re-entry on SUCCESS; failure allows trying again.
		if result_success:
			mini_game_completed = true
			puzzle_solved.emit()
			_on_puzzle_solved()
		else:
			puzzle_failed.emit()
			_on_puzzle_failed()
		# After closing the mini-game, ensure the prompt can show again by refreshing the area registration
		if interaction_area and is_instance_valid(interaction_area):
			await get_tree().create_timer(0.1).timeout  # Small delay for cleanup
			InteractionManager.unregister_area(interaction_area)
			InteractionManager.register_area(interaction_area)
			InteractionManager.enable_interaction()  # Ensure interactions are re-enabled
		return {"completed": true, "success": result_success}
	else:  # closed_signal_fired
		print("Mini-game was closed without completion")
		# Refresh area registration so the [E] prompt returns immediately after a close
		if interaction_area and is_instance_valid(interaction_area):
			await get_tree().create_timer(0.1).timeout  # Small delay for cleanup
			InteractionManager.unregister_area(interaction_area)
			InteractionManager.register_area(interaction_area)
			InteractionManager.enable_interaction()  # Ensure interactions are re-enabled
		return {"completed": false, "success": false}

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
