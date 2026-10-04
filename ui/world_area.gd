class_name WorldArea
extends Control
## The part of the screen that is "the world": everything not covered by a
## panel. It turns mouse input into world positions for WorldInput, pans the
## camera, and is where roster entries are dropped to assign dwarves.

## World pixels the view moves per mouse-wheel notch.
@export var wheel_pan: float = 24.0

var _world: World
var _is_panning: bool = false


func setup(world: World) -> void:
	_world = world


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		_on_button(button)
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		if _is_panning:
			_world.camera.pan(-motion.relative / _world.camera.zoom)
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_world.input.drag(_to_world(motion.position))
		_world.input.hover(_to_world(motion.position))


func _on_button(button: InputEventMouseButton) -> void:
	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if button.pressed:
				_world.input.click(_to_world(button.position))
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			# Right-click puts away whatever tool is in hand. Otherwise drag to pan.
			if button.pressed and _world.build_tool.is_active():
				_world.build_tool.cancel()
			elif button.pressed and _world.furniture_tool.is_active():
				_world.furniture_tool.cancel()
			elif button.pressed and _world.hand.is_holding_tool():
				_world.hand.put_away()
			else:
				_is_panning = button.pressed
		MOUSE_BUTTON_WHEEL_UP:
			_world.camera.pan(Vector2(0, -wheel_pan))
		MOUSE_BUTTON_WHEEL_DOWN:
			_world.camera.pan(Vector2(0, wheel_pan))


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dwarf and _world.input.can_assign_at(_to_world(at_position))


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_world.input.assign_at(data as Dwarf, _to_world(at_position))


func _to_world(screen_point: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_point
