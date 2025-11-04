extends Node

## Autoload singleton for managing mini-games in the escape room
## Add this to Project Settings -> Autoload as "MiniGameManager"

var current_mini_game: BaseMiniGame = null
var mini_game_container: CanvasLayer = null

signal mini_game_completed(success: bool)
signal mini_game_closed

func _ready():
	# Create a CanvasLayer to hold mini-games
	mini_game_container = CanvasLayer.new()
	mini_game_container.layer = 100  # Render on top of everything
	add_child(mini_game_container)

## Show a mini-game scene
## game_scene: PackedScene - The mini-game scene to instantiate
## Returns: The instantiated mini-game node
func show_mini_game(game_scene: PackedScene) -> BaseMiniGame:
	# Close any existing mini-game
	if current_mini_game:
		close_mini_game()
	
	# Instantiate the new mini-game
	current_mini_game = game_scene.instantiate()
	mini_game_container.add_child(current_mini_game)
	
	# Connect signals
	current_mini_game.game_completed.connect(_on_mini_game_completed)
	current_mini_game.game_closed.connect(_on_mini_game_closed)
	
	# Start the game
	current_mini_game.start_game()
	
	return current_mini_game

## Close the current mini-game
func close_mini_game():
	if current_mini_game:
		current_mini_game.queue_free()
		current_mini_game = null

func _on_mini_game_completed(success: bool):
	mini_game_completed.emit(success)
	close_mini_game()

func _on_mini_game_closed():
	mini_game_closed.emit()
	close_mini_game()
