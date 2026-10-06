class_name ZigzagTabs
extends Container
## Tab buttons in two staggered columns: the first top right, the next a
## half step down on the left, the next a half step further on the right,
## and so on. Twice as many tabs fit down the side panel's edge as in one
## column. Hidden buttons are skipped, so the zigzag closes up as tabs come
## and go (indoors, only the room tab shows).

## How far each button sits below the one before it, in UI pixels. Half a
## tab's height plus a pixel keeps a gap between buttons in the same column.
@export var step: int = 11
@export var column_gap: int = 1


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var width: float = _column_width()
	var buttons: Array[Control] = _shown()
	for i: int in buttons.size():
		var on_right: bool = i % 2 == 0
		var spot: Vector2 = Vector2(width + column_gap if on_right else 0.0, i * step)
		fit_child_in_rect(buttons[i], Rect2(spot, Vector2(width, buttons[i].get_combined_minimum_size().y)))


func _get_minimum_size() -> Vector2:
	var height: float = 0.0
	var buttons: Array[Control] = _shown()
	for i: int in buttons.size():
		height = maxf(height, i * step + buttons[i].get_combined_minimum_size().y)
	return Vector2(_column_width() * 2.0 + column_gap, height)


func _column_width() -> float:
	var width: float = 0.0
	for button: Control in _shown():
		width = maxf(width, button.get_combined_minimum_size().x)
	return width


func _shown() -> Array[Control]:
	var shown: Array[Control] = []
	for child: Node in get_children():
		var control: Control = child as Control
		if control != null and control.visible:
			shown.append(control)
	return shown
