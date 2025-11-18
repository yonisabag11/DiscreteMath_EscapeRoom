extends "res://Levels/Interactions/Scripts/interactable_object.gd"

## Final Door that tracks mini-game progress and shows a win screen when all are complete

# Mini-game scene references
const CIPHER_GAME = preload("res://GUI/MiniGames/affine_cipher_game.tscn")
const TRUTH_TABLE_GAME = preload("res://GUI/MiniGames/truth_table_puzzle.tscn")
const SET_THEORY_GAME = preload("res://GUI/MiniGames/set_theory_puzzle_game.tscn")

var win_screen_scene = preload("res://GUI/win_screen.tscn")

func _get_progress_text() -> String:
	var cipher_complete = MiniGameManager.is_mini_game_completed(CIPHER_GAME)
	var truth_complete = MiniGameManager.is_mini_game_completed(TRUTH_TABLE_GAME)
	var sets_complete = MiniGameManager.is_mini_game_completed(SET_THEORY_GAME)
	
	var text = ""
	
	# Cipher progress
	if cipher_complete:
		text += "[color=green]Cipher: Complete[/color]\n\n"
	else:
		text += "[color=red]Cipher: In Progress[/color]\n\n"
	
	# Truth Table progress
	if truth_complete:
		text += "[color=green]Truth Tables: Complete[/color]\n\n"
	else:
		text += "[color=red]Truth Tables: In Progress[/color]\n\n"
	
	# Set Theory progress
	if sets_complete:
		text += "[color=green]Set Theory: Complete[/color]"
	else:
		text += "[color=red]Set Theory: In Progress[/color]"
	
	return text

func _on_interact():
	var cipher_complete = MiniGameManager.is_mini_game_completed(CIPHER_GAME)
	var truth_complete = MiniGameManager.is_mini_game_completed(TRUTH_TABLE_GAME)
	var sets_complete = MiniGameManager.is_mini_game_completed(SET_THEORY_GAME)
	
	if cipher_complete and truth_complete and sets_complete:
		# All mini-games completed - show win screen!
		_show_win_screen()
	else:
		# Not all completed yet - show progress in dialog
		var progress_text = _get_progress_text()
		DialogBox.show_dialog(progress_text)
		await DialogBox.dialog_finished

func _show_win_screen():
	var win_screen = win_screen_scene.instantiate()
	get_tree().root.add_child(win_screen)
