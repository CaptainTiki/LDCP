class_name CursorCard
extends PanelContainer
## A small card that sits beside the mouse cursor, flipping to the other
## side near the screen edges. It never catches the mouse.

## Gap between the cursor and the card, in UI pixels.
const CURSOR_GAP: Vector2 = Vector2(8, 8)


func follow_cursor() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var cursor: Vector2 = get_global_mouse_position()
	var spot: Vector2 = cursor + CURSOR_GAP
	if spot.x + size.x > screen.x:
		spot.x = cursor.x - CURSOR_GAP.x - size.x
	spot = spot.clamp(Vector2.ZERO, (screen - size).max(Vector2.ZERO))
	global_position = spot.round()
