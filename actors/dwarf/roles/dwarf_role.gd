class_name DwarfRole
extends Node
## Base for the things a dwarf can be doing: a job, idling, or a meal break.
## Exactly one role is in charge at a time, and its act() runs every tick.
##
## Roles are written as "look at the world, decide where I should be and
## what I should do, and do one tick of it". They keep very little memory,
## so they cope when the player moves or destroys things mid-task.

var dwarf: Dwarf


## One sim tick of this role.
func act(_delta: float) -> void:
	pass


## Called when another role takes over. Let go of anything claimed.
func release() -> void:
	pass


func title() -> String:
	return "Idle"


func badge() -> String:
	return "-"


## Walks toward `cell`. Returns true once the dwarf is standing on it.
func _walk_to(cell: Vector2i) -> bool:
	if cell == NavGrid.NO_CELL:
		return false
	if dwarf.mover.is_at(cell):
		return true
	dwarf.mover.travel_to(cell)
	return false


## Carries whatever is on the dwarf's back to the Great Hall's storage.
func _haul_to_hall() -> void:
	var hall: GreatHall = dwarf.world.hall
	if _walk_to(hall.storage_cell()):
		dwarf.carrier.unload_into(hall.storage)
		dwarf.equip_best_tool(hall.storage)
