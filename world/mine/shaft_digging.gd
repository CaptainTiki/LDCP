class_name ShaftDigging
extends RefCounted
## Where new tunnels come from once the landing's two are taken: the shaft.
##
## A miner with no tunnel end to work opens a new tunnel off the side of the
## shaft, at the shallowest height with room for one. If there is no room,
## he digs the shaft deeper until there is. So the ladder only grows as the
## mine needs it, and the climb gets longer as the mine does.

var _shaft: Shaft
var _safety: DigSafety
var _def: MineLevelDef
var _top_row: int
## The side the next branch tries first, so they alternate. 1 = east.
var _next_side: int = -1


func _init(shaft: Shaft, safety: DigSafety, def: MineLevelDef, top_row: int) -> void:
	_shaft = shaft
	_safety = safety
	_def = def
	_top_row = top_row


## The head that digs the shaft down, one cell at a time, standing on the
## bottom rung.
func make_shaft_head() -> DigHead:
	var head := DigHead.new()
	head.is_shaft = true
	head.stand_cell = _shaft.bottom_cell()
	return head


## Reserves the cell under the ladder. False once the shaft can go no deeper.
func plan(head: DigHead) -> bool:
	var below: Vector2i = head.stand_cell + Vector2i.DOWN
	if not _safety.cell_ok(below):
		return false
	_safety.reserve_cell(head, below)
	return true


## The cell under the ladder has been dug: the ladder reaches down into it.
func deepen(head: DigHead) -> void:
	_shaft.deepen()
	head.stand_cell = _shaft.bottom_cell()


## A new tunnel leaving the shaft at the shallowest height with room for it,
## not yet planned. Null if there is no room yet.
func open_branch() -> DigHead:
	var spot: Vector2i = _find_spot()
	if spot == NavGrid.NO_CELL:
		return null
	var head := DigHead.new()
	head.stand_cell = Vector2i(_shaft.column, spot.y)
	head.direction = spot.x
	head.straight_left = _def.branch_straight_columns
	_next_side = -spot.x
	return head


func has_branch_spot() -> bool:
	return _find_spot() != NavGrid.NO_CELL


## The side (x) and floor row (y) of the shallowest spot a branch fits.
func _find_spot() -> Vector2i:
	for row: int in range(_top_row + 2, _shaft.bottom_cell().y + 1):
		for side: int in [_next_side, -_next_side]:
			if _branch_fits(row, side):
				return Vector2i(side, row)
	return NavGrid.NO_CELL


## Room for a two-tall tunnel with its floor on `feet_row`, at least the
## branch gap away from any other tunnel leaving this side of the shaft.
func _branch_fits(feet_row: int, side: int) -> bool:
	var column: int = _shaft.column + side
	var gap: int = _def.branch_gap_rows
	for row: int in range(maxi(_top_row, feet_row - 1 - gap), feet_row + gap + 1):
		if not _safety.is_untouched(Vector2i(column, row)):
			return false
	return _safety.span_ok(column, feet_row - 1, feet_row)
