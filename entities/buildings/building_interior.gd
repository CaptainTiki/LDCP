class_name BuildingInterior
extends Node2D
## The inside of a building, seen from above: a rectangle of floor dwarves
## can walk, a door in the bottom wall, slots for workstations, and any
## furniture the player has placed. The node's origin is the top-left corner
## of the floor.

## Size of the walkable floor in nav cells.
@export var floor_size_cells: Vector2i = Vector2i(20, 8)
## Floor areas furniture may not cover (a storage pile, a work spot), in
## cells from the floor's corner. The door's cell is always kept clear too.
@export var reserved_rects: Array[Rect2i] = []

var building: Building

var _world: World

@onready var _door: Marker2D = $Door
@onready var _slots: Node2D = $Slots
@onready var _furniture: Node2D = $Furniture


func setup(world: World, owner_building: Building) -> void:
	_world = world
	building = owner_building
	# Authored furniture has its cell and facing set in the scene.
	for piece: Furniture in furniture():
		piece.place(piece.cell, piece.facing)
	_refresh_nav()


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


## The nav cell of the floor's top-left corner.
func origin_cell() -> Vector2i:
	return NavGrid.world_to_cell(global_position)


## The room cell (counted from the floor's corner) under a world position.
func room_cell_at(world_point: Vector2) -> Vector2i:
	return NavGrid.world_to_cell(world_point) - origin_cell()


func contains_cell(cell: Vector2i) -> bool:
	return _floor_rect().has_point(cell)


## World-space rectangle of the room, for framing the camera.
func view_rect() -> Rect2:
	return Rect2(global_position, Vector2(floor_size_cells * NavGrid.CELL))


# --- Workstations ---------------------------------------------------------------------

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


# --- Furniture ------------------------------------------------------------------------

func furniture() -> Array[Furniture]:
	var pieces: Array[Furniture] = []
	for child: Node in _furniture.get_children():
		if not child.is_queued_for_deletion():
			pieces.append(child as Furniture)
	return pieces


func furniture_at(room_cell: Vector2i) -> Furniture:
	for piece: Furniture in furniture():
		if piece.rect().has_point(room_cell):
			return piece
	return null


## Could `def`, turned `facing` quarter turns, stand with its corner at
## `room_cell`? `ignore` lets a piece being moved overlap its own old spot.
## Nothing may wall off part of the floor: every open cell must stay
## reachable from the door.
func can_place(def: FurnitureDef, room_cell: Vector2i, ignore: Furniture = null, facing: int = 0) -> bool:
	var wanted := Rect2i(room_cell, Furniture.turned_size(def.footprint, facing))
	if not Rect2i(Vector2i.ZERO, floor_size_cells).encloses(wanted):
		return false
	if wanted.has_point(door_cell() - origin_cell()):
		return false
	for reserved: Rect2i in reserved_rects:
		if reserved.intersects(wanted):
			return false
	for piece: Furniture in furniture():
		if piece != ignore and piece.rect().intersects(wanted):
			return false
	return not def.blocks_walking or _floor_stays_connected(wanted, ignore)


func place_furniture(def: FurnitureDef, room_cell: Vector2i, facing: int = 0) -> Furniture:
	var piece: Furniture = def.scene.instantiate() as Furniture
	piece.def = def
	_furniture.add_child(piece)
	piece.place(room_cell, facing)
	_refresh_nav()
	return piece


func move_furniture(piece: Furniture, room_cell: Vector2i, facing: int) -> void:
	piece.occupant = null  # Whoever was sitting there has to get up.
	piece.place(room_cell, facing)
	_refresh_nav()


## Turns a placed piece a quarter turn clockwise, where it stands. Returns
## false (and leaves it alone) if the turned piece wouldn't fit there.
func turn_furniture(piece: Furniture) -> bool:
	var turned: int = (piece.facing + 1) % 4
	if not can_place(piece.def, piece.cell, piece, turned):
		return false
	move_furniture(piece, piece.cell, turned)
	return true


func remove_furniture(piece: Furniture) -> void:
	_furniture.remove_child(piece)
	piece.queue_free()
	_refresh_nav()


## Reserves a free seat for the dwarf (or finds the one he has). Returns
## the nav cell to sit in, or NO_CELL when every seat is taken.
func claim_seat(dwarf: Node) -> Vector2i:
	var free_seat: Furniture = null
	for piece: Furniture in furniture():
		if piece.def.is_seat and piece.occupant == dwarf:
			return origin_cell() + piece.cell
		if free_seat == null and piece.is_free_seat(dwarf):
			free_seat = piece
	if free_seat == null:
		return NavGrid.NO_CELL
	free_seat.occupant = dwarf
	return origin_cell() + free_seat.cell


func release_seat(dwarf: Node) -> void:
	for piece: Furniture in furniture():
		if piece.occupant == dwarf:
			piece.occupant = null


func seat_count() -> int:
	var seats: int = 0
	for piece: Furniture in furniture():
		if piece.def.is_seat:
			seats += 1
	return seats


func _first_free_slot() -> Node2D:
	for slot: Node in _slots.get_children():
		if slot.get_child_count() == 0:
			return slot as Node2D
	return null


func _floor_rect() -> Rect2i:
	return Rect2i(origin_cell(), floor_size_cells)


## Room cells that blocking furniture covers, optionally pretending one piece
## has moved (`ignore` gone, `extra` added).
func _blocked_cells(extra: Rect2i = Rect2i(), ignore: Furniture = null) -> Dictionary[Vector2i, bool]:
	var blocked: Dictionary[Vector2i, bool] = {}
	var rects: Array[Rect2i] = [extra]
	for piece: Furniture in furniture():
		if piece != ignore and piece.def.blocks_walking:
			rects.append(piece.rect())
	for rect: Rect2i in rects:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				blocked[Vector2i(x, y)] = true
	return blocked


func _floor_stays_connected(wanted: Rect2i, ignore: Furniture) -> bool:
	var blocked: Dictionary[Vector2i, bool] = _blocked_cells(wanted, ignore)
	var bounds := Rect2i(Vector2i.ZERO, floor_size_cells)
	var start: Vector2i = door_cell() - origin_cell()
	var reached: Dictionary[Vector2i, bool] = {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if bounds.has_point(next) and not blocked.has(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached.size() == floor_size_cells.x * floor_size_cells.y - blocked.size()


## Floor is walkable everywhere except under tables and the like.
func _refresh_nav() -> void:
	var origin: Vector2i = origin_cell()
	var blocked: Dictionary[Vector2i, bool] = _blocked_cells()
	for y: int in floor_size_cells.y:
		for x: int in floor_size_cells.x:
			var cell := Vector2i(x, y)
			if blocked.has(cell):
				_world.nav.clear_walkable(origin + cell)
			else:
				_world.nav.set_flags(origin + cell, NavGrid.TOP_DOWN)
