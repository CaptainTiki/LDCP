class_name GreatHall
extends Building
## The heart of the town: central storage, and the chairs where dwarves eat
## and drink (or sit and wait when the pantry is bare).

@onready var storage: Storage = $Storage


## Where a dwarf stands to drop off or pick up goods.
func storage_cell() -> Vector2i:
	return (interior as GreatHallInterior).storage_cell()


## Reserves a chair for the dwarf. NO_CELL when every chair is taken.
func claim_seat(dwarf: Node) -> Vector2i:
	return interior.claim_seat(dwarf)


func release_seat(dwarf: Node) -> void:
	interior.release_seat(dwarf)
