class_name Thirst
extends Node
## Drink is work rate. A fresh drink starts at its high multiplier and tapers
## toward its low as the dwarf works it off. With nothing to drink a dwarf still works, at the floor.

## For the game log's count of what gets drunk.
signal drank(drink: DrinkDef)

## Work rate with no drink at all.
@export var floor_multiplier: float = 0.5

var drink: DrinkDef = null
var seconds_left: float = 0.0


func drink_up(new_drink: DrinkDef) -> void:
	drink = new_drink
	seconds_left = new_drink.duration_seconds
	drank.emit(new_drink)


func sim_tick(delta: float) -> void:
	seconds_left = maxf(0.0, seconds_left - delta)


func multiplier() -> float:
	if drink == null or seconds_left <= 0.0:
		return floor_multiplier
	return maxf(floor_multiplier, drink.multiplier_at(1.0 - ratio()))


func ratio() -> float:
	if drink == null or drink.duration_seconds <= 0.0:
		return 0.0
	return clampf(seconds_left / drink.duration_seconds, 0.0, 1.0)
