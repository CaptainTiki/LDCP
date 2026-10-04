class_name Unlocks
extends Node
## Remembers one-off purchases that open up new build options.

signal changed

var _unlocked_ids: Dictionary[StringName, bool] = {}


func is_unlocked(def: BuildingDef) -> bool:
	return def.unlock_cost <= 0 or _unlocked_ids.has(def.id)


func unlock(def: BuildingDef) -> void:
	_unlocked_ids[def.id] = true
	changed.emit()
