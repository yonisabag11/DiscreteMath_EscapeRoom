extends CanvasLayer

## Win Screen shown when all mini-games are completed

@onready var restart_button: Button = $Panel/CenterPanel/MarginContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $Panel/CenterPanel/MarginContainer/VBoxContainer/MainMenuButton

func _ready():
	# Connect button signals
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Focus the first button
	restart_button.grab_focus()
	
	# Freeze player
	var player = get_tree().get_first_node_in_group("player_cat")
	if player and player.has_method("freeze"):
		player.freeze()

func _on_restart_pressed():
	# Reset everything and go back to lobby
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset all mini-game static persistent states
	AffineCipherGame.reset_persistent_state()
	TruthTablePuzzleGame.reset_persistent_state()
	SetTheoryPuzzleGame.reset_persistent_state()
	queue_free()
	get_tree().change_scene_to_file("res://Levels/Lobby.tscn")

func _on_main_menu_pressed():
	# Reset everything and go to main menu
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset all mini-game static persistent states
	AffineCipherGame.reset_persistent_state()
	TruthTablePuzzleGame.reset_persistent_state()
	SetTheoryPuzzleGame.reset_persistent_state()
	queue_free()
	get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
