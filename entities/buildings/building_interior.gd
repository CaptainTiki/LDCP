class_name BuildingInterior
extends Node2D
## The inside of a building: a floor dwarves can walk, a door, and a few
## slots for workstations. The node's origin is the left end of the floor.

## Width of the walkable floor in nav cells.
@export var floor_cells: int = 20
## Height of the room in world pixels, for framing the camera.
@export var room_height: float = 72.0

var building: Building

var _world: World

@onready var _door: Marker2D = $Door
@onready var _slots: Node2D = $Slots


func setup(world: World, owner_building: Building) -> void:
	_world = world
	building = owner_building
	for cell: Vector2i in _floor():
		world.nav.set_walkable(cell)


func teardown() -> void:
	for cell: Vector2i in _floor():
		_world.nav.clear_walkable(cell)
	queue_free()


func door_cell() -> Vector2i:
	return cell_at(_door)


## The floor cell under a marker placed in the room.
func cell_at(marker: Node2D) -> Vector2i:
	return NavGrid.world_to_cell(marker.global_position + Vector2(0, -1))


func contains_cell(cell: Vector2i) -> bool:
	return _floor().has(cell)


## World-space rectangle of the room, for framing the camera.
func view_rect() -> Rect2:
	var width: float = floor_cells * NavGrid.CELL
	return Rect2(global_position + Vector2(0, -room_height), Vector2(width, room_height))


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


func _floor() -> Array[Vector2i]:
	var first: Vector2i = NavGrid.world_to_cell(global_position + Vector2(0, -1))
	var cells: Array[Vector2i] = []
	for i: int in floor_cells:
		cells.append(first + Vector2i(i, 0))
	return cells
