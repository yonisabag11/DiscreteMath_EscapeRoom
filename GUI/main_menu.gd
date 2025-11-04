extends Control

## Main Menu for the Discrete Math Escape Room game

@onready var start_button: Button = $MarginContainer/VBoxContainer/MenuButtons/StartButton
@onready var how_to_play_button: Button = $MarginContainer/VBoxContainer/MenuButtons/HowToPlayButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/MenuButtons/ExitButton
@onready var how_to_play_panel: Panel = $HowToPlayPanel
@onready var back_button: Button = $HowToPlayPanel/MarginContainer/VBoxContainer/BackButton

# Preload the lobby scene
const LOBBY_SCENE = preload("res://Levels/Lobby.tscn")

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Hide the how to play panel initially
	how_to_play_panel.hide()
	
	# Focus on the start button
	start_button.grab_focus()

func _on_start_pressed():
	# Reset all mini-game completions when starting a new game
	MiniGameManager.reset_all_completions()
	# Start the game by loading the lobby
	get_tree().change_scene_to_packed(LOBBY_SCENE)

func _on_how_to_play_pressed():
	# Show the how to play panel
	how_to_play_panel.show()
	back_button.grab_focus()

func _on_back_pressed():
	# Hide the how to play panel
	how_to_play_panel.hide()
	how_to_play_button.grab_focus()

func _on_exit_pressed():
	# Quit the game
	get_tree().quit()
