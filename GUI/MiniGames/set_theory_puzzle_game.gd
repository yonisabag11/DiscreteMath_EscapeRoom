extends BaseMiniGame
class_name SetTheoryPuzzleGame

## A Set Theory puzzle mini-game for Discrete Math
## Players must find the intersection (A ∩ B) by clicking cells in a grid
## Game has 3 rounds, each with one intersection element to find

# Grid configuration - using coordinate system (1-5 for columns, a-e for rows)
const GRID_COLS: int = 5
const GRID_ROWS: int = 5
const CELL_SIZE: int = 28
const ROW_LABELS: Array[String] = ["a", "b", "c", "d", "e"]
const COL_LABELS: Array[String] = ["1", "2", "3", "4", "5"]

# Game settings
@export var puzzle_title: String = "Find A ∩ B"
@export var max_total_attempts: int = 3  # Maximum attempts allowed
@export var total_rounds: int = 3  # Number of questions to ask

# Persistent state - these persist across game open/close
static var persistent_attempts_made: int = 0  # Total attempts across all sessions
static var persistent_rounds_completed: int = 0  # Number of rounds successfully completed
static var persistent_game_failed: bool = false  # Whether the game was failed permanently

## Static method to reset persistent state (call when restarting game)
static func reset_persistent_state():
	persistent_attempts_made = 0
	persistent_rounds_completed = 0
	persistent_game_failed = false

# Game mode enum
enum SetOperation {
	INTERSECTION,  # Find elements in both sets (A ∩ B)
	SYMMETRIC_DIFF     # Find elements in symmetric difference (A ^ B)
}

# State
var current_round: int = 0
var rounds_completed: int = 0
var current_operation: SetOperation  # Current operation type for this round
var set_a_elements: Array[String] = []
var set_b_elements: Array[String] = []
var current_intersection_element: String = ""  # The ONE element in intersection for this round
var current_intersection_coord: Vector2i  # The correct coordinate for this round
var selected_cell: Vector2i = Vector2i(-1, -1)  # Only one selection at a time
var attempts_made: int = 0
var grid_buttons: Array[Button] = []

# UI References
@onready var title_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var question_label: Label = $Panel/MarginContainer/VBoxContainer/QuestionLabel
@onready var set_info_label: Label = $Panel/MarginContainer/VBoxContainer/SetInfoLabel
@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/GridContainer
@onready var submit_button: Button = $ButtonContainer/SubmitButton
@onready var clear_button: Button = $ButtonContainer/ClearButton
@onready var feedback_label: Label = $FeedbackLabel
@onready var attempts_label: Label = $AttemptsLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var main_panel: Panel = $Panel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/CenterPanel/MarginContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $GameOverPanel/CenterPanel/MarginContainer/VBoxContainer/MainMenuButton


func _ready():
	super._ready()

	# Enable BBCode on the title so we can resize the operation symbols
	title_label.bbcode_enabled = true
	# If puzzle_title contains the symbol characters, wrap them with a font_size tag
	var formatted = puzzle_title
	formatted = formatted.replace("∩", "[font_size=12]∩[/font_size]")
	formatted = formatted.replace("∪", "[font_size=12]∪[/font_size]")
	title_label.text = formatted
	
	# Set up grid - add 1 extra column and row for labels
	grid_container.columns = GRID_COLS + 1
	
	# Connect buttons
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	# Game over panel
	game_over_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func start_game():
	super.start_game()
	
	# Restore persistent state so progress carries across re-entries
	game_over_panel.hide()
	attempts_made = persistent_attempts_made
	rounds_completed = persistent_rounds_completed
	current_round = persistent_rounds_completed  # Resume from where you left off
	selected_cell = Vector2i(-1, -1)
	feedback_label.text = ""
	_update_attempts_display()
	
	# Check if already completed all rounds
	if rounds_completed >= total_rounds:
		feedback_label.text = "🎉 You already completed all rounds!"
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		await get_tree().create_timer(2.0).timeout
		complete_game(true)
		return
	
	# Start next round (question will be randomized)
	_start_new_round()

