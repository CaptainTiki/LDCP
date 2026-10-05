class_name Shaft
extends Node2D
## The vertical way between the pit-head and the mine. The mine entrance in
## town is a door onto the top of it.
## It starts short, down through the dirt to the landing, and miners dig it
## deeper as the mine needs room. It starts as a slow ladder; buying the
## lift makes the same cells fast.

@export var ladder_texture: Texture2D
@export var lift_texture: Texture2D

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
	_flag_cells(_climb_flag())
	queue_redraw()


## The cell at the top of the ladder, where the mine entrance lets out.
func top_cell() -> Vector2i:
	return Vector2i(column, -1)


## The ladder's lowest rung.
func bottom_cell() -> Vector2i:
	return Vector2i(column, _bottom_row)


## A miner has dug out the cell under the ladder: the ladder reaches down
## into it.
func deepen() -> void:
	_bottom_row += 1
	_nav.set_flags(bottom_cell(), NavGrid.WALK | _climb_flag())
	queue_redraw()


func install_lift() -> void:
	has_lift = true
	_flag_cells(_climb_flag())
	queue_redraw()


func _climb_flag() -> int:
	return NavGrid.LIFT if has_lift else NavGrid.LADDER


func _flag_cells(climb_flag: int) -> void:
	# Row -1 is the surface cell above the hole, where dwarves step on and off.
	for row: int in range(-1, _bottom_row + 1):
		_nav.set_flags(Vector2i(column, row), NavGrid.WALK | climb_flag)


func _draw() -> void:
	var top: float = -NavGrid.CELL
	var bottom: float = (_bottom_row + 1) * NavGrid.CELL
	var texture: Texture2D = lift_texture if has_lift else ladder_texture
	draw_texture_rect(texture, Rect2(0, top, NavGrid.CELL, bottom - top), true)
