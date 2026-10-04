class_name ViewCamera
extends Camera2D
## There are three kinds of view, and the camera jumps between them: the
## town (top-down), the mine (side-on) and one building's interior
## (top-down). The town and the mine can each be panned within their own
## bounds. You never scroll from one into another.

signal view_changed

enum View { SURFACE, MINE, INTERIOR }

## World pixels the camera moves per second when panned with the keys.
@export var key_pan_speed: float = 300.0

## The building whose interior is being shown, or null outdoors.
var interior_building: Building = null

var _world: World
var _outdoor_view: View = View.SURFACE
## Where the camera was last looking in each outdoor view.
var _saved_positions: Dictionary[View, Vector2] = {}


func setup(world: World) -> void:
	_world = world
	# Start in town, looking at the Great Hall.
	position = world.hall.global_position
	var shaft_x: float = NavGrid.cell_to_world(world.shaft.top_cell()).x
	_saved_positions[View.MINE] = Vector2(shaft_x, world.mine_level.view_rect().get_center().y)
	show_surface()


func _process(delta: float) -> void:
	var direction := Vector2(Input.get_axis(&"ui_left", &"ui_right"), Input.get_axis(&"ui_up", &"ui_down"))
	if direction != Vector2.ZERO:
		pan(direction * key_pan_speed * delta)


func current_view() -> View:
	return View.INTERIOR if interior_building != null else _outdoor_view


func show_surface() -> void:
	_show_outdoors(View.SURFACE)


func show_mine() -> void:
	_show_outdoors(View.MINE)


func show_interior(building: Building) -> void:
	_remember_position()
	interior_building = building
	position = building.interior.view_rect().get_center()
	view_changed.emit()


## Moves the camera by a world-space offset. Ignored indoors.
func pan(offset: Vector2) -> void:
	if interior_building != null:
		return
	position += offset
	_clamp_to_view()


## Size of the visible part of the world, in world pixels.
func visible_size() -> Vector2:
	return get_viewport_rect().size / zoom


func _show_outdoors(view: View) -> void:
	_remember_position()
	interior_building = null
	_outdoor_view = view
	position = _saved_positions[view]
	_clamp_to_view()
	view_changed.emit()


func _remember_position() -> void:
	if interior_building == null:
		_saved_positions[_outdoor_view] = position


func _clamp_to_view() -> void:
	var area: Rect2 = _world.surface.view_rect()
	if _outdoor_view == View.MINE:
		area = _world.mine_view_rect()
	var half: Vector2 = visible_size() * 0.5
	position.x = _clamp_axis(position.x, area.position.x, area.end.x, half.x)
	position.y = _clamp_axis(position.y, area.position.y, area.end.y, half.y)


## Keeps the view inside [low, high]. If the view is bigger than the area
## on this axis, centres it instead.
func _clamp_axis(value: float, low: float, high: float, half_view: float) -> float:
	if high - low <= half_view * 2.0:
		return (low + high) * 0.5
	return clampf(value, low + half_view, high - half_view)
