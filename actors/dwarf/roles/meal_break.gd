class_name MealBreak
extends DwarfRole
## What a dwarf does when his food bar is empty: walk to the Great Hall, put
## down anything he is carrying, take a free chair and eat. With no food in
## the hall he sits and waits; that is the stall, and buying gruel ends it.
## With every chair taken he waits by the storage pile for one to free up.
## Drink is topped up on the same visit. Dwarves never come in just to drink.

var eat_seconds: float = 4.0
## True from the moment the break starts until the meal is finished.
var in_progress: bool = false
var is_waiting_for_food: bool = false
var is_waiting_for_seat: bool = false

var _meal: MealDef = null
var _eating_left: float = 0.0


func act(delta: float) -> void:
	in_progress = true
	var hall: GreatHall = dwarf.world.hall
	if not dwarf.carrier.is_empty():
		_haul_to_hall()
		return
	if _meal == null:
		_find_a_seat_and_order(hall)
		return
	_eating_left -= delta
	if _eating_left <= 0.0:
		dwarf.hunger.eat(_meal)
		release()


func release() -> void:
	in_progress = false
	is_waiting_for_food = false
	is_waiting_for_seat = false
	dwarf.is_sitting = false
	_meal = null
	dwarf.world.hall.release_seat(dwarf)


func _find_a_seat_and_order(hall: GreatHall) -> void:
	var seat: Vector2i = hall.claim_seat(dwarf)
	is_waiting_for_seat = seat == NavGrid.NO_CELL
	if is_waiting_for_seat:
		dwarf.is_sitting = false
		_walk_to(hall.storage_cell())
		return
	if _walk_to(seat):
		dwarf.is_sitting = true
		_try_to_get_served(hall.storage)
	else:
		dwarf.is_sitting = false


func _try_to_get_served(storage: Storage) -> void:
	_meal = storage.take_best_meal()
	is_waiting_for_food = _meal == null
	if _meal == null:
		return
	_eating_left = eat_seconds
	var drink: DrinkDef = storage.take_best_drink()
	if drink != null:
		dwarf.thirst.drink_up(drink)
