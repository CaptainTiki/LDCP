class_name Furniture
extends Node2D
## A table, chair or the like standing in a room. The node's origin is the
## top-left corner of its footprint. The room owns the rules about where it
## may go; this only knows where it is and who is sitting on it.

## Set by the room when placed, or on the instance for authored furniture.
@export var def: FurnitureDef
## Top-left cell of the footprint, counted from the room's floor corner.
@export var cell: Vector2i = Vector2i.ZERO

## The dwarf using this seat, or null. Only seats are ever occupied.
var occupant: Node = null


func move_to(new_cell: Vector2i) -> void:
	cell = new_cell
	position = Vector2(cell * NavGrid.CELL)


## The footprint in room cells.
func rect() -> Rect2i:
	return Rect2i(cell, def.footprint)


func is_free_seat(for_dwarf: Node) -> bool:
	if not def.is_seat:
		return false
	return occupant == null or occupant == for_dwarf or not is_instance_valid(occupant)
