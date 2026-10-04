class_name Storage
extends Node
## A pile of items. The Great Hall owns the town's one central Storage.

signal changed

var _counts: Dictionary[ItemDef, int] = {}


func count(item: ItemDef) -> int:
	return _counts.get(item, 0)


func add(item: ItemDef, amount: int) -> void:
	if amount <= 0:
		return
	_counts[item] = count(item) + amount
	changed.emit()


## Removes the items only if all of them are there. Returns whether it did.
func remove(item: ItemDef, amount: int) -> bool:
	if count(item) < amount:
		return false
	_counts[item] = count(item) - amount
	changed.emit()
	return true


## Every kind of item there's at least one of.
func items() -> Array[ItemDef]:
	var stocked: Array[ItemDef] = []
	for item: ItemDef in _counts:
		if _counts[item] > 0:
			stocked.append(item)
	return stocked


## Takes one serving of the longest-lasting meal in stock, or null if none.
func take_best_meal() -> MealDef:
	var best: MealDef = null
	for item: ItemDef in _counts:
		var meal: MealDef = item as MealDef
		if meal == null or count(meal) <= 0:
			continue
		if best == null or meal.shift_seconds > best.shift_seconds:
			best = meal
	if best != null:
		remove(best, 1)
	return best


## Takes one serving of the strongest drink in stock, or null if none.
func take_best_drink() -> DrinkDef:
	var best: DrinkDef = null
	for item: ItemDef in _counts:
		var drink: DrinkDef = item as DrinkDef
		if drink == null or count(drink) <= 0:
			continue
		if best == null or drink.high_multiplier > best.high_multiplier:
			best = drink
	if best != null:
		remove(best, 1)
	return best
