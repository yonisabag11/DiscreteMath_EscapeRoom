extends Control

## Dialog box that displays text for interactions in the escape room
## This is a basic implementation - the main dialog system uses dialog_box_autoload.gd instead

# References to UI elements
@onready var panel = $Panel
@onready var text_label = $Panel/MarginContainer/VBoxContainer/RichTextLabel  # Displays the dialog text
@onready var continue_label = $Panel/MarginContainer/VBoxContainer/Label  # Shows "[Space] to continue" prompt

var current_text: String = ""  # Currently displayed text
var is_displaying: bool = false  # Whether the dialog is currently visible

signal dialog_finished  # Emitted when the player closes the dialog

# Initialize the dialog box as hidden
func _ready():
	hide_dialog()

# Show the dialog box with the given text
func show_dialog(text: String):
	current_text = text
	text_label.text = text
	panel.show()
	is_displaying = true
	
	# Optionally: add a typing effect here if you want
	# For now, text appears instantly

# Hide the dialog box
func hide_dialog():
	panel.hide()
	is_displaying = false
	current_text = ""

# Handle input to close the dialog
func _input(event):
	if is_displaying and event.is_action_pressed("ui_accept"):  # Space or Enter
		hide_dialog()
		dialog_finished.emit()
