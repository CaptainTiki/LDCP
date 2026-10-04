class_name Interiors
extends Node2D
## Holds every building's interior room. This node sits far away from the
## town so rooms never show up in the surface or mine views. Each new room
## gets its own stretch of floor.

## World pixels between one room's origin and the next. A multiple of the
## nav cell size, so room floors line up with the grid.
const ROOM_SPACING: float = 1600.0

var _rooms_added: int = 0


func add_room(room: BuildingInterior) -> void:
	add_child(room)
	room.position = Vector2(_rooms_added * ROOM_SPACING, 0)
	_rooms_added += 1


## The room that contains this nav cell, or null if the cell is outdoors.
func room_at(cell: Vector2i) -> BuildingInterior:
	for child: Node in get_children():
		var room: BuildingInterior = child as BuildingInterior
		if not room.is_queued_for_deletion() and room.contains_cell(cell):
			return room
	return null
