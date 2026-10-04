class_name Hunger
extends Node
## Food is shift length. A meal fills the bar, and when it runs out the dwarf
## stops for a meal break. Hunger never hurts a dwarf, it only stalls him.

var seconds_left: float = 0.0
## Length of the last meal, so the bar can show a 0..1 ratio.
var shift_seconds: float = 1.0


func eat(meal: MealDef) -> void:
	fill(meal.shift_seconds)


func fill(seconds: float) -> void:
	seconds_left = seconds
	shift_seconds = maxf(seconds, 1.0)


func sim_tick(delta: float) -> void:
	seconds_left = maxf(0.0, seconds_left - delta)


func is_empty() -> bool:
	return seconds_left <= 0.0


func ratio() -> float:
	return clampf(seconds_left / shift_seconds, 0.0, 1.0)
