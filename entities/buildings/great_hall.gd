class_name GreatHall
extends Building
## The heart of the town: central storage, and the tables where dwarves eat
## and drink (or sit and wait when the pantry is bare).

@onready var storage: Storage = $Storage


## Where a dwarf stands to drop off or pick up goods.
func storage_cell() -> Vector2i:
	return (interior as GreatHallInterior).storage_cell()


## A seat at the tables. Any index is fine: seats are shared out in turn.
func seat_cell(index: int) -> Vector2i:
	return (interior as GreatHallInterior).seat_cell(index)
