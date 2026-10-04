class_name Worker
extends Node
## Turns a dwarf's time into work on a WorkReceiver.
## Work per second = base rate x tool multiplier x drink multiplier.

var base_rate: float = 1.0
## Hook for tool tiers. Always 1.0 until tools exist.
var tool_multiplier: float = 1.0

var _thirst: Thirst
var _receiver: WorkReceiver = null
var _worked_this_tick: bool = false
var _worked_last_tick: bool = false


func setup(thirst: Thirst) -> void:
	_thirst = thirst


## Call once at the start of every sim tick, before any work is done.
func begin_tick() -> void:
	_worked_last_tick = _worked_this_tick
	_worked_this_tick = false


func rate() -> float:
	return base_rate * tool_multiplier * _thirst.multiplier()


func work_on(receiver: WorkReceiver, delta: float) -> void:
	_receiver = receiver
	_worked_this_tick = true
	receiver.apply_work(rate() * delta, get_parent())


## For animation: was the dwarf swinging a tool just now?
func is_working() -> bool:
	return _worked_this_tick or _worked_last_tick


## True while a job is part-done. A hungry dwarf finishes it before he leaves.
func is_mid_unit() -> bool:
	return _worked_last_tick and is_instance_valid(_receiver) and _receiver.progress > 0.0
