class_name GridMover
extends Node
## Walks a dwarf cell by cell along a NavGrid path. Movement advances on sim
## ticks. `previous_position` and `position` let the visuals glide between.

var walk_speed: float = 24.0
var ladder_speed: float = 8.0
var lift_speed: float = 64.0
## Time spent stepping through a door.
var portal_seconds: float = 0.3

var nav: NavGrid
## The cell the dwarf is in, or is leaving if mid-step.
var cell: Vector2i = NavGrid.NO_CELL
var position: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO
## 1 when facing right, -1 when facing left.
var facing: int = 1

var _path: Array[Vector2i] = []
var _step_progress: float = 0.0
var _destination: Vector2i = NavGrid.NO_CELL


## Drops the dwarf on a cell with no walking involved.
func place_at(new_cell: Vector2i) -> void:
	cell = new_cell
	stop()
	position = NavGrid.cell_to_world(cell)
	previous_position = position


func stop() -> void:
	_path.clear()
	_step_progress = 0.0
	_destination = NavGrid.NO_CELL


func is_moving() -> bool:
	return not _path.is_empty()


## True once standing still on `target`.
func is_at(target: Vector2i) -> bool:
	return cell == target and _path.is_empty()


## Heads for `target`. Safe to call every tick: the route is only planned
## when the destination changes. Returns false if there is no way there.
func travel_to(target: Vector2i) -> bool:
	if is_at(target) or (is_moving() and target == _destination):
		return true
	# If we are mid-step, finish that step first and route on from there.
	var mid_step: bool = is_moving() and _step_progress > 0.0
	var start: Vector2i = _path[0] if mid_step else cell
	var route: Array[Vector2i] = nav.find_path(start, target)
	if route.is_empty() and start != target:
		return false
	if mid_step:
		route.push_front(start)
	_path = route
	_destination = target
	return true


func is_on_lift() -> bool:
	return is_moving() and _path[0].x == cell.x and nav.is_lift(_path[0])


func sim_tick(delta: float) -> void:
	previous_position = position
	var time_left: float = delta
	while time_left > 0.0 and not _path.is_empty():
		var next: Vector2i = _path[0]
		# The world may have changed under us (a building moved or was removed).
		if _step_progress == 0.0 and not nav.are_connected(cell, next):
			stop()
			break
		var step_seconds: float = _step_seconds(cell, next)
		var seconds_to_finish: float = (1.0 - _step_progress) * step_seconds
		if time_left >= seconds_to_finish:
			time_left -= seconds_to_finish
			_finish_step(next)
		else:
			_step_progress += time_left / step_seconds
			time_left = 0.0
	position = _current_position()


func _finish_step(next: Vector2i) -> void:
	if next.x != cell.x and not nav.is_portal(cell, next):
		facing = 1 if next.x > cell.x else -1
	cell = next
	_path.remove_at(0)
	_step_progress = 0.0
	if _path.is_empty():
		_destination = NavGrid.NO_CELL


func _step_seconds(from: Vector2i, to: Vector2i) -> float:
	if nav.is_portal(from, to):
		return portal_seconds
	var distance: float = NavGrid.cell_to_world(from).distance_to(NavGrid.cell_to_world(to))
	if from.x == to.x:
		return distance / (lift_speed if nav.is_lift(to) else ladder_speed)
	return distance / walk_speed


func _current_position() -> Vector2:
	var here: Vector2 = NavGrid.cell_to_world(cell)
	if _path.is_empty() or nav.is_portal(cell, _path[0]):
		return here
	return here.lerp(NavGrid.cell_to_world(_path[0]), _step_progress)
