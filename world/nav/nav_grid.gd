class_name NavGrid
extends Node
## The set of cells a dwarf can stand in, and how to get between them.
##
## The grid does not know *why* a cell is walkable. Each part of the world
## registers its own cells: the surface its ground row, the shaft its ladder,
## the mine terrain its tunnels, building interiors their floors. Doors are
## portals that join two far-apart cells.
##
## Two kinds of place share the grid. The mine is seen from the side: dwarves
## walk left and right, take one-cell steps, and only climb on ladders. The
## town and building interiors are seen from above (TOP_DOWN cells): dwarves
## walk in any direction across open floor.

## Size of one nav cell in world pixels.
const CELL: int = 8
## Stand-in for "no cell".
const NO_CELL: Vector2i = Vector2i(-99999, -99999)

const WALK: int = 1
const LADDER: int = 2
const LIFT: int = 4
const TOP_DOWN: int = 8

const _ORTHOGONAL: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const _DIAGONAL: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]

var _cells: Dictionary[Vector2i, int] = {}
var _portals: Dictionary[Vector2i, Vector2i] = {}


## World position of a dwarf's feet when standing in the cell.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, (cell.y + 1) * CELL)


static func world_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL), floori(point.y / CELL))


## Adds flags to a cell, keeping any it already has.
func set_walkable(cell: Vector2i, flags: int = WALK) -> void:
	_cells[cell] = _cells.get(cell, 0) | flags


## Replaces a cell's flags outright.
func set_flags(cell: Vector2i, flags: int) -> void:
	_cells[cell] = flags


func clear_walkable(cell: Vector2i) -> void:
	_cells.erase(cell)


func is_walkable(cell: Vector2i) -> bool:
	return _cells.has(cell)


## True for ladder and lift cells: the only places dwarves move vertically.
func is_climbable(cell: Vector2i) -> bool:
	return (_cells.get(cell, 0) & (LADDER | LIFT)) != 0


func is_lift(cell: Vector2i) -> bool:
	return (_cells.get(cell, 0) & LIFT) != 0


func is_top_down(cell: Vector2i) -> bool:
	return (_cells.get(cell, 0) & TOP_DOWN) != 0


func link_portal(a: Vector2i, b: Vector2i) -> void:
	_portals[a] = b
	_portals[b] = a


func unlink_portal(a: Vector2i) -> void:
	if _portals.has(a):
		_portals.erase(_portals[a])
		_portals.erase(a)


func is_portal(from: Vector2i, to: Vector2i) -> bool:
	return _portals.get(from, NO_CELL) == to


func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if is_top_down(cell):
		_add_top_down_neighbors(cell, result)
	else:
		_add_side_view_neighbors(cell, result)
	if _portals.has(cell):
		result.append(_portals[cell])
	return result


func _add_top_down_neighbors(cell: Vector2i, result: Array[Vector2i]) -> void:
	for offset: Vector2i in _ORTHOGONAL:
		if is_top_down(cell + offset):
			result.append(cell + offset)
	# Diagonals only where neither corner is cut.
	for offset: Vector2i in _DIAGONAL:
		var open_x: bool = is_top_down(cell + Vector2i(offset.x, 0))
		var open_y: bool = is_top_down(cell + Vector2i(0, offset.y))
		if open_x and open_y and is_top_down(cell + offset):
			result.append(cell + offset)


func _add_side_view_neighbors(cell: Vector2i, result: Array[Vector2i]) -> void:
	# Sideways, including one-cell steps up and down (slopes and planks).
	for dx: int in [-1, 1]:
		for dy: int in [0, -1, 1]:
			var side: Vector2i = cell + Vector2i(dx, dy)
			if is_walkable(side):
				result.append(side)
	if is_climbable(cell):
		for dy: int in [-1, 1]:
			var rung: Vector2i = cell + Vector2i(0, dy)
			if is_climbable(rung):
				result.append(rung)


func are_connected(from: Vector2i, to: Vector2i) -> bool:
	return neighbors(from).has(to)


## Breadth-first search. Returns the cells to step through, ending at `to`
## and not including `from`. Empty when already there or unreachable.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	# `from` need not be walkable: a dwarf caught under a new building can
	# still walk out of it.
	if from == to or not is_walkable(to):
		return path
	var came_from: Dictionary[Vector2i, Vector2i] = {from: from}
	var frontier: Array[Vector2i] = [from]
	var next_index: int = 0
	while next_index < frontier.size() and not came_from.has(to):
		var current: Vector2i = frontier[next_index]
		next_index += 1
		for next: Vector2i in neighbors(current):
			if not came_from.has(next):
				came_from[next] = current
				frontier.append(next)
	if not came_from.has(to):
		return path
	var step: Vector2i = to
	while step != from:
		path.append(step)
		step = came_from[step]
	path.reverse()
	return path