func _start_new_round():
	current_round += 1
	
	# Randomly choose between intersection and symmetric difference for this round
	current_operation = SetOperation.INTERSECTION if randf() < 0.5 else SetOperation.SYMMETRIC_DIFF
	
	# Update title to show progress and operation (use BBCode to resize symbols)
	var operation_text = ""
	if current_operation == SetOperation.INTERSECTION:
		operation_text = "A [font_size=12]∩[/font_size] B"
	else:
		operation_text = "(A - B) [font_size=12]∪[/font_size] (B - A)"
	title_label.text = "Round " + str(current_round) + "/" + str(total_rounds) + ": Find " + operation_text
	
	# Generate random sets based on the operation
	if current_operation == SetOperation.INTERSECTION:
		_generate_random_sets_single_intersection()
	else:
		_generate_random_sets_single_symmetric_diff()
	
	# Display set information
	var set_a_str = "A = {" + ", ".join(set_a_elements) + "}"
	var set_b_str = "B = {" + ", ".join(set_b_elements) + "}"
	set_info_label.text = set_a_str + "\n" + set_b_str
	
	# Hide the question label - users can figure it out from the title
	question_label.hide()
	
	# Generate the grid
	_generate_grid()
	
	# Reset round state (but keep attempts from session)
	selected_cell = Vector2i(-1, -1)
	feedback_label.text = ""
	_update_attempts_display()
	
	# Enable buttons
	submit_button.disabled = false
	clear_button.disabled = false

func _generate_random_sets_single_intersection():
	# Clear previous data
	set_a_elements.clear()
	set_b_elements.clear()
	
	# All possible elements (numbers 1-5 and letters a-e)
	var all_elements: Array[String] = ["a", "b", "c", "d", "e", "1", "2", "3", "4", "5"]
	
	# Pick ONE letter and ONE number that will be the intersection pair
	var letters: Array[String] = ["a", "b", "c", "d", "e"]
	var numbers: Array[String] = ["1", "2", "3", "4", "5"]
	
	letters.shuffle()
	numbers.shuffle()
	
	var intersection_letter = letters[0]
	var intersection_number = numbers[0]
	current_intersection_element = intersection_letter + intersection_number  # e.g., "b1"
	
	print("DEBUG Round ", current_round, ": Intersection pair: ", intersection_letter, " + ", intersection_number, " = ", current_intersection_element)
	
	# Build set A: MUST include BOTH the letter AND the number + 2-3 random others (4-5 total)
	set_a_elements = [intersection_letter, intersection_number]
	var remaining_for_a = all_elements.duplicate()
	remaining_for_a.erase(intersection_letter)
	remaining_for_a.erase(intersection_number)
	remaining_for_a.shuffle()
	
	# Add 2-3 random elements to set A (to keep total at 4-5)
	var num_extra_a = min(randi_range(2, 3), remaining_for_a.size())
	for i in range(num_extra_a):
		set_a_elements.append(remaining_for_a[i])
	set_a_elements.shuffle()
	
	# Build set B: MUST include BOTH the letter AND the number + 2-3 different random others (4-5 total)
	set_b_elements = [intersection_letter, intersection_number]
	var remaining_for_b = all_elements.duplicate()
	remaining_for_b.erase(intersection_letter)
	remaining_for_b.erase(intersection_number)
	
	# Remove elements already used in set A to ensure ONLY the letter+number pair intersects
	for elem in remaining_for_a:
		if elem in set_a_elements:
			remaining_for_b.erase(elem)
	
	remaining_for_b.shuffle()
	
	# Add 2-3 random elements to set B (different from A's extras, to keep total at 4-5)
	var num_extra_b = min(randi_range(2, 3), remaining_for_b.size())
	for i in range(num_extra_b):
		set_b_elements.append(remaining_for_b[i])
	set_b_elements.shuffle()
	
	# Set the grid coordinate based on the letter and number
	var letter_row = ROW_LABELS.find(intersection_letter)
	var number_col = COL_LABELS.find(intersection_number)
	
	current_intersection_coord = Vector2i(number_col, letter_row)
	
	print("DEBUG: Set A = ", set_a_elements, " (mixed)")
	print("DEBUG: Set B = ", set_b_elements, " (mixed)")
	print("DEBUG: Intersection elements: {", intersection_letter, ", ", intersection_number, "}")
	print("DEBUG: Grid coordinate: ", current_intersection_coord, " = ", ROW_LABELS[current_intersection_coord.y], COL_LABELS[current_intersection_coord.x])

