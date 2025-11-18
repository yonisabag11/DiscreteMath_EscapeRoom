extends BaseMiniGame
class_name TruthTablePuzzleGame

## Truth Table Mini-Game
## Player must correctly complete the truth table for A, B with ¬, ∧, ∨, →, ↔.
## Player has a limited number of attempts; on final failure they lose a heart

# -------------------------------
# CONFIG
# -------------------------------

# Define different truth table variations as questions
const QUESTION_POOL: Array[Dictionary] = [
	{
		"title": "Complete the Basic Operators",
		"columns": ["A", "B", "¬A", "A ∧ B", "A ∨ B"]
	},
	{
		"title": "Complete Implication and Equivalence",
		"columns": ["A", "B", "A → B", "A ↔ B", "¬(A ∧ B)"]
	},
	{
		"title": "Complete All Operators",
		"columns": ["A", "B", "¬A", "A ∧ B", "A ∨ B", "A → B", "A ↔ B"]
	},
	{
		"title": "Complete Mixed Operations",
		"columns": ["A", "B", "¬B", "A ∨ B", "A → B", "¬(A → B)"]
	},
	{
		"title": "Complete Advanced Logic",
		"columns": ["A", "B", "A ∧ B", "¬(A ∧ B)", "A ∨ B", "A ↔ B"]
	}
]

@export var max_attempts: int = 3  # Total attempts for this puzzle
@export var prefilled_cells_count: int = 3  # Number of cells to pre-fill as hints

# Persistent state
static var persistent_attempts_made: int = 0

## Static method to reset persistent state (call when restarting game)
static func reset_persistent_state():
	persistent_attempts_made = 0

# -------------------------------
# STATE
# -------------------------------

var current_question: Dictionary = {}
var current_columns: PackedStringArray = []
var rows: Array[Dictionary] = []
var correct: Array[Array] = []      # 4 x N matrix of bools (N = columns count)
var cell_nodes: Array[Array] = []   # matching Controls [row][col]
var prefilled_cells: Array[Vector2i] = []  # Track which cells are pre-filled

var attempts_made: int = 0

# -------------------------------
# UI NODES
# -------------------------------

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var instructions_label: Label = $Panel/MarginContainer/VBoxContainer/InstructionsLabel
@onready var grid: GridContainer = $Panel/MarginContainer/VBoxContainer/CenterContainer/TableGrid
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

# -------------------------------
# LIFECYCLE
# -------------------------------

func _ready() -> void:
	# BaseMiniGame may set up input, transitions, etc.
	super._ready()
	
	# Connect UI signals
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	# Game over panel
	game_over_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func start_game() -> void:
	super.start_game()
	
	game_over_panel.hide()
	feedback_label.text = ""
	_update_attempts_display()
	
	main_panel.show()
	color_rect.show()
	
	# Select random question
	var question = QUESTION_POOL[randi() % QUESTION_POOL.size()]
	current_columns = question.columns.duplicate()
	current_question = question
	
	# Update title
	title_label.text = question.title
	
	# Update instructions
	instructions_label.text = "Fill in the truth table. Blue cells are given as hints."
	
	# Build the data structures first
	_build_rows()
	_compute_correct()
	_build_grid()
	
	# DEBUG: Print correct answers to console
	print("\n=== TRUTH TABLE DEBUG ===")
	print("Question: ", question.title)
	for r_idx in range(rows.size()):
		var debug_row = "Row " + str(r_idx) + ": "
		for c_idx in range(current_columns.size()):
			debug_row += current_columns[c_idx] + "=" + ("T" if correct[r_idx][c_idx] else "F") + " "
		print(debug_row)
	print("========================\n")


# -------------------------------
# BUILDING THE TRUTH TABLE
# -------------------------------

func _build_rows() -> void:
	rows = [
		{"A": true,  "B": true},
		{"A": true,  "B": false},
		{"A": false, "B": true},
		{"A": false, "B": false},
	]


func _compute_correct() -> void:
	correct.clear()
	for r in rows:
		var A: bool = bool(r["A"])
		var B: bool = bool(r["B"])
		
		var row_values: Array = []
		
		# Compute values for each column in the current question
		for col_name in current_columns:
			match col_name:
				"A":
					row_values.append(A)
				"B":
					row_values.append(B)
				"¬A":
					row_values.append(!A)
				"¬B":
					row_values.append(!B)
				"A ∧ B":
					row_values.append(A and B)
				"A ∨ B":
					row_values.append(A or B)
				"A → B":
					row_values.append((not A) or B)
				"A ↔ B":
					row_values.append(A == B)
				"¬(A ∧ B)":
					row_values.append(not (A and B))
				"¬(A → B)":
					row_values.append(not ((not A) or B))
		
		correct.append(row_values)


