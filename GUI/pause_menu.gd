extends CanvasLayer

## Pause Menu - Shows when ESC is pressed during gameplay
## Provides Help and Exit options

@onready var panel: Panel = $Panel
@onready var help_button: Button = $Panel/MarginContainer/VBoxContainer/MenuButtons/HelpButton
@onready var resume_button: Button = $Panel/MarginContainer/VBoxContainer/MenuButtons/ResumeButton
@onready var exit_button: Button = $Panel/MarginContainer/VBoxContainer/MenuButtons/ExitButton
@onready var how_to_play_panel: Panel = $HowToPlayPanel
@onready var back_button: Button = $HowToPlayPanel/MarginContainer/VBoxContainer/BackButton

var is_paused: bool = false

func _ready():
	# Connect button signals
	help_button.pressed.connect(_on_help_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Hide initially
	hide()
	how_to_play_panel.hide()
	
	# Set process mode to always so it works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Only handle ESC if no mini-game is active
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if MiniGameManager.current_mini_game == null:
			toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		show_pause_menu()
	else:
		hide_pause_menu()

func show_pause_menu():
	show()
	panel.show()
	how_to_play_panel.hide()
	get_tree().paused = true
	resume_button.grab_focus()

func hide_pause_menu():
	hide()
	get_tree().paused = false
	is_paused = false

func _on_resume_pressed():
	hide_pause_menu()

func _on_help_pressed():
	# Show the how to play panel
	panel.hide()
	how_to_play_panel.show()
	back_button.grab_focus()

func _on_back_pressed():
	# Hide the how to play panel
	how_to_play_panel.hide()
	panel.show()
	help_button.grab_focus()

func _on_exit_pressed():
	# Hide pause menu first
	hide()
	is_paused = false
	
	# Unpause and return to main menu
	get_tree().paused = false
	
	# Close any open dialogs
	if DialogBox and DialogBox.has_method("hide_dialog"):
		DialogBox.hide_dialog()
	
	# Close any open mini-games
	if MiniGameManager:
		MiniGameManager.close_mini_game()
	
	# Reset game state
	MiniGameManager.reset_all_completions()
	if HealthManager:
		HealthManager.reset_hearts()
	
	# Unfreeze player if they were frozen
	var player = get_tree().get_first_node_in_group("player_cat")
	if player and player.has_method("unfreeze"):
		player.unfreeze()
	
	# Load main menu
	get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
