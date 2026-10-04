class_name Shaft
extends Node2D
## The vertical way between the pit-head and the Level 1 landing. The mine
## entrance in town is a door onto the top of it.
## It starts as a slow ladder. Buying the lift makes the same cells fast.

@export var rail_color: Color = Color(0.6, 0.45, 0.25)
@export var lift_color: Color = Color(0.75, 0.75, 0.8)

## Terrain column the shaft runs down.
@export var column: int = 130

var has_lift: bool = false

var _nav: NavGrid
var _bottom_row: int = 0


## Carves the shaft from the surface down to `bottom_row` and makes it climbable.
func setup(nav: NavGrid, terrain: Terrain, bottom_row: int) -> void:
	_nav = nav
	_bottom_row = bottom_row
	position = Vector2(column * NavGrid.CELL, 0)
	for row: int in range(0, bottom_row + 1):
		terrain.set_cell(Vector2i(column, row), Terrain.Cell.AIR)
	_flag_cells(NavGrid.LADDER)
	queue_redraw()


## The cell at the top of the ladder, where the mine entrance lets out.
func top_cell() -> Vector2i:
	return Vector2i(column, -1)


func install_lift() -> void:
	has_lift = true
	_flag_cells(NavGrid.LIFT)
	queue_redraw()


func _flag_cells(climb_flag: int) -> void:
	# Row -1 is the surface cell above the hole, where dwarves step on and off.
	for row: int in range(-1, _bottom_row + 1):
		_nav.set_flags(Vector2i(column, row), NavGrid.WALK | climb_flag)


func _draw() -> void:
	var top: float = -NavGrid.CELL
	var bottom: float = (_bottom_row + 1) * NavGrid.CELL
	var color: Color = lift_color if has_lift else rail_color
	draw_rect(Rect2(1, top, 1, bottom - top), color)
	draw_rect(Rect2(NavGrid.CELL - 2, top, 1, bottom - top), color)
	if has_lift:
		return
	# Ladder rungs.
	var y: float = top + 2.0
	while y < bottom:
		draw_rect(Rect2(1, y, NavGrid.CELL - 2, 1), color)
		y += 4.0
