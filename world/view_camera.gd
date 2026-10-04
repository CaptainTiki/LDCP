class_name ViewCamera
extends Camera2D
## Views are camera framings of the one world, not separate scenes.
## Surface and Mine are two positions the camera jumps between and can be
## panned from. An Interior view locks onto one building's room.

signal view_changed

enum View { SURFACE, MINE, INTERIOR }

## World pixels of sky shown above the ground line in the surface view.
@export var sky_height: float = 122.0
## World pixels the camera moves per second when panned with the keys.
@export var key_pan_speed: float = 300.0

## The building whose interior is being shown, or null in the world views.
var interior_building: Building = null

var _world: World
## Which of the two outdoor framings the camera is at, or nearest to.
var _outdoor_view: View = View.SURFACE
## Where the camera was in the world before it went indoors.
var _outdoor_position: Vector2 = Vector2.ZERO


func setup(world: World) -> void:
	_world = world
	position.x = world.hall.position.x + world.hall.width_slots() * Placeable.SLOT_PIXELS * 0.5
	show_surface()


func _process(delta: float) -> void:
	var direction := Vector2(Input.get_axis(&"ui_left", &"ui_right"), Input.get_axis(&"ui_up", &"ui_down"))
	if direction != Vector2.ZERO:
		pan(direction * key_pan_speed * delta)


func current_view() -> View:
	return View.INTERIOR if interior_building != null else _outdoor_view


func show_surface() -> void:
	_leave_interior()
	_outdoor_view = View.SURFACE
	position.y = _surface_y()
	_changed()


func show_mine() -> void:
	_leave_interior()
	_outdoor_view = View.MINE
	position.y = _mine_y()
	_changed()


func show_interior(building: Building) -> void:
	if interior_building == null:
		_outdoor_position = position
	interior_building = building
	position = building.interior.view_rect().get_center()
	view_changed.emit()


## Moves the camera by a world-space offset. Ignored indoors.
func pan(offset: Vector2) -> void:
	if interior_building != null:
		return
	position += offset
	_clamp_to_world()
	# Panning far enough up or down the shaft changes which view this is.
	var nearest: View = View.SURFACE
	if absf(position.y - _mine_y()) < absf(position.y - _surface_y()):
		nearest = View.MINE
	if nearest != _outdoor_view:
		_outdoor_view = nearest
		view_changed.emit()


## Size of the visible part of the world, in world pixels.
func visible_size() -> Vector2:
	return get_viewport_rect().size / zoom


func _surface_y() -> float:
	return -sky_height + visible_size().y * 0.5


func _mine_y() -> float:
	return _world.mine_level.view_rect().get_center().y


func _leave_interior() -> void:
	if interior_building != null:
		interior_building = null
		position = _outdoor_position


func _changed() -> void:
	_clamp_to_world()
	view_changed.emit()


func _clamp_to_world() -> void:
	var area: Rect2 = _world.bounds()
	var half: Vector2 = visible_size() * 0.5
	position.x = _clamp_axis(position.x, area.position.x, area.end.x, half.x)
	position.y = _clamp_axis(position.y, area.position.y, area.end.y, half.y)


## Keeps the view inside [low, high]. If the view is bigger than the world
## on this axis, centres it instead.
func _clamp_axis(value: float, low: float, high: float, half_view: float) -> float:
	if high - low <= half_view * 2.0:
		return (low + high) * 0.5
	return clampf(value, low + half_view, high - half_view)
