extends BaseMiniGame

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
@export var max_attempts_per_round: int = 3  # Attempts per question
@export var total_rounds: int = 3  # Number of questions to ask

# State
var current_round: int = 0
var rounds_completed: int = 0
var set_a_elements: Array[String] = []
var set_b_elements: Array[String] = []
var current_intersection_element: String = ""  # The ONE element in intersection for this round
var current_intersection_coord: Vector2i  # The correct coordinate for this round
var selected_cell: Vector2i = Vector2i(-1, -1)  # Only one selection at a time
var attempts_made: int = 0
var grid_buttons: Array[Button] = []

# UI References
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var question_label: Label = $Panel/MarginContainer/VBoxContainer/QuestionLabel
@onready var set_info_label: Label = $Panel/MarginContainer/VBoxContainer/SetInfoLabel
@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/GridContainer
@onready var button_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ButtonContainer
@onready var submit_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SubmitButton
@onready var clear_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ClearButton
@onready var feedback_label: Label = $Panel/MarginContainer/VBoxContainer/FeedbackLabel
@onready var attempts_label: Label = $Panel/MarginContainer/VBoxContainer/AttemptsLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var main_panel: Panel = $Panel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/CenterPanel/MarginContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $GameOverPanel/CenterPanel/MarginContainer/VBoxContainer/MainMenuButton

func _ready():
	super._ready()
	
	title_label.text = puzzle_title
	
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
	
	# Reset game state
	current_round = 0
	rounds_completed = 0
	game_over_panel.hide()
	
	# Start first round
	_start_new_round()

func _start_new_round():
	current_round += 1
	
	# Update title to show progress
	title_label.text = "Round " + str(current_round) + "/" + str(total_rounds) + ": Find A ∩ B"
	
	# Generate random sets with ONE intersection element
	_generate_random_sets_single_intersection()
	
	# Display set information
	var set_a_str = "A = {" + ", ".join(set_a_elements) + "}"
	var set_b_str = "B = {" + ", ".join(set_b_elements) + "}"
	set_info_label.text = set_a_str + "\n" + set_b_str
	
	# Show question
	question_label.text = "Click the cell with the element in A ∩ B"
	question_label.show()
	
	# Generate the grid
	_generate_grid()
	
	# Reset round state
	selected_cell = Vector2i(-1, -1)
	attempts_made = 0
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
	
	# Build set A: MUST include BOTH the letter AND the number + 2-3 random others
	set_a_elements = [intersection_letter, intersection_number]
	var remaining_for_a = all_elements.duplicate()
	remaining_for_a.erase(intersection_letter)
	remaining_for_a.erase(intersection_number)
	remaining_for_a.shuffle()
	
	# Add 2-3 random elements to set A
	for i in range(randi_range(2, 3)):
		if i < remaining_for_a.size():
			set_a_elements.append(remaining_for_a[i])
	set_a_elements.shuffle()
	
	# Build set B: MUST include BOTH the letter AND the number + 2-3 different random others
	set_b_elements = [intersection_letter, intersection_number]
	var remaining_for_b = all_elements.duplicate()
	remaining_for_b.erase(intersection_letter)
	remaining_for_b.erase(intersection_number)
	
	# Remove elements already used in set A to ensure ONLY the letter+number pair intersects
	for elem in remaining_for_a:
		if elem in set_a_elements:
			remaining_for_b.erase(elem)
	
	remaining_for_b.shuffle()
	
	# Add 2-3 random elements to set B (different from A's extras)
	for i in range(min(randi_range(2, 3), remaining_for_b.size())):
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
	
	feedback_label.text = ""

func _on_correct_answer():
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
	
	# Wait a moment, then move to next round or complete
	await get_tree().create_timer(1.5).timeout
	
	if rounds_completed >= total_rounds:
		# All rounds completed!
		feedback_label.text = "🎉 Perfect! You found all intersections!"
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		await get_tree().create_timer(2.0).timeout
		complete_game(true)
	else:
		# Start next round
		_start_new_round()

func _on_wrong_answer():
	attempts_made += 1
	
	if attempts_made >= max_attempts_per_round:
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
		
		# Hide main panel and background, then show game over panel
		await get_tree().create_timer(2.0).timeout
		main_panel.visible = false  # Hide the main game panel
		color_rect.visible = false  # Hide the dark background overlay
		game_over_panel.show()
		restart_button.grab_focus()
	else:
		feedback_label.text = "✗ Incorrect. Try again!"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		_update_attempts_display()

func _update_attempts_display():
	var remaining = max_attempts_per_round - attempts_made
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
	# Destroy this mini-game instance completely
	queue_free()
	# Go back to the lobby (starting room)
	get_tree().change_scene_to_file("res://Levels/Lobby.tscn")

func _on_main_menu_pressed():
	# Reset the mini-game manager completion tracking
	MiniGameManager.reset_all_completions()
	# Destroy this mini-game instance completely
	queue_free()
	# Go to main menu
	get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