func _generate_random_sets_single_symmetric_diff():
	"""
	Generate sets for SYMMETRIC DIFFERENCE mode where we find a unique pairing.
	Sets should share most elements, but ONE letter only in A and ONE number only in B.
	Example: A = [a,b,c,d], B = [a,b,c,4] → answer is d4
	The letter 'd' is only in A, and the number '4' is only in B.
	All other elements (a,b,c) are shared between both sets.
	"""
	# Clear previous data
	set_a_elements.clear()
	set_b_elements.clear()
	
	# All possible elements
	var all_letters: Array[String] = ["a", "b", "c", "d", "e"]
	var all_numbers: Array[String] = ["1", "2", "3", "4", "5"]
	
	# Shuffle for randomness
	all_letters.shuffle()
	all_numbers.shuffle()
	
	# Pick ONE unique letter that will ONLY be in set A
	var unique_letter = all_letters[0]
	
	# Pick ONE unique number that will ONLY be in set B
	var unique_number = all_numbers[0]
	
	# The answer is the combination of these two unique elements
	current_intersection_element = unique_letter + unique_number  # e.g., "d4"
	
	print("DEBUG Round ", current_round, " (SYMMETRIC DIFF): Unique letter (only in A): ", unique_letter, ", Unique number (only in B): ", unique_number, " = ", current_intersection_element)
	
	# We need 4-5 total elements per set
	# Strategy: 1 unique element + 3-4 common elements
	
	# Pick 2-3 common letters (will be in BOTH sets, excluding the unique letter)
	var common_letters: Array[String] = []
	var num_common_letters = randi_range(2, 3)
	for i in range(1, min(1 + num_common_letters, all_letters.size())):
		common_letters.append(all_letters[i])
	
	# Calculate how many common numbers we need (1-2) to reach 4-5 total
	# Total = 1 unique + num_common_letters + num_common_numbers
	# We want 4-5 total, so if we have 2 common letters, we need 1-2 numbers
	# If we have 3 common letters, we need 0-1 numbers
	var num_common_numbers = 4 - 1 - num_common_letters  # Base amount to reach 4
	if randf() < 0.5:  # 50% chance to add one more to reach 5
		num_common_numbers += 1
	
	var common_numbers: Array[String] = []
	for i in range(1, min(1 + num_common_numbers, all_numbers.size())):
		common_numbers.append(all_numbers[i])
	
	# Build set A: unique letter + common letters + common numbers (NO unique number from B)
	set_a_elements.clear()
	set_a_elements.append(unique_letter)
	for letter in common_letters:
		set_a_elements.append(letter)
	for number in common_numbers:
		set_a_elements.append(number)
	set_a_elements.shuffle()
	
	# Build set B: unique number + common letters + common numbers (NO unique letter from A)
	set_b_elements.clear()
	set_b_elements.append(unique_number)
	for letter in common_letters:
		set_b_elements.append(letter)
	for number in common_numbers:
		set_b_elements.append(number)
	set_b_elements.shuffle()
	
	# Set the grid coordinate based on the unique letter and unique number
	var letter_row = ROW_LABELS.find(unique_letter)
	var number_col = COL_LABELS.find(unique_number)
	
	current_intersection_coord = Vector2i(number_col, letter_row)
	
	print("DEBUG: Set A = ", set_a_elements, " (has ONLY unique letter '", unique_letter, "', NOT number '", unique_number, "')")
	print("DEBUG: Set B = ", set_b_elements, " (has ONLY unique number '", unique_number, "', NOT letter '", unique_letter, "')")
	print("DEBUG: Common elements: ", common_letters + common_numbers)
	print("DEBUG: Symmetric difference answer: ", current_intersection_element)
	print("DEBUG: Grid coordinate: ", current_intersection_coord, " = ", ROW_LABELS[current_intersection_coord.y], COL_LABELS[current_intersection_coord.x])