func _build_grid() -> void:
	# Clear old content
	for child in grid.get_children():
		child.queue_free()
	
	grid.columns = current_columns.size()
	cell_nodes.clear()
	prefilled_cells.clear()
	
	# Select random cells to pre-fill as hints
	var total_cells = rows.size() * current_columns.size()
	var prefill_positions: Array[Vector2i] = []
	
	# Generate all possible positions (excluding A and B columns which are always given)
	for r_idx in range(rows.size()):
		for c_idx in range(2, current_columns.size()):  # Start from column 2 (skip A and B)
			prefill_positions.append(Vector2i(c_idx, r_idx))
	
	# Shuffle and select random positions to pre-fill
	prefill_positions.shuffle()
	var num_to_prefill = min(prefilled_cells_count, prefill_positions.size())
	for i in range(num_to_prefill):
		prefilled_cells.append(prefill_positions[i])
	
	# Header row
	for title in current_columns:
		var lbl := Label.new()
		lbl.text = title
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 8)
		# Make headers uniform size to match buttons
		lbl.custom_minimum_size = Vector2(24, 18)
		grid.add_child(lbl)
	
	# Body rows
	for r_idx in range(rows.size()):
		var row_nodes: Array = []
		
		for c_idx in range(current_columns.size()):
			var cell_pos = Vector2i(c_idx, r_idx)
			var is_prefilled = cell_pos in prefilled_cells
			
			if c_idx <= 1:
				# Given columns A, B - make them look like grid cells with bright cyan
				var given_btn := Button.new()
				given_btn.text = "T" if bool(correct[r_idx][c_idx]) else "F"
				given_btn.modulate = Color(0.4, 0.9, 1.0)
				given_btn.custom_minimum_size = Vector2(24, 18)
				given_btn.add_theme_font_size_override("font_size", 8)
				given_btn.disabled = true  # Make them non-interactive
				grid.add_child(given_btn)
				row_nodes.append(given_btn)
			elif is_prefilled:
				# Pre-filled cells as hints - show correct answer in light blue
				var hint_btn := Button.new()
				hint_btn.text = "T" if bool(correct[r_idx][c_idx]) else "F"
				hint_btn.modulate = Color(0.6, 0.8, 1.0)  # Lighter blue for hints
				hint_btn.custom_minimum_size = Vector2(24, 18)
				hint_btn.add_theme_font_size_override("font_size", 8)
				hint_btn.disabled = true  # Make them non-interactive
				grid.add_child(hint_btn)
				row_nodes.append(hint_btn)
			else:
				# Player input cells
				var btn := Button.new()
				btn.toggle_mode = true
				btn.text = "?"
				btn.custom_minimum_size = Vector2(24, 18)
				btn.add_theme_font_size_override("font_size", 8)
				
				btn.pressed.connect(func():
					btn.text = "T" if btn.button_pressed else "F"
				)
				
				grid.add_child(btn)
				row_nodes.append(btn)
		
		cell_nodes.append(row_nodes)


# -------------------------------
# BUTTON HANDLERS
# -------------------------------

func _on_clear_pressed() -> void:
	feedback_label.text = "Cleared."
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	for row in cell_nodes:
		for n in row:
			if n is Button:
				var btn := n as Button
				# Only clear cells that aren't disabled (not pre-filled or given)
				if not btn.disabled:
					btn.button_pressed = false
					btn.text = "?"


func _on_submit_pressed() -> void:
	# First check if all cells are filled
	var has_unfilled := false
	for r in range(cell_nodes.size()):
		for c in range(cell_nodes[r].size()):
			var n: Control = cell_nodes[r][c]
			if n is Button:
				var btn := n as Button
				# Skip disabled cells (given or pre-filled)
				if btn.disabled:
					continue
				# Check if cell is still unfilled
				if btn.text == "?":
					has_unfilled = true
					break
		if has_unfilled:
			break
	
	# If there are unfilled cells, show warning and return
	if has_unfilled:
		feedback_label.text = "Please fill in all cells before submitting!"
		feedback_label.add_theme_color_override("font_color", Color.YELLOW)
		return
	
	var mistakes := 0
	
	# Count mistakes ONLY in non-disabled cells (skip given A/B columns and pre-filled hints)
	for r in range(cell_nodes.size()):
		for c in range(cell_nodes[r].size()):
			var n: Control = cell_nodes[r][c]
			var should: bool = bool(correct[r][c])
			
			if n is Button:
				var btn := n as Button
				
				# Skip disabled cells (given or pre-filled)
				if btn.disabled:
					continue
				
				var val: bool = btn.button_pressed
				if val != should:
					mistakes += 1
	
	# ------------------------------
	# SUCCESS
	# ------------------------------
	if mistakes == 0:
		feedback_label.text = "✓ Correct! Truth table completed."
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		
		submit_button.disabled = true
		clear_button.disabled = true
		
		await get_tree().create_timer(2.0).timeout
		complete_game(true)
		return
	
	# ------------------------------
	# FAILURE ATTEMPT
	# ------------------------------
	persistent_attempts_made += 1
	
	if persistent_attempts_made >= max_attempts:
		# Out of attempts → lose heart
		submit_button.disabled = true
		clear_button.disabled = true
		
		var last_heart := false
		if has_node("/root/HealthManager"):
			last_heart = HealthManager.will_lose_last_heart()
		
		if last_heart:
			feedback_label.text = "✗ Wrong. You lost your last heart."
			feedback_label.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(1.2).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Show in-mini-game Game Over screen
			main_panel.visible = false
			color_rect.visible = false
			game_over_panel.show()
			restart_button.grab_focus()
		else:
			feedback_label.text = "✗ Wrong. You lost a heart."
			feedback_label.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(1.0).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Reset attempts for next entry
			persistent_attempts_made = 0
			complete_game(false)
	else:
		# Still have attempts left
		feedback_label.text = "✗ Incorrect. Try again!"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		_update_attempts_display()


func _update_attempts_display() -> void:
	var remaining := max_attempts - persistent_attempts_made
	attempts_label.text = "Attempts remaining: " + str(remaining)


func _on_restart_pressed():
	# Reset the mini-game manager completion tracking
	MiniGameManager.reset_all_completions()
	if has_node("/root/HealthManager"):
		HealthManager.reset_hearts()
	# Reset static persistent state
	TruthTablePuzzleGame.reset_persistent_state()
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
	TruthTablePuzzleGame.reset_persistent_state()
	# Destroy this mini-game instance completely
	queue_free()
	# Go to main menu
	get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
