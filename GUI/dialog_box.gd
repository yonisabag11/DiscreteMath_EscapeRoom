extends Control

# Dialog box that displays text for interactions in the escape room

@onready var panel = $Panel
@onready var text_label = $Panel/MarginContainer/VBoxContainer/RichTextLabel
@onready var continue_label = $Panel/MarginContainer/VBoxContainer/Label

var current_text: String = ""
var is_displaying: bool = false

signal dialog_finished

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
