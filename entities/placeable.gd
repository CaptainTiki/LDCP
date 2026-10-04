class_name Placeable
extends Node2D
## Base for anything that sits in the surface's slots: buildings and plots.
## The node's origin is the bottom-left corner of its footprint, on the
## ground line.

## Width of one surface slot in world pixels.
const SLOT_PIXELS: int = 32
## Nav cells per slot.
const SLOT_CELLS: int = 4

## Set by whoever places this (the Surface), or on the instance for
## buildings that are pre-placed in the world scene.
@export var def: BuildingDef
## Leftmost slot this occupies.
@export var slot: int = 0

var world: World


func place(in_world: World, at_slot: int) -> void:
	world = in_world
	slot = at_slot
	position = Vector2(slot * SLOT_PIXELS, 0)
	_on_placed()


func move_to(new_slot: int) -> void:
	slot = new_slot
	position = Vector2(slot * SLOT_PIXELS, 0)
	_on_moved()


func remove() -> void:
	_on_removed()


func width_slots() -> int:
	return def.footprint.x


## The surface cell a dwarf stands in to work on or at this.
func work_cell() -> Vector2i:
	return Vector2i(slot * SLOT_CELLS + width_slots() * SLOT_CELLS / 2, -1)


func sim_tick(_delta: float) -> void:
	pass


func _on_placed() -> void:
	pass


func _on_moved() -> void:
	pass


func _on_removed() -> void:
	pass
