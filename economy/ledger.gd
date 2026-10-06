class_name Ledger
extends Node
## The town's lifetime record: how much of everything has ever been
## harvested, made, mined and sold. Unlock milestones read it; save/load and stats
## will too. Counters are keyed by name: a total ("harvested") and one per
## item ("harvested:potato").

signal changed

const HARVESTED: StringName = &"harvested"
const MADE: StringName = &"made"
const MEALS_MADE: StringName = &"meals_made"
const DRINKS_MADE: StringName = &"drinks_made"
const MINED: StringName = &"mined"
const SOLD: StringName = &"sold"

var _counts: Dictionary[StringName, int] = {}


## The per-item counter name, e.g. "harvested:potato".
static func key_for(kind: StringName, item: ItemDef) -> StringName:
	return StringName("%s:%s" % [kind, item.id])


func count(key: StringName) -> int:
	return _counts.get(key, 0)


## Every counter so far, for the game log.
func counters() -> Dictionary[StringName, int]:
	return _counts.duplicate()


func record_harvest(item: ItemDef, amount: int) -> void:
	_add(HARVESTED, amount)
	_add(key_for(HARVESTED, item), amount)
	changed.emit()


func record_made(item: ItemDef, amount: int) -> void:
	_add(key_for(MADE, item), amount)
	if item is MealDef:
		_add(MEALS_MADE, amount)
	elif item is DrinkDef:
		_add(DRINKS_MADE, amount)
	changed.emit()


func record_mined(item: ItemDef, amount: int) -> void:
	_add(MINED, amount)
	_add(key_for(MINED, item), amount)
	changed.emit()


## Sold by hand from the Inventory tab, or at the market.
func record_sold(item: ItemDef, amount: int) -> void:
	_add(SOLD, amount)
	_add(key_for(SOLD, item), amount)
	changed.emit()


func _add(key: StringName, amount: int) -> void:
	_counts[key] = count(key) + amount
