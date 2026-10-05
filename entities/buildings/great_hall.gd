class_name GreatHall
extends Building
## The heart of the town: central storage, and the chairs where dwarves eat
## and drink (or sit and wait when the pantry is bare). Dwarves with nothing
## to do sit here too, but they give up their chair to anyone come to eat.

## Dwarves in a chair only because they have nothing to do.
var _idlers: Array[Node] = []

@onready var storage: Storage = $Storage


## Where a dwarf stands to drop off or pick up goods.
func storage_cell() -> Vector2i:
	return (interior as GreatHallInterior).storage_cell()


## Reserves a chair for a meal, standing an idler up if that's what it
## takes. NO_CELL when everyone in a chair is eating.
func claim_seat(dwarf: Node) -> Vector2i:
	_idlers.erase(dwarf)
	var seat: Vector2i = interior.claim_seat(dwarf)
	if seat == NavGrid.NO_CELL and not _idlers.is_empty():
		interior.release_seat(_idlers.pop_back())
		seat = interior.claim_seat(dwarf)
	return seat


## Reserves a chair to idle in, if one is free. NO_CELL if not.
func claim_idle_seat(dwarf: Node) -> Vector2i:
	var seat: Vector2i = interior.claim_seat(dwarf)
	if seat != NavGrid.NO_CELL and not _idlers.has(dwarf):
		_idlers.append(dwarf)
	return seat


## Gets an idler up. A chair taken for a meal is left alone.
func release_idle_seat(dwarf: Node) -> void:
	if _idlers.has(dwarf):
		_idlers.erase(dwarf)
		interior.release_seat(dwarf)


func release_seat(dwarf: Node) -> void:
	_idlers.erase(dwarf)
	interior.release_seat(dwarf)
