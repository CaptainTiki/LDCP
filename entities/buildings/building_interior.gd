class_name BuildingInterior
extends Node2D
## The inside of a building, seen from above: a rectangle of floor dwarves
## can walk, a door in the bottom wall, and a few slots for workstations.
## The node's origin is the top-left corner of the floor.

## Size of the walkable floor in nav cells.
@export var floor_size_cells: Vector2i = Vector2i(20, 8)

var building: Building

var _world: World

@onready var _door: Marker2D = $Door
@onready var _slots: Node2D = $Slots


func setup(world: World, owner_building: Building) -> void:
	_world = world
	building = owner_building
	var floor_rect: Rect2i = _floor_rect()
	for y: int in range(floor_rect.position.y, floor_rect.end.y):
		for x: int in range(floor_rect.position.x, floor_rect.end.x):
			world.nav.set_walkable(Vector2i(x, y), NavGrid.TOP_DOWN)


func teardown() -> void:
	var floor_rect: Rect2i = _floor_rect()
	for y: int in range(floor_rect.position.y, floor_rect.end.y):
		for x: int in range(floor_rect.position.x, floor_rect.end.x):
			_world.nav.clear_walkable(Vector2i(x, y))
	queue_free()


func door_cell() -> Vector2i:
	return cell_at(_door)


## The floor cell under a marker placed in the room.
func cell_at(marker: Node2D) -> Vector2i:
	return NavGrid.world_to_cell(marker.global_position)


func contains_cell(cell: Vector2i) -> bool:
	return _floor_rect().has_point(cell)


## World-space rectangle of the room, for framing the camera.
func view_rect() -> Rect2:
	return Rect2(global_position, Vector2(floor_size_cells * NavGrid.CELL))


func workstations() -> Array[Workstation]:
	var stations: Array[Workstation] = []
	for slot: Node in _slots.get_children():
		if slot.get_child_count() > 0:
			stations.append(slot.get_child(0) as Workstation)
	return stations


func has_free_slot() -> bool:
	return _first_free_slot() != null


## Instances the workstation into the first empty slot.
func add_workstation(def: WorkstationDef) -> Workstation:
	var slot: Node2D = _first_free_slot()
	if slot == null:
		return null
	var station: Workstation = def.scene.instantiate() as Workstation
	slot.add_child(station)
	station.setup(def, _world.hall.storage)
	return station


func remove_workstation(station: Workstation) -> void:
	station.get_parent().remove_child(station)
	station.queue_free()


func sim_tick(delta: float) -> void:
	for station: Workstation in workstations():
		station.sim_tick(delta)


func _first_free_slot() -> Node2D:
	for slot: Node in _slots.get_children():
		if slot.get_child_count() == 0:
			return slot as Node2D
	return null


func _floor_rect() -> Rect2i:
	return Rect2i(NavGrid.world_to_cell(global_position), floor_size_cells)
