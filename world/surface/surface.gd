class_name Surface
extends Node2D
## The town, seen from above: a grid of tiles that buildings and farm plots
## are placed on. Dwarves walk anywhere a building is not. Buildings authored
## under Placeables are adopted at start-up, and new ones are instanced from
## their BuildingDef scenes.
##
## This node sits in its own part of the world, away from the mine. The mine
## entrance's door is what joins the two.

## Size of the town in tiles.
@export var size_tiles: Vector2i = Vector2i(128, 9)

var _world: World

@onready var _placeables: Node2D = $Placeables
@onready var _ground: Ground = $Ground


func setup(world: World) -> void:
	_world = world
	_ground.size_tiles = size_tiles
	_ground.queue_redraw()
	_refresh_nav()
	for placeable: Placeable in placeables():
		placeable.place(world, placeable.tile)
	_refresh_nav()


func sim_tick(delta: float) -> void:
	for placeable: Placeable in placeables():
		placeable.sim_tick(delta)


## The nav cell at the town's top-left corner.
func origin_cell() -> Vector2i:
	return NavGrid.world_to_cell(global_position)


func contains_cell(cell: Vector2i) -> bool:
	return Rect2i(origin_cell(), size_tiles * Placeable.TILE_CELLS).has_point(cell)


## World-space rectangle of the town, for framing the camera.
func view_rect() -> Rect2:
	return Rect2(global_position, Vector2(size_tiles * Placeable.TILE_PIXELS))


func tile_at(world_point: Vector2) -> Vector2i:
	return Vector2i(((world_point - global_position) / Placeable.TILE_PIXELS).floor())


func tile_to_world(tile: Vector2i) -> Vector2:
	return global_position + Vector2(tile * Placeable.TILE_PIXELS)


func placeables() -> Array[Placeable]:
	var result: Array[Placeable] = []
	for child: Node in _placeables.get_children():
		result.append(child as Placeable)
	return result


func farm_plots() -> Array[FarmPlot]:
	var result: Array[FarmPlot] = []
	for child: Node in _placeables.get_children():
		if child is FarmPlot:
			result.append(child as FarmPlot)
	return result


func placeable_at(tile: Vector2i) -> Placeable:
	for placeable: Placeable in placeables():
		if placeable.footprint_rect().has_point(tile):
			return placeable
	return null


## Could something with this def stand with its top-left corner at `tile`?
## `ignore` lets a building being moved overlap its own old position.
func is_free(def: BuildingDef, tile: Vector2i, ignore: Placeable = null) -> bool:
	var wanted := Rect2i(tile, def.footprint)
	if def.blocks_walking:
		wanted.size.y += 1  # Room for the door.
	if not Rect2i(Vector2i.ZERO, size_tiles).encloses(wanted):
		return false
	for placeable: Placeable in placeables():
		if placeable != ignore and placeable.claimed_rect().intersects(wanted):
			return false
	return true


func build(def: BuildingDef, tile: Vector2i) -> Placeable:
	var placeable: Placeable = def.scene.instantiate() as Placeable
	placeable.def = def
	_placeables.add_child(placeable)
	placeable.place(_world, tile)
	_refresh_nav()
	return placeable


func move(placeable: Placeable, tile: Vector2i) -> void:
	placeable.move_to(tile)
	_refresh_nav()


func demolish(placeable: Placeable) -> void:
	placeable.remove()
	_placeables.remove_child(placeable)
	placeable.queue_free()
	_refresh_nav()


## Works out afresh where dwarves can walk: everywhere in town except
## under a building.
func _refresh_nav() -> void:
	var origin: Vector2i = origin_cell()
	var size_cells: Vector2i = size_tiles * Placeable.TILE_CELLS
	for y: int in size_cells.y:
		for x: int in size_cells.x:
			_world.nav.set_flags(origin + Vector2i(x, y), NavGrid.TOP_DOWN)
	for placeable: Placeable in placeables():
		if not placeable.def.blocks_walking:
			continue
		var rect: Rect2i = placeable.footprint_rect()
		for y: int in range(rect.position.y * Placeable.TILE_CELLS, rect.end.y * Placeable.TILE_CELLS):
			for x: int in range(rect.position.x * Placeable.TILE_CELLS, rect.end.x * Placeable.TILE_CELLS):
				_world.nav.clear_walkable(origin + Vector2i(x, y))
