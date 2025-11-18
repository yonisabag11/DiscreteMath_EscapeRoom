extends BaseMiniGame
class_name AffineCipherGame

## An Affine Cipher puzzle mini-game for Discrete Math
## Players must decrypt an encrypted message using the affine cipher formula
## Decryption: D(x) = a^(-1) * (x - b) mod 26
## where a is the multiplicative key and b is the additive shift

# Puzzle database - each entry has: [plaintext, a_key, b_shift]
# a_key must be coprime with 26: valid values are 1, 3, 5, 7, 9, 11, 15, 17, 19, 21, 23, 25
# Example encryptions (for reference):
#   "CHOCOLATE" with a=5, b=3 → "HWHHAPWNO"
#   "MATHEMATICS" with a=7, b=5 → "RFMYRFRMPJH"
#   "ESCAPE ROOM" with a=5, b=11 → "KVIJXK LUUF"
const PUZZLE_DATABASE = [
	["CHOCOLATE", 5, 3],
	["MATHEMATICS", 7, 5],
	["DISCRETE", 3, 8],
	["CIPHER", 9, 2],
	["ALGORITHM", 11, 7],
	["PUZZLE", 15, 4],
	["ESCAPE ROOM", 5, 11],
	["MODULAR", 17, 6],
	["ENCRYPTION", 3, 9],
	["DECODE THIS", 7, 12],
	["SECRET CODE", 5, 8],
	["CRYPTOGRAPHY", 9, 15],
	["NUMBER THEORY", 11, 3],
	["ABSTRACT", 3, 6],
	["LOGIC GATES", 5, 14],
]

# Current puzzle data
var encrypted_message: String = ""
var plaintext_answer: String = ""
var multiplicative_key: int = 5
var additive_shift: int = 3
@export var max_attempts: int = 3  # Maximum attempts allowed

# Persistent state
static var persistent_attempts_made: int = 0

# State
var attempts_made: int = 0

## Static method to reset persistent state (call when restarting game)
static func reset_persistent_state():
	persistent_attempts_made = 0

# UI References
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var instructions_label: Label = $Panel/MarginContainer/VBoxContainer/InstructionsLabel
@onready var encrypted_label: Label = $Panel/MarginContainer/VBoxContainer/EncryptedLabel
@onready var formula_label: Label = $Panel/MarginContainer/VBoxContainer/FormulaLabel
@onready var input_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/InputContainer
@onready var input_label: Label = $Panel/MarginContainer/VBoxContainer/InputContainer/InputLabel
@onready var answer_input: LineEdit = $Panel/MarginContainer/VBoxContainer/InputContainer/AnswerInput
@onready var submit_button: Button = $ButtonContainer/SubmitButton
@onready var clear_button: Button = $ButtonContainer/ClearButton
@onready var feedback_label: Label = $FeedbackLabel
@onready var attempts_label: Label = $AttemptsLabel
@onready var close_label: Label = $CloseLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var main_panel: Panel = $Panel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/CenterPanel/MarginContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $GameOverPanel/CenterPanel/MarginContainer/VBoxContainer/MainMenuButton

func _ready():
	super._ready()
	
	# Connect button signals
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	answer_input.text_submitted.connect(_on_text_submitted)
	
	# Game over panel
	game_over_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func start_game():
	super.start_game()
	
	# Select a random puzzle
	_select_random_puzzle()
	
	# Restore persistent state
	attempts_made = persistent_attempts_made
	answer_input.text = ""
	feedback_label.text = ""
	game_over_panel.hide()
	main_panel.show()
	color_rect.show()
	
	# Display the puzzle
	title_label.text = "Affine Cipher Puzzle"
	instructions_label.text = "Decrypt the message using the shift values from the note"
	encrypted_label.text = "Encrypted: " + encrypted_message
	# Keep UI concise; the formula is on the hint note. Show only the keys here.
	formula_label.text = "Keys: a=" + str(multiplicative_key) + ", b=" + str(additive_shift)
	
	_update_attempts_display()
	
	# Focus the input field after a frame to avoid capturing the interact key press
	await get_tree().process_frame
	answer_input.text = ""  # Clear any captured input
	answer_input.grab_focus()

