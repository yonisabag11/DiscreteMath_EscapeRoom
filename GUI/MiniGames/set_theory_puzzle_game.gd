extends BaseMiniGame

## A Set Theory puzzle mini-game for Discrete Math
## Players must find the intersection (A ∩ B) by clicking cells in a grid

# Set configuration
@export var set_a_elements: Array[String] = ["b", "2", "d", "4", "e", "5"]
@export var set_b_elements: Array[String] = ["a", "1", "b", "2", "c", "3"]
@export var puzzle_title: String = "Find A ∩ B"
@export var show_question: bool = true
@export var max_attempts: int = 3  # 0 for unlimited

# Grid settings
const GRID_COLS: int = 5
const GRID_ROWS: int = 5
const CELL_SIZE: int = 35  # Reduced for smaller screen

# State
var intersection_set: Array[String] = []
var selected_cells: Array[Vector2i] = []
var cell_to_element: Dictionary = {}  # Maps grid position to element
var correct_positions: Array[Vector2i] = []
var attempts_made: int = 0
var grid_buttons: Array[Button] = []

# UI References
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var question_label: Label = $Panel/MarginContainer/VBoxContainer/QuestionLabel
@onready var set_info_label: Label = $Panel/MarginContainer/VBoxContainer/SetInfoLabel
@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/GridContainer
@onready var button_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ButtonContainer
@onready var submit_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SubmitButton
@onready var clear_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ClearButton
@onready var feedback_label: Label = $Panel/MarginContainer/VBoxContainer/FeedbackLabel
@onready var attempts_label: Label = $Panel/MarginContainer/VBoxContainer/AttemptsLabel

func _ready():
	super._ready()
	
	title_label.text = puzzle_title
	
	# Set up grid
	grid_container.columns = GRID_COLS
	
	# Connect buttons
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)

func start_game():
	super.start_game()
	
	# Calculate intersection
	_calculate_intersection()
	
	# Display set information
	var set_a_str = "A = {" + ", ".join(set_a_elements) + "}"
	var set_b_str = "B = {" + ", ".join(set_b_elements) + "}"
	set_info_label.text = set_a_str + "\n" + set_b_str
	
	# Show/hide question
	if show_question:
		question_label.text = "Click all cells that belong to A ∩ B"
		question_label.show()
	else:
		question_label.hide()
	
	# Generate the grid
	_generate_grid()
	
	# Reset state
	selected_cells.clear()
	attempts_made = 0
	feedback_label.text = ""
	_update_attempts_display()

func _calculate_intersection():
	intersection_set.clear()
	
	for element in set_a_elements:
		if element in set_b_elements:
			intersection_set.append(element)
	
	print("DEBUG: Intersection A ∩ B = {" + ", ".join(intersection_set) + "}")

func _generate_grid():
	# Clear existing grid
	for button in grid_buttons:
		button.queue_free()
	grid_buttons.clear()
	cell_to_element.clear()
	correct_positions.clear()
	
	# Create a list of all unique elements from both sets
	var all_elements: Array[String] = []
	for elem in set_a_elements:
		if elem not in all_elements:
			all_elements.append(elem)
	for elem in set_b_elements:
		if elem not in all_elements:
			all_elements.append(elem)
	
	# Shuffle for random placement
	all_elements.shuffle()
	
	# Place elements in grid (only use what we need)
	var element_index: int = 0
	
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var button = Button.new()
			button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			
			var pos = Vector2i(col, row)
			
			# Assign element if we have any left
			if element_index < all_elements.size():
				var element = all_elements[element_index]
				button.text = element
				cell_to_element[pos] = element
				
				# Style the button with better colors
				var style_normal = StyleBoxFlat.new()
				style_normal.bg_color = Color(0.2, 0.2, 0.25)  # Dark blue-gray
				style_normal.border_width_left = 2
				style_normal.border_width_right = 2
				style_normal.border_width_top = 2
				style_normal.border_width_bottom = 2
				style_normal.border_color = Color(0.4, 0.4, 0.5)  # Lighter border
				style_normal.corner_radius_top_left = 4
				style_normal.corner_radius_top_right = 4
				style_normal.corner_radius_bottom_left = 4
				style_normal.corner_radius_bottom_right = 4
				button.add_theme_stylebox_override("normal", style_normal)
				
				var style_hover = StyleBoxFlat.new()
				style_hover.bg_color = Color(0.3, 0.3, 0.4)  # Lighter on hover
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
				
				var style_pressed = StyleBoxFlat.new()
				style_pressed.bg_color = Color(0.4, 0.5, 0.7)  # Blue when pressed
				style_pressed.border_width_left = 2
				style_pressed.border_width_right = 2
				style_pressed.border_width_top = 2
				style_pressed.border_width_bottom = 2
				style_pressed.border_color = Color(0.6, 0.7, 0.9)
				style_pressed.corner_radius_top_left = 4
				style_pressed.corner_radius_top_right = 4
				style_pressed.corner_radius_bottom_left = 4
				style_pressed.corner_radius_bottom_right = 4
				button.add_theme_stylebox_override("pressed", style_pressed)
				
				# White text for visibility
				button.add_theme_color_override("font_color", Color.WHITE)
				button.add_theme_color_override("font_hover_color", Color.WHITE)
				button.add_theme_color_override("font_pressed_color", Color.WHITE)
				
				# Check if this element is in the intersection
				if element in intersection_set:
					correct_positions.append(pos)
				
				element_index += 1
			else:
				button.text = ""
				button.disabled = true
				button.modulate = Color(0.15, 0.15, 0.15)  # Very dark for empty cells
			
			# Style the button text
			button.add_theme_font_size_override("font_size", 14)
			
			# Connect press signal
			button.pressed.connect(_on_cell_pressed.bind(pos, button))
			
			grid_container.add_child(button)
			grid_buttons.append(button)

