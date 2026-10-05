class_name DigSafety
extends RefCounted
## The rule that keeps dwarves from ever being trapped, and the bookkeeping
## behind it.
##
## A run of cells is only dug if the cell above it and the cell below it are
## solid and stay solid. So no dig can take the floor out from under an
## existing tunnel, and every new column is a single step away from the one
## before it. Cells some head is about to dig, or needs to stay solid, are
## reserved so two heads can't undermine each other.

var _terrain: Terrain
var _bounds: Rect2i
var _reserved_dig: Dictionary[Vector2i, bool] = {}
var _reserved_solid: Dictionary[Vector2i, bool] = {}


func _init(terrain: Terrain, bounds: Rect2i) -> void:
	_terrain = terrain
	_bounds = bounds


## Can rows top_row..bottom_row of `column` be dug, with the cell above and
## the cell below left solid? The level's outer rows and columns never are.
func span_ok(column: int, top_row: int, bottom_row: int) -> bool:
	if column <= _bounds.position.x or column >= _bounds.end.x - 1:
		return false
	if top_row - 1 < _bounds.position.y or bottom_row + 1 >= _bounds.end.y:
		return false
	for row: int in range(top_row, bottom_row + 1):
		var cell := Vector2i(column, row)
		if not _terrain.is_diggable(cell) or _reserved_dig.has(cell) or _reserved_solid.has(cell):
			return false
	for cap: Vector2i in [Vector2i(column, top_row - 1), Vector2i(column, bottom_row + 1)]:
		if _terrain.is_open(cap) or _reserved_dig.has(cap):
			return false
	return true


## Ground that is still there and that no head is about to dig.
func is_untouched(cell: Vector2i) -> bool:
	return not _terrain.is_open(cell) and not _reserved_dig.has(cell)


## Can this one cell be dug on its own? Only the shaft digs like this: the
## cells either side of it belong to nobody, and what's above is ladder.
func cell_ok(cell: Vector2i) -> bool:
	if cell.y + 1 >= _bounds.end.y:
		return false
	return _terrain.is_diggable(cell) and not _reserved_dig.has(cell) and not _reserved_solid.has(cell)


## Marks rows top_row..bottom_row of `column` for `head` to dig, top first,
## and the cells above and below to stay solid.
func reserve(head: DigHead, column: int, top_row: int, bottom_row: int) -> void:
	head.pending.clear()
	# Dig from the top down so the miner always has a floor to stand by.
	for row: int in range(top_row, bottom_row + 1):
		var cell := Vector2i(column, row)
		head.pending.append(cell)
		head.reserved_dig.append(cell)
		_reserved_dig[cell] = true
	for cap: Vector2i in [Vector2i(column, top_row - 1), Vector2i(column, bottom_row + 1)]:
		head.reserved_solid.append(cap)
		_reserved_solid[cap] = true


## Marks one cell for the shaft to dig.
func reserve_cell(head: DigHead, cell: Vector2i) -> void:
	head.pending.clear()
	head.pending.append(cell)
	head.reserved_dig.append(cell)
	_reserved_dig[cell] = true


func unreserve(head: DigHead) -> void:
	for cell: Vector2i in head.reserved_dig:
		_reserved_dig.erase(cell)
	for cell: Vector2i in head.reserved_solid:
		_reserved_solid.erase(cell)
	head.reserved_dig.clear()
	head.reserved_solid.clear()
