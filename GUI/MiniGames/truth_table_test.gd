extends Control
class_name PuzzleOverlay

## Truth Table Puzzle Overlay (Alternative Implementation)
## This is an alternative truth table puzzle implementation using a pause-based overlay
## The main game uses truth_table_puzzle_game.gd instead
## This version pauses the world and shows a modal overlay

signal puzzle_solved  # Emitted when the puzzle is correctly completed

# UI node references
@onready var panel: Panel = $Root/Center/Panel
@onready var grid: GridContainer = $Root/Center/Panel/TableGrid  # The truth table grid
@onready var feedback: Label = $Root/Center/Panel/Feedback  # Shows success/error messages
@onready var check_btn: Button = $Root/Center/Panel/Buttons/CheckButton  # Submit answer button
@onready var clear_btn: Button = $Root/Center/Panel/Buttons/ClearButton  # Clear all inputs
@onready var close_btn: Button = $Root/Center/Panel/Buttons/CloseButton  # Close the overlay
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")  # Optional fade animations

# Keep this overlay responsive while the rest of the game is paused
var _was_paused: bool = false  # Store previous pause state to restore later

const COLS: PackedStringArray = ["A","B","¬A","A ∧ B","A ∨ B","A → B","A ↔ B"]  # Column headers

var rows: Array[Dictionary] = []     # [{A: true, B: true}, ...] - The 4 input combinations
var correct: Array[Array] = []       # 4 x 7 matrix of bools - Correct answers
var cell_nodes: Array[Array] = []    # mirror of controls [r][c] - UI elements

## Initialize the puzzle when the node is ready
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED  # Allow this to work while game is paused
	_build_rows()  # Create the 4 input combinations (TT, TF, FT, FF)
	_compute_correct()  # Calculate all correct answers
	_build_grid()  # Build the UI grid with buttons

	# Connect button signals
	check_btn.pressed.connect(_on_check)
	clear_btn.pressed.connect(_on_clear)
	close_btn.pressed.connect(_on_close)

## Open the overlay, pause the game, and show the puzzle
func open_overlay() -> void:
	# Pause world, show overlay, optional fade
	_was_paused = get_tree().paused
	get_tree().paused = true
	feedback.text = ""
	visible = true
	if anim and anim.has_animation("fade_in"):
		anim.play("fade_in")

## Close button handler - hides overlay and unpauses
func _on_close() -> void:
	if anim and anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished
	_hide_and_unpause()

## Hide the overlay and restore the previous pause state
func _hide_and_unpause() -> void:
	visible = false
	get_tree().paused = _was_paused

## Handle ESC key to close the overlay
func _unhandled_input(event: InputEvent) -> void:
	# Allow ESC / cancel to close overlay
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()

# ---------- Table construction ----------

## Build the 4 rows of input combinations for A and B
## Creates: (T,T), (T,F), (F,T), (F,F)
func _build_rows() -> void:
	rows = [
		{"A": true,  "B": true},
		{"A": true,  "B": false},
		{"A": false, "B": true},
		{"A": false, "B": false},
	]


## Compute the correct answers for all cells in the truth table
## For each row, calculates: A, B, ¬A, A∧B, A∨B, A→B, A↔B
func _compute_correct() -> void:
	correct.clear()
	for r in rows:
		var A: bool = bool(r["A"])
		var B: bool = bool(r["B"])
		correct.append([
			A,                  # A
			B,                  # B
			!A,                 # ¬A
			A and B,            # A ∧ B
			A or B,             # A ∨ B
			(not A) or B,       # A → B (false only when A=T and B=F)
			A == B              # A ↔ B (true when equal)
		])

## Build the visual grid with headers and input buttons
## Creates header row with column names, then 4 data rows
## A and B columns are pre-filled, others are toggle buttons for player input
func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
	grid.columns = COLS.size()

	# Header row - display column names
	for title in COLS:
		var h := Label.new()
		h.text = title
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_theme_font_size_override("font_size", 22)
		grid.add_child(h)

	# Body rows - create input cells
	cell_nodes.clear()
	for r_idx in range(rows.size()):
		var row_nodes: Array = []
		for c_idx in range(COLS.size()):
			if c_idx <= 1:
				# Prefilled A, B columns - show correct values in gray
				var lbl := Label.new()
				lbl.text = "T" if bool(correct[r_idx][c_idx]) else "F"
				lbl.modulate = Color(0.8, 0.8, 0.8)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				grid.add_child(lbl)
				row_nodes.append(lbl)
			else:
				# Player input toggle buttons - start with "?"
				var btn := Button.new()
				btn.toggle_mode = true
				btn.text = "?"
				btn.focus_mode = Control.FOCUS_ALL
				btn.pressed.connect(func():
					if btn.button_pressed:
						btn.text = "T"  # Button pressed = True
					else:
						btn.text = "F"  # Button not pressed = False
				)
				grid.add_child(btn)
				row_nodes.append(btn)
		cell_nodes.append(row_nodes)

# ---------- Buttons ----------

## Clear all player inputs back to "?"
func _on_clear() -> void:
	feedback.text = ""
	for r in cell_nodes:
		for n in r:
			if n is Button:
				var btn := n as Button
				btn.button_pressed = false
				btn.text = "?"
				btn.modulate = Color(1, 1, 1, 1)  # Reset color

## Check player's answers and provide feedback
## Compares player inputs with correct answers and highlights mistakes
func _on_check() -> void:
	var mistakes: int = 0
	for r in range(cell_nodes.size()):
		for c in range(cell_nodes[r].size()):
			var n: Control = cell_nodes[r][c]
			var should: bool = bool(correct[r][c])

			if n is Button:
				var btn := n as Button
				if btn.text == "?":
					mistakes += 1
					btn.modulate = Color(1, 0.55, 0.55, 1)   # light red - unanswered
				else:
					var val: bool = btn.button_pressed
					if val != should:
						mistakes += 1
						btn.modulate = Color(1, 0.4, 0.4, 1) # red - wrong answer
					else:
						btn.modulate = Color(0.6, 1, 0.6, 1) # green - correct answer

	if mistakes == 0:
		feedback.text = "All correct!"
		emit_signal("puzzle_solved")
		_on_close()  # Auto-close on success
	else:
		feedback.text = str(mistakes) + " cell(s) incorrect."  # Show error count