func _on_cell_pressed(pos: Vector2i, button: Button):
	if pos in selected_cells:
		# Deselect
		selected_cells.erase(pos)
		
		# Reset to normal style
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
		button.add_theme_color_override("font_color", Color.WHITE)
	else:
		# Select
		selected_cells.append(pos)
		
		# Highlight style - bright blue
		var style_selected = StyleBoxFlat.new()
		style_selected.bg_color = Color(0.2, 0.5, 0.9)  # Bright blue
		style_selected.border_width_left = 3
		style_selected.border_width_right = 3
		style_selected.border_width_top = 3
		style_selected.border_width_bottom = 3
		style_selected.border_color = Color(0.4, 0.7, 1.0)  # Lighter blue border
		style_selected.corner_radius_top_left = 4
		style_selected.corner_radius_top_right = 4
		style_selected.corner_radius_bottom_left = 4
		style_selected.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", style_selected)
		button.add_theme_color_override("font_color", Color.WHITE)

func _on_submit_pressed():
	# Check if the selected cells match the correct positions
	if selected_cells.size() != correct_positions.size():
		_on_wrong_answer()
		return
	
	# Check if all selected cells are correct
	var all_correct = true
	for pos in selected_cells:
		if pos not in correct_positions:
			all_correct = false
			break
	
	if all_correct:
		_on_correct_answer()
	else:
		_on_wrong_answer()

func _on_clear_pressed():
	# Clear all selections
	for pos in selected_cells.duplicate():
		var button = _get_button_at_pos(pos)
		if button:
			_on_cell_pressed(pos, button)
	
	feedback_label.text = ""

func _on_correct_answer():
	feedback_label.text = "✓ Correct! A ∩ B = {" + ", ".join(_get_selected_elements()) + "}"
	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Highlight correct cells in bright green
	for pos in selected_cells:
		var button = _get_button_at_pos(pos)
		if button:
			var style_correct = StyleBoxFlat.new()
			style_correct.bg_color = Color(0.2, 0.8, 0.2)  # Bright green
			style_correct.border_width_left = 3
			style_correct.border_width_right = 3
			style_correct.border_width_top = 3
			style_correct.border_width_bottom = 3
			style_correct.border_color = Color(0.4, 1.0, 0.4)
			style_correct.corner_radius_top_left = 4
			style_correct.corner_radius_top_right = 4
			style_correct.corner_radius_bottom_left = 4
			style_correct.corner_radius_bottom_right = 4
			button.add_theme_stylebox_override("normal", style_correct)
			button.add_theme_color_override("font_color", Color.WHITE)
	
	# Disable interaction
	submit_button.disabled = true
	clear_button.disabled = true
	for button in grid_buttons:
		button.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	complete_game(true)

func _on_wrong_answer():
	attempts_made += 1
	
	if max_attempts > 0 and attempts_made >= max_attempts:
		feedback_label.text = "✗ Out of attempts! A ∩ B = {" + ", ".join(intersection_set) + "}"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		
		# Show correct answer in yellow
		for pos in correct_positions:
			var button = _get_button_at_pos(pos)
			if button:
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
				button.add_theme_stylebox_override("normal", style_answer)
				button.add_theme_color_override("font_color", Color.WHITE)
		
		# Disable interaction
		submit_button.disabled = true
		clear_button.disabled = true
		for button in grid_buttons:
			button.disabled = true
		
		await get_tree().create_timer(3.0).timeout
		complete_game(false)
	else:
		feedback_label.text = "✗ Incorrect. Try again!"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		_update_attempts_display()

func _get_selected_elements() -> Array[String]:
	var elements: Array[String] = []
	for pos in selected_cells:
		if pos in cell_to_element:
			elements.append(cell_to_element[pos])
	return elements

func _get_button_at_pos(pos: Vector2i) -> Button:
	var index = pos.y * GRID_COLS + pos.x
	if index >= 0 and index < grid_buttons.size():
		return grid_buttons[index]
	return null

func _update_attempts_display():
	if max_attempts > 0:
		var remaining = max_attempts - attempts_made
		attempts_label.text = "Attempts remaining: " + str(remaining)
		attempts_label.show()
	else:
		attempts_label.hide()
