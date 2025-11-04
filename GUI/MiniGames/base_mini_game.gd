extends Control
class_name BaseMiniGame

## Base class for all mini-games in the escape room
## Extend this class to create your own puzzles and challenges

signal game_completed(success: bool)
signal game_closed

var is_active: bool = false

func _ready():
	hide()
	set_process_input(false)

## Override this to set up your mini-game
func start_game():
	show()
	is_active = true
	set_process_input(true)
	print("Mini-game started")

## Call this when the player solves the puzzle
func complete_game(success: bool = true):
	is_active = false
	set_process_input(false)
	game_completed.emit(success)
	await get_tree().create_timer(0.5).timeout
	hide()

## Call this to close the game without completing it
func close_game():
	is_active = false
	set_process_input(false)
	game_closed.emit()
	hide()

## Override this to handle input during your mini-game
func _input(event):
	if not is_active:
		return
	
	# Allow ESC to close the mini-game
	if event.is_action_pressed("ui_cancel"):
		close_game()
