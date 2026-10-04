class_name FoldButton
extends Button
## Folds a panel away and back out by hiding its body.

@export var target: Control
@export var open_text: String = "<"
@export var closed_text: String = ">"


func _ready() -> void:
	_update_text()


func _pressed() -> void:
	target.visible = not target.visible
	_update_text()


func _update_text() -> void:
	text = open_text if target.visible else closed_text