## Select a random puzzle from the database and encrypt it
func _select_random_puzzle():
	# Randomly pick a puzzle
	var puzzle_index = randi() % PUZZLE_DATABASE.size()
	var puzzle = PUZZLE_DATABASE[puzzle_index]
	
	plaintext_answer = puzzle[0]
	multiplicative_key = puzzle[1]
	additive_shift = puzzle[2]
	
	# Encrypt the plaintext
	encrypted_message = _encrypt_text(plaintext_answer, multiplicative_key, additive_shift)
	
	print("DEBUG: Selected puzzle - Plain: ", plaintext_answer, ", a=", multiplicative_key, ", b=", additive_shift, ", Encrypted: ", encrypted_message)

## Encrypt text using affine cipher: E(x) = (a * x + b) mod 26
func _encrypt_text(text: String, a: int, b: int) -> String:
	var result = ""
	var uppercase_text = text.to_upper()
	
	for i in range(uppercase_text.length()):
		var ch = uppercase_text[i]
		
		# Only encrypt letters, keep spaces and other characters
		if ch >= 'A' and ch <= 'Z':
			var x = ch.unicode_at(0) - 'A'.unicode_at(0)  # Convert to 0-25
			var encrypted_value = (a * x + b) % 26
			var encrypted_char = String.chr(encrypted_value + 'A'.unicode_at(0))
			result += encrypted_char
		else:
			result += ch  # Keep spaces, punctuation as-is
	
	return result

func _on_submit_pressed():
	_check_answer()

func _on_text_submitted(_text: String):
	_check_answer()

func _on_clear_pressed():
	answer_input.text = ""
	feedback_label.text = "Cleared."
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	answer_input.grab_focus()

func _check_answer():
	var user_answer = answer_input.text.strip_edges().to_upper()
	
	if user_answer.is_empty():
		feedback_label.text = "Please enter your answer!"
		feedback_label.add_theme_color_override("font_color", Color.YELLOW)
		return
	
	# Compare answers (both normalized to uppercase, spaces preserved)
	if user_answer == plaintext_answer.to_upper():
		_on_correct_answer()
	else:
		_on_wrong_answer()

func _on_correct_answer():
	feedback_label.text = "✓ Correct! You decrypted the message!"
	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Disable input
	answer_input.editable = false
	submit_button.disabled = true
	
	# Wait a moment, then complete
	await get_tree().create_timer(2.0).timeout
	complete_game(true)

func _on_wrong_answer():
	attempts_made += 1
	persistent_attempts_made = attempts_made
	
	if attempts_made >= max_attempts:
		# On attempts exhausted, lose a heart. Only show Game Over if that was the last heart.
		answer_input.editable = false
		submit_button.disabled = true

		var last_heart = false
		if has_node("/root/HealthManager"):
			last_heart = HealthManager.will_lose_last_heart()

		if last_heart:
			# Reveal the correct answer then trigger last heart loss and show Game Over
			feedback_label.text = "✗ Wrong! The answer was: " + plaintext_answer + "\nYou lost your last heart."
			feedback_label.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(1.2).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Show in-mini-game Game Over screen
			main_panel.visible = false
			color_rect.visible = false
			game_over_panel.show()
			restart_button.grab_focus()
			# Keep the panel; do not complete/close. Restart/Main Menu will handle scene change.
		else:
			# Lose a heart and close the mini-game as a failure so the player can retry later
			feedback_label.text = "✗ Wrong! The answer was: " + plaintext_answer + "\nYou lost a heart."
			feedback_label.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(1.0).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Reset attempts for next entry
			attempts_made = 0
			persistent_attempts_made = 0
			complete_game(false)
	else:
		feedback_label.text = "✗ Incorrect. Try again!"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		_update_attempts_display()
		answer_input.text = ""
		answer_input.grab_focus()

func _update_attempts_display():
	var remaining = max_attempts - attempts_made
	attempts_label.text = "Attempts remaining: " + str(remaining)

func _on_restart_pressed():
	# Restore original behavior: restart the whole game by going back to the Lobby
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset static persistent state
	AffineCipherGame.reset_persistent_state()
	queue_free()
	get_tree().change_scene_to_file("res://Levels/Lobby.tscn")

func _on_main_menu_pressed():
	# Reset the mini-game manager completion tracking
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset static persistent state
	AffineCipherGame.reset_persistent_state()
	# Destroy this mini-game instance completely
	queue_free()
	# Go to main menu
	get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
