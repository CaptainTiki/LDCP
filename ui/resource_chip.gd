class_name ResourceChip
extends PanelContainer
## An icon and a number in the top bar.

@onready var _icon: TextureRect = $Row/Icon
@onready var _value: Label = $Row/Value


func setup(icon: Texture2D, tip: String) -> void:
	_icon.texture = icon
	tooltip_text = tip


func set_value(value: int) -> void:
	_value.text = str(value)
