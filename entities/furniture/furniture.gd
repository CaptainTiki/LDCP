class_name Furniture
extends Node2D
## A table, chair or the like standing in a room. The node's origin is the
## top-left corner of its footprint. The room owns the rules about where it
## may go; this only knows where it is, which way it faces, and who is
## sitting on it.

## Set by the room when placed, or on the instance for authored furniture.
@export var def: FurnitureDef
## Top-left cell of the footprint, counted from the room's floor corner.
@export var cell: Vector2i = Vector2i.ZERO
## Quarter turns clockwise from how the sprite is drawn, 0..3.
@export_range(0, 3) var facing: int = 0

## The dwarf using this seat, or null. Only seats are ever occupied.
var occupant: Node = null

@onready var _sprite: Sprite2D = $Sprite


## The footprint after turning: odd quarter turns swap width and height.
static func turned_size(footprint: Vector2i, quarter_turns: int) -> Vector2i:
	return Vector2i(footprint.y, footprint.x) if quarter_turns % 2 == 1 else footprint


func place(new_cell: Vector2i, new_facing: int) -> void:
	cell = new_cell
	facing = new_facing % 4
	position = Vector2(cell * NavGrid.CELL)
	# The sprite turns about the middle of the (turned) footprint.
	_sprite.position = Vector2(size() * NavGrid.CELL) * 0.5
	_sprite.rotation_degrees = 90.0 * facing


func size() -> Vector2i:
	return turned_size(def.footprint, facing)


## The footprint in room cells.
func rect() -> Rect2i:
	return Rect2i(cell, size())


func is_free_seat(for_dwarf: Node) -> bool:
	if not def.is_seat:
		return false
	return occupant == null or occupant == for_dwarf or not is_instance_valid(occupant)
