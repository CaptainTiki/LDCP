class_name MealBreak
extends DwarfRole
## What a dwarf does when his food bar is empty: walk to the Great Hall, put
## down anything he is carrying, sit at a table and eat. With no food in the
## hall he just sits and waits. That is the stall, and buying gruel ends it.
## Drink is topped up on the same visit. Dwarves never come in just to drink.

var eat_seconds: float = 4.0
## True from the moment the break starts until the meal is finished.
var in_progress: bool = false
var is_waiting_for_food: bool = false

var _meal: MealDef = null
var _eating_left: float = 0.0


func act(delta: float) -> void:
	in_progress = true
	var hall: GreatHall = dwarf.world.hall
	if not dwarf.carrier.is_empty():
		_haul_to_hall()
		return
	if _meal == null:
		if _walk_to(hall.seat_cell(dwarf.get_index())):
			dwarf.is_sitting = true
			_try_to_get_served(hall.storage)
		return
	_eating_left -= delta
	if _eating_left <= 0.0:
		dwarf.hunger.eat(_meal)
		release()


func release() -> void:
	in_progress = false
	is_waiting_for_food = false
	dwarf.is_sitting = false
	_meal = null


func _try_to_get_served(storage: Storage) -> void:
	_meal = storage.take_best_meal()
	is_waiting_for_food = _meal == null
	if _meal == null:
		return
	_eating_left = eat_seconds
	var drink: DrinkDef = storage.take_best_drink()
	if drink != null:
		dwarf.thirst.drink_up(drink)
