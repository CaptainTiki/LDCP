class_name Surface
extends Node2D
## The town's ground line: a row of slots that buildings and farm plots sit
## in. Buildings authored under Placeables are adopted at start-up, and new
## ones are instanced from their BuildingDef scenes.

## Number of buildable slots. Keep the Terrain at least this many slots wide.
@export var slot_count: int = 64

var _world: World

@onready var _placeables: Node2D = $Placeables


func setup(world: World) -> void:
	_world = world
	for x: int in slot_count * Placeable.SLOT_CELLS:
		world.nav.set_walkable(Vector2i(x, -1))
	for placeable: Placeable in placeables():
		placeable.place(world, placeable.slot)


func sim_tick(delta: float) -> void:
	for placeable: Placeable in placeables():
		placeable.sim_tick(delta)


func width_pixels() -> float:
	return slot_count * Placeable.SLOT_PIXELS


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


func slot_at(world_x: float) -> int:
	return floori(world_x / Placeable.SLOT_PIXELS)


func placeable_at(slot: int) -> Placeable:
	for placeable: Placeable in placeables():
		if slot >= placeable.slot and slot < placeable.slot + placeable.width_slots():
			return placeable
	return null


## Are `width` slots starting at `slot` empty? `ignore` lets a building being
## moved overlap its own old position.
func is_free(slot: int, width: int, ignore: Placeable = null) -> bool:
	if slot < 0 or slot + width > slot_count:
		return false
	for placeable: Placeable in placeables():
		if placeable == ignore:
			continue
		if slot < placeable.slot + placeable.width_slots() and placeable.slot < slot + width:
			return false
	return true


func build(def: BuildingDef, slot: int) -> Placeable:
	var placeable: Placeable = def.scene.instantiate() as Placeable
	placeable.def = def
	_placeables.add_child(placeable)
	placeable.place(_world, slot)
	return placeable


func demolish(placeable: Placeable) -> void:
	placeable.remove()
	_placeables.remove_child(placeable)
	placeable.queue_free()
