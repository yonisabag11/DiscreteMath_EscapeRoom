extends BaseMiniGame

## Truth Table Mini-Game
## Player must correctly complete the truth table for A, B with ¬, ∧, ∨, →, ↔.
## Player has a limited number of attempts; on final failure they lose a heart,

# -------------------------------
# CONFIG
# -------------------------------

const COLS: PackedStringArray = ["A", "B", "¬A", "A ∧ B", "A ∨ B", "A → B", "A ↔ B"]

@export var max_attempts: int = 3  # attempts allowed, like the affine mini-game

# -------------------------------
# STATE
# -------------------------------

var rows: Array[Dictionary] = []
var correct: Array[Array] = []      # 4 x 7 matrix of bools
var cell_nodes: Array[Array] = []   # matching Controls [row][col]

var attempts_made: int = 0

# -------------------------------
# UI NODES
# -------------------------------

@onready var panel: Panel = $Root/Center/Panel
@onready var grid: GridContainer = $Root/Center/Panel/TableGrid
@onready var feedback_label: Label = $Root/Center/Panel/Feedback
@onready var attempts_label: Label = $Root/Center/Panel/AttemptsLabel
@onready var check_button: Button = $Root/Center/Panel/Buttons/CheckButton
@onready var clear_button: Button = $Root/Center/Panel/Buttons/ClearButton
@onready var close_button: Button = $Root/Center/Panel/Buttons/CloseButton
@onready var color_rect: ColorRect = $Root/ColorRect

# -------------------------------
# LIFECYCLE
# -------------------------------

func _ready() -> void:
	# BaseMiniGame may set up input, transitions, etc.
	super._ready()
	
	# Connect UI signals
	check_button.pressed.connect(_on_check_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	close_button.pressed.connect(_on_close_pressed)


func start_game() -> void:
	# Called by MiniGameManager when shown, just like in your affine cipher mini-game.
	super.start_game()
	
	attempts_made = 0
	feedback_label.text = ""
	_update_attempts_display()
	
	# Ensure UI visible
	panel.show()
	if is_instance_valid(color_rect):
		color_rect.show()
	
	_build_rows()
	_compute_correct()
	_build_grid()


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
		
		correct.append([
			A,                 # A
			B,                 # B
			!A,                # ¬A
			A and B,           # A ∧ B
			A or B,            # A ∨ B
			(not A) or B,      # A → B
			A == B             # A ↔ B
		])


func _build_grid() -> void:
	# Clear old content
	for child in grid.get_children():
		child.queue_free()
	
	grid.columns = COLS.size()
	cell_nodes.clear()
	
	# Header row
	for title in COLS:
		var lbl := Label.new()
		lbl.text = title
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		grid.add_child(lbl)
	
	# Body rows
	for r_idx in range(rows.size()):
		var row_nodes: Array = []
		
		for c_idx in range(COLS.size()):
			if c_idx <= 1:
				# Given columns A, B
				var given_lbl := Label.new()
				given_lbl.text = "T" if bool(correct[r_idx][c_idx]) else "F"
				given_lbl.modulate = Color(0.8, 0.8, 0.8)
				given_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				given_lbl.add_theme_font_size_override("font_size", 12)
				grid.add_child(given_lbl)
				row_nodes.append(given_lbl)
			else:
				# Player input cells
				var btn := Button.new()
				btn.toggle_mode = true
				btn.text = "?"
				btn.custom_minimum_size = Vector2(20, 14)
				btn.add_theme_font_size_override("font_size", 12)
				
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
	for row in cell_nodes:
		for n in row:
			if n is Button:
				var btn := n as Button
				btn.button_pressed = false
				btn.text = "?"


func _on_close_pressed() -> void:
	# Player chose to exit without solving; treat as failure so they can retry later.
	complete_game(false)
	queue_free()


func _on_check_pressed() -> void:
	var mistakes := 0
	
	# Count mistakes ONLY (no coloring)
	for r in range(cell_nodes.size()):
		for c in range(cell_nodes[r].size()):
			var n: Control = cell_nodes[r][c]
			var should: bool = bool(correct[r][c])
			
			if n is Button:
				var btn := n as Button
				
				if btn.text == "?":
					mistakes += 1
				else:
					var val: bool = btn.button_pressed
					if val != should:
						mistakes += 1
	
	# ------------------------------
	# SUCCESS
	# ------------------------------
	if mistakes == 0:
		feedback_label.text = "✓ Correct! Truth table completed."
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		
		# Disable buttons while we pause briefly
		check_button.disabled = true
		clear_button.disabled = true
		close_button.disabled = true
		
		await get_tree().create_timer(1.2).timeout
		complete_game(true)
		return
	
	# ------------------------------
	# FAILURE ATTEMPT
	# ------------------------------
	attempts_made += 1
	var remaining := max_attempts - attempts_made
	
	if attempts_made >= max_attempts:
		# Out of attempts → lose heart (same logic pattern as affine cipher game)
		check_button.disabled = true
		clear_button.disabled = true
		
		var last_heart := false
		if has_node("/root/HealthManager"):
			last_heart = HealthManager.will_lose_last_heart()
		
		if last_heart:
			feedback_label.text = "✗ Wrong. You ran out of attempts and lost your last heart."
			feedback_label.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(1.2).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			# Let the main game handle Game Over scene; here we just end as failure.
			complete_game(false)
		else:
			feedback_label.text = "✗ Wrong. You lost a heart."
			feedback_label.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(1.0).timeout
			if has_node("/root/HealthManager"):
				HealthManager.lose_heart()
			complete_game(false)
	else:
		# Still have attempts left
		feedback_label.text = "✗ Incorrect. Try again!"
		feedback_label.add_theme_color_override("font_color", Color.RED)
		_update_attempts_display()


func _update_attempts_display() -> void:
	var remaining := max_attempts - attempts_made
	attempts_label.text = "Attempts remaining: " + str(remaining)