func _generate_grid():
	# Clear existing grid
	for button in grid_buttons:
		button.queue_free()
	grid_buttons.clear()
	
	# Clear all children from grid container
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create grid with labels
	# First row: column labels (empty corner + 1,2,3,4,5)
	var corner_label = Label.new()
	corner_label.text = ""
	corner_label.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	corner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid_container.add_child(corner_label)
	
	for col in range(GRID_COLS):
		var label = Label.new()
		label.text = COL_LABELS[col]
		label.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 12)
		grid_container.add_child(label)
	
	# Create grid rows with row labels (A,B,C,D,E) + cells
	for row in range(GRID_ROWS):
		# Row label
		var label = Label.new()
		label.text = ROW_LABELS[row]
		label.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 12)
		grid_container.add_child(label)
		
		# Grid cells for this row
		for col in range(GRID_COLS):
			var button = Button.new()
			button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			button.text = ""  # Empty - no text in cells
			
			var pos = Vector2i(col, row)
			
			# Style the button - starts unselected (dark)
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = Color(0.2, 0.2, 0.25)  # Dark blue-gray
			style_normal.border_width_left = 2
			style_normal.border_width_right = 2
			style_normal.border_width_top = 2
			style_normal.border_width_bottom = 2
			style_normal.border_color = Color(0.4, 0.4, 0.5)
			style_normal.corner_radius_top_left = 4
			style_normal.corner_radius_top_right = 4
			style_normal.corner_radius_bottom_left = 4
			style_normal.corner_radius_bottom_right = 4
			button.add_theme_stylebox_override("normal", style_normal)
			
			var style_hover = StyleBoxFlat.new()
			style_hover.bg_color = Color(0.3, 0.3, 0.4)
			style_hover.border_width_left = 2
			style_hover.border_width_right = 2
			style_hover.border_width_top = 2
			style_hover.border_width_bottom = 2
			style_hover.border_color = Color(0.6, 0.6, 0.7)
			style_hover.corner_radius_top_left = 4
			style_hover.corner_radius_top_right = 4
			style_hover.corner_radius_bottom_left = 4
			style_hover.corner_radius_bottom_right = 4
			button.add_theme_stylebox_override("hover", style_hover)
			
			# Connect press signal
			button.pressed.connect(_on_cell_pressed.bind(pos, button))
			
			grid_container.add_child(button)
			grid_buttons.append(button)

func _on_cell_pressed(pos: Vector2i, button: Button):
	# Deselect previous selection if any
	if selected_cell != Vector2i(-1, -1) and selected_cell != pos:
		var prev_button = _get_button_at_pos(selected_cell)
		if prev_button:
			_reset_button_style(prev_button)
	
	if pos == selected_cell:
		# Deselect current cell
		selected_cell = Vector2i(-1, -1)
		_reset_button_style(button)
	else:
		# Select this cell
		selected_cell = pos
		_highlight_button_style(button)

func _reset_button_style(button: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.25)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.4, 0.4, 0.5)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", style_normal)

func _highlight_button_style(button: Button):
	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0.2, 0.8, 0.2)  # Bright green (lit up)
	style_selected.border_width_left = 3
	style_selected.border_width_right = 3
	style_selected.border_width_top = 3
	style_selected.border_width_bottom = 3
	style_selected.border_color = Color(0.4, 1.0, 0.4)
	style_selected.corner_radius_top_left = 4
	style_selected.corner_radius_top_right = 4
	style_selected.corner_radius_bottom_left = 4
	style_selected.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", style_selected)

func _on_submit_pressed():
	# Check if a cell is selected
	if selected_cell == Vector2i(-1, -1):
		feedback_label.text = "Please select a cell first!"
		feedback_label.add_theme_color_override("font_color", Color.YELLOW)
		return
	
	# Check if the selected cell is correct
	if selected_cell == current_intersection_coord:
		_on_correct_answer()
	else:
		_on_wrong_answer()

func _on_clear_pressed():
	# Clear selection
	if selected_cell != Vector2i(-1, -1):
		var button = _get_button_at_pos(selected_cell)
		if button:
			_reset_button_style(button)
		selected_cell = Vector2i(-1, -1)
	
	feedback_label.text = "Cleared."
	feedback_label.add_theme_color_override("font_color", Color.WHITE)

