class_name DwarfPool
extends Node2D
## Every dwarf the town can ever have is already a child of this node,
## hidden. Hiring activates the next spare one, so nothing is created or
## freed while the game runs.

signal roster_changed

@export var names: NameList

var _world: World
var _tuning: GameTuning
var _rng := RandomNumberGenerator.new()


func setup(world: World, tuning: GameTuning, clock: SimClock) -> void:
	_world = world
	_tuning = tuning
	_rng.randomize()
	for dwarf: Dwarf in _all():
		dwarf.setup(world, tuning, clock)
	for i: int in tuning.starting_dwarves:
		hire()


func sim_tick(delta: float) -> void:
	for dwarf: Dwarf in active():
		dwarf.sim_tick(delta)


func active() -> Array[Dwarf]:
	var result: Array[Dwarf] = []
	for dwarf: Dwarf in _all():
		if dwarf.is_active:
			result.append(dwarf)
	return result


func active_count() -> int:
	return active().size()


func has_spare() -> bool:
	return active_count() < get_child_count()


## Activates a spare dwarf outside the Great Hall. Null if the pool is empty.
func hire() -> Dwarf:
	for dwarf: Dwarf in _all():
		if dwarf.is_active:
			continue
		var beard := Color.from_hsv(_rng.randf(), 0.55, 0.85)
		var spot: Vector2i = _world.hall.door_cell() + Vector2i(_rng.randi_range(-3, 3), 0)
		dwarf.activate(spot, names.random_name(_rng), beard, _tuning.starting_food_seconds)
		roster_changed.emit()
		return dwarf
	return null


func _all() -> Array[Dwarf]:
	var result: Array[Dwarf] = []
	for child: Node in get_children():
		result.append(child as Dwarf)
	return result
