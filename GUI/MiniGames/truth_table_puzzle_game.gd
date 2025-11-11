extends BaseMiniGame

# This scene is a "mini-game" used by InteractableObject + MiniGameManager.

const COLS: PackedStringArray = ["A","B","¬A","A ∧ B","A ∨ B","A → B","A ↔ B"]

@onready var grid: GridContainer = $Root/Center/Panel/TableGrid
@onready var feedback: Label = $Root/Center/Panel/Feedback
@onready var check_btn: Button = $Root/Center/Panel/Buttons/CheckButton
@onready var clear_btn: Button = $Root/Center/Panel/Buttons/ClearButton
@onready var close_btn: Button = $Root/Center/Panel/Buttons/CloseButton

var rows: Array[Dictionary] = []
var correct: Array[Array] = []
var cell_nodes: Array[Array] = []

func _ready() -> void:
	_build_rows()
	_compute_correct()
	_build_grid()
	check_btn.pressed.connect(_on_check_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	feedback.text = ""

# ---------- basic table data ----------

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
			A,          # A
			B,          # B
			!A,         # ¬A
			A and B,    # A ∧ B
			A or B,     # A ∨ B
			(not A) or B, # A → B
			A == B      # A ↔ B
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
		grid.add_child(h)

	# Body
	cell_nodes.clear()
	for r_idx in range(rows.size()):
		var row_nodes: Array = []
		for c_idx in range(COLS.size()):
			if c_idx <= 1:
				var lbl := Label.new()
				lbl.text = "T" if bool(correct[r_idx][c_idx]) else "F"
				lbl.modulate = Color(0.8,0.8,0.8)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				grid.add_child(lbl)
				row_nodes.append(lbl)
			else:
				var btn := Button.new()
				btn.toggle_mode = true
				btn.text = "?"
				btn.focus_mode = Control.FOCUS_ALL
				btn.pressed.connect(func():
					btn.text = "T" if btn.button_pressed else "F"
				)
				grid.add_child(btn)
				row_nodes.append(btn)
		cell_nodes.append(row_nodes)

# ---------- buttons ----------

func _on_clear_pressed() -> void:
	feedback.text = ""
	for row in cell_nodes:
		for n in row:
			if n is Button:
				var btn := n as Button
				btn.button_pressed = false
				btn.text = "?"
				btn.modulate = Color(1,1,1)

func _on_check_pressed() -> void:
	var mistakes := 0
	for r in range(cell_nodes.size()):
		for c in range(cell_nodes[r].size()):
			var n: Control = cell_nodes[r][c]
			var should: bool = bool(correct[r][c])
			if n is Button:
				var btn := n as Button
				if btn.text == "?":
					mistakes += 1
					btn.modulate = Color(1,0.55,0.55)
				else:
					var val: bool = btn.button_pressed
					if val != should:
						mistakes += 1
						btn.modulate = Color(1,0.4,0.4)
					else:
						btn.modulate = Color(0.6,1,0.6)

	if mistakes == 0:
		feedback.text = "All correct!"
		_signal_success_and_close(true)
	else:
		feedback.text = str(mistakes) + " incorrect cell(s)."

func _on_close_pressed() -> void:
	# Player closed without finishing
	_signal_closed()

# ---------- notify MiniGameManager ----------

func _signal_success_and_close(success: bool) -> void:
	# Tell MiniGameManager this mini-game was completed successfully.
	if Engine.has_singleton("MiniGameManager"):
		var mgr = Engine.get_singleton("MiniGameManager")
		if mgr.has_signal("mini_game_completed"):
			mgr.emit_signal("mini_game_completed", success)
	_queue_close()

func _signal_closed() -> void:
	# Tell MiniGameManager the mini-game was closed without completion.
	if Engine.has_singleton("MiniGameManager"):
		var mgr = Engine.get_singleton("MiniGameManager")
		if mgr.has_signal("mini_game_closed"):
			mgr.emit_signal("mini_game_closed")
	_queue_close()

func _queue_close() -> void:
	queue_free()