func _on_correct_answer():
	var operation_name = "intersection (A ∩ B)" if current_operation == SetOperation.INTERSECTION else "symmetric difference ((A - B) ∪ (B - A))"
	feedback_label.text = "✓ Correct! The answer is " + current_intersection_element
	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Highlight correct cell
	var button = _get_button_at_pos(selected_cell)
	if button:
		_highlight_button_style(button)
	
	# Disable interaction temporarily
	submit_button.disabled = true
	clear_button.disabled = true
	for btn in grid_buttons:
		btn.disabled = true
	
	rounds_completed += 1
	persistent_rounds_completed = rounds_completed  # Save progress
	
	# Wait a moment, then move to next round or complete
	await get_tree().create_timer(1.5).timeout
	
	if rounds_completed >= total_rounds:
		# All rounds completed! Reset persistent state for next full play-through
		feedback_label.text = "Perfect! You found all the answers!"
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		persistent_attempts_made = 0
		persistent_rounds_completed = 0
		await get_tree().create_timer(2.0).timeout
		complete_game(true)
	else:
		# Start next round
		_start_new_round()

func _on_wrong_answer():
	attempts_made += 1
	persistent_attempts_made = attempts_made  # Save to persistent state
	
	if attempts_made >= max_total_attempts:
		feedback_label.text = "✗ Wrong! The answer was " + current_intersection_element
		feedback_label.add_theme_color_override("font_color", Color.RED)
		
		# Show correct answer in yellow
		var correct_button = _get_button_at_pos(current_intersection_coord)
		if correct_button:
			var style_answer = StyleBoxFlat.new()
			style_answer.bg_color = Color(0.8, 0.6, 0.0)  # Gold/yellow
			style_answer.border_width_left = 3
			style_answer.border_width_right = 3
			style_answer.border_width_top = 3
			style_answer.border_width_bottom = 3
			style_answer.border_color = Color(1.0, 0.8, 0.2)
			style_answer.corner_radius_top_left = 4
			style_answer.corner_radius_top_right = 4
			style_answer.corner_radius_bottom_left = 4
			style_answer.corner_radius_bottom_right = 4
			correct_button.add_theme_stylebox_override("normal", style_answer)
		
		# Disable interaction
		submit_button.disabled = true
		clear_button.disabled = true
		for button in grid_buttons:
			button.disabled = true
		
		var last_heart = false
		if has_node("/root/HealthManager"):
			last_heart = HealthManager.will_lose_last_heart()
		
		if last_heart:
			feedback_label.text += "\nYou lost your last heart."
			await get_tree().create_timer(1.2).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Show in-mini-game Game Over
			main_panel.visible = false
			color_rect.visible = false
			game_over_panel.show()
			restart_button.grab_focus()
		else:
			feedback_label.text += "\nYou lost a heart."
			await get_tree().create_timer(2.0).timeout  # Give time to read the message
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Reset attempts and rounds for next entry
			attempts_made = 0
			persistent_attempts_made = 0
			rounds_completed = 0
			persistent_rounds_completed = 0
			# Close the mini-game so they can re-enter when ready
			complete_game(false)
	else:
		feedback_label.text = "✗ Incorrect. Try again!"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		_update_attempts_display()

func _update_attempts_display():
	var remaining = max_total_attempts - attempts_made
	attempts_label.text = "Attempts remaining: " + str(remaining)
	attempts_label.show()

func _get_button_at_pos(pos: Vector2i) -> Button:
	# Account for the label row and column
	var index = pos.y * GRID_COLS + pos.x
	if index >= 0 and index < grid_buttons.size():
		return grid_buttons[index]
	return null

func _on_restart_pressed():
	# Reset the mini-game manager completion tracking
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset static persistent state
	SetTheoryPuzzleGame.reset_persistent_state()
	# Destroy this mini-game instance completely
	queue_free()
	# Go back to the lobby (starting room)
	get_tree().change_scene_to_file("res://Levels/Lobby.tscn")

func _on_main_menu_pressed():
	# Reset the mini-game manager completion tracking
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset static persistent state
	SetTheoryPuzzleGame.reset_persistent_state()
	# Destroy this mini-game instance completely
	queue_free()
	# Go to main menu
	get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
