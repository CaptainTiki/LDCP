class_name Placeable
extends Node2D
## Base for anything placed on the town's tile grid: buildings and plots.
## The town is seen from above. The node's origin is the bottom-left corner
## of its footprint, so things nearer the bottom of the screen draw in front.

## Size of one town tile in world pixels.
const TILE_PIXELS: int = 16
## Nav cells along one side of a tile.
const TILE_CELLS: int = 2

## Set by whoever places this (the Surface), or on the instance for
## buildings that are pre-placed in the world scene.
@export var def: BuildingDef
## Top-left tile of the footprint.
@export var tile: Vector2i = Vector2i.ZERO

var world: World


func place(in_world: World, at_tile: Vector2i) -> void:
	world = in_world
	_set_tile(at_tile)
	_on_placed()


func move_to(new_tile: Vector2i) -> void:
	_set_tile(new_tile)
	_on_moved()


func remove() -> void:
	_on_removed()


## The tiles this stands on.
func footprint_rect() -> Rect2i:
	return Rect2i(tile, def.footprint)


## The tiles nothing else may be built on: the footprint, plus the row in
## front of a building so its door can never be walled in.
func claimed_rect() -> Rect2i:
	var rect: Rect2i = footprint_rect()
	if def.blocks_walking:
		rect.size.y += 1
	return rect


## The nav cell a dwarf stands in to work on this: the middle of it.
func work_cell() -> Vector2i:
	return _cell_of_tile(tile) + def.footprint


## The nav cell just outside the door in the front wall.
func door_cell() -> Vector2i:
	return _cell_of_tile(tile + Vector2i(0, def.footprint.y)) + Vector2i(def.door_offset_cells, 0)


func sim_tick(_delta: float) -> void:
	pass


func _on_placed() -> void:
	pass


func _on_moved() -> void:
	pass


func _on_removed() -> void:
	pass


func _set_tile(new_tile: Vector2i) -> void:
	tile = new_tile
	position = Vector2(tile.x, tile.y + def.footprint.y) * TILE_PIXELS


func _cell_of_tile(a_tile: Vector2i) -> Vector2i:
	return world.surface.origin_cell() + a_tile * TILE_CELLS
