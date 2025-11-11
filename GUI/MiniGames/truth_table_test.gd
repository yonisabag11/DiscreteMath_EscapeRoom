extends Control
class_name PuzzleOverlay

signal puzzle_solved

@onready var panel: Panel = $Root/Center/Panel
@onready var grid: GridContainer = $Root/Center/Panel/TableGrid
@onready var feedback: Label = $Root/Center/Panel/Feedback
@onready var check_btn: Button = $Root/Center/Panel/Buttons/CheckButton
@onready var clear_btn: Button = $Root/Center/Panel/Buttons/ClearButton
@onready var close_btn: Button = $Root/Center/Panel/Buttons/CloseButton
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

# Keep this overlay responsive while the rest of the game is paused
var _was_paused: bool = false

const COLS: PackedStringArray = ["A","B","¬A","A ∧ B","A ∨ B","A → B","A ↔ B"]

var rows: Array[Dictionary] = []     # [{A: true, B: true}, ...]
var correct: Array[Array] = []       # 4 x 7 matrix of bools
var cell_nodes: Array[Array] = []    # mirror of controls [r][c]

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_rows()
	_compute_correct()
	_build_grid()

	check_btn.pressed.connect(_on_check)
	clear_btn.pressed.connect(_on_clear)
	close_btn.pressed.connect(_on_close)

func open_overlay() -> void:
	# Pause world, show overlay, optional fade
	_was_paused = get_tree().paused
	get_tree().paused = true
	feedback.text = ""
	visible = true
	if anim and anim.has_animation("fade_in"):
		anim.play("fade_in")

func _on_close() -> void:
	if anim and anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished
	_hide_and_unpause()

func _hide_and_unpause() -> void:
	visible = false
	get_tree().paused = _was_paused

func _unhandled_input(event: InputEvent) -> void:
	# Allow ESC / cancel to close overlay
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()

# ---------- Table construction ----------

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
			A,                  # A
			B,                  # B
			!A,                 # ¬A
			A and B,            # A ∧ B
			A or B,             # A ∨ B
			(not A) or B,       # A → B (false only when A=T and B=F)
			A == B              # A ↔ B (true when equal)
		])

func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
	grid.columns = COLS.size()

	# Header row
	for title in COLS:
		var h := Label.new()
		h.text = title
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_theme_font_size_override("font_size", 22)
		grid.add_child(h)

	# Body
	cell_nodes.clear()
	for r_idx in range(rows.size()):
		var row_nodes: Array = []
		for c_idx in range(COLS.size()):
			if c_idx <= 1:
				# Prefilled A, B
				var lbl := Label.new()
				lbl.text = "T" if bool(correct[r_idx][c_idx]) else "F"
				lbl.modulate = Color(0.8, 0.8, 0.8)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				grid.add_child(lbl)
				row_nodes.append(lbl)
			else:
				# Player input toggle
				var btn := Button.new()
				btn.toggle_mode = true
				btn.text = "?"
				btn.focus_mode = Control.FOCUS_ALL
				btn.pressed.connect(func():
					if btn.button_pressed:
						btn.text = "T"
					else:
						btn.text = "F"
				)
				grid.add_child(btn)
				row_nodes.append(btn)
		cell_nodes.append(row_nodes)

# ---------- Buttons ----------

func _on_clear() -> void:
	feedback.text = ""
	for r in cell_nodes:
		for n in r:
			if n is Button:
				var btn := n as Button
				btn.button_pressed = false
				btn.text = "?"
				btn.modulate = Color(1, 1, 1, 1)

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
					btn.modulate = Color(1, 0.55, 0.55, 1)   # light red
				else:
					var val: bool = btn.button_pressed
					if val != should:
						mistakes += 1
						btn.modulate = Color(1, 0.4, 0.4, 1) # red
					else:
						btn.modulate = Color(0.6, 1, 0.6, 1) # green

	if mistakes == 0:
		feedback.text = "All correct!"
		emit_signal("puzzle_solved")
		_on_close()
	else:
		feedback.text = str(mistakes) + " cell(s) incorrect."
