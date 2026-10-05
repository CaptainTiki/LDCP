class_name FurnitureTool
extends Node2D
## The player's hand inside the Great Hall: place new furniture on the room's
## floor grid, pick a piece up and move it, turn it, or take it away. The
## Ghost child previews where a piece would land, green when it fits and red
## when not. While a piece is in hand, the mouse wheel turns it; right-click
## puts the tool away.

signal mode_changed

enum Mode { NONE, PLACE, MOVE, TURN, DESTROY }

@export var valid_color: Color = Color(0.3, 1.0, 0.3, 0.45)
@export var invalid_color: Color = Color(1.0, 0.3, 0.3, 0.45)

var mode: Mode = Mode.NONE
## What PLACE mode is placing.
var place_def: FurnitureDef = null
## Which way the piece in hand faces, in quarter turns clockwise.
var facing: int = 0

var _world: World
var _wallet: Wallet
## What MOVE mode has picked up, or null if nothing yet.
var _carried: Furniture = null
var _last_point: Vector2 = Vector2.ZERO

@onready var _ghost: ColorRect = $Ghost


func setup(world: World, wallet: Wallet) -> void:
	_world = world
	_wallet = wallet
	_ghost.visible = false


func is_active() -> bool:
	return mode != Mode.NONE


## True while there's a piece to turn: one being placed, or one picked up.
func is_holding_piece() -> bool:
	return mode == Mode.PLACE or (mode == Mode.MOVE and _carried != null)


func start_place(def: FurnitureDef) -> void:
	place_def = def
	_set_mode(Mode.PLACE)


func start_move() -> void:
	_set_mode(Mode.MOVE)


func start_turn() -> void:
	_set_mode(Mode.TURN)


func start_destroy() -> void:
	_set_mode(Mode.DESTROY)


func cancel() -> void:
	_set_mode(Mode.NONE)


## Turns the piece in hand a quarter turn clockwise.
func turn_held_piece() -> void:
	if not is_holding_piece():
		return
	facing = (facing + 1) % 4
	hover(_last_point)


func hover(world_point: Vector2) -> void:
	_last_point = world_point
	var room: BuildingInterior = _room()
	var def: FurnitureDef = _ghost_def()
	_ghost.visible = room != null and def != null
	if not _ghost.visible:
		return
	var cell: Vector2i = room.room_cell_at(world_point)
	_ghost.global_position = Vector2((room.origin_cell() + cell) * NavGrid.CELL)
	_ghost.size = Vector2(Furniture.turned_size(def.footprint, facing) * NavGrid.CELL)
	_ghost.color = valid_color if _fits(room, cell) else invalid_color


func click(world_point: Vector2) -> void:
	var room: BuildingInterior = _room()
	if room == null:
		return
	var cell: Vector2i = room.room_cell_at(world_point)
	match mode:
		Mode.PLACE:
			if _fits(room, cell) and _wallet.spend(place_def.cost):
				room.place_furniture(place_def, cell, facing)
		Mode.MOVE:
			_click_move(room, cell)
		Mode.TURN:
			var piece: Furniture = room.furniture_at(cell)
			if piece != null:
				room.turn_furniture(piece)
		Mode.DESTROY:
			var piece: Furniture = room.furniture_at(cell)
			if piece != null:
				room.remove_furniture(piece)
	hover(world_point)


func _click_move(room: BuildingInterior, cell: Vector2i) -> void:
	if _carried == null:
		_carried = room.furniture_at(cell)
		if _carried != null:
			facing = _carried.facing
	elif _fits(room, cell):
		room.move_furniture(_carried, cell, facing)
		_carried = null


## Furniture only goes in the room being looked at.
func _room() -> BuildingInterior:
	var building: Building = _world.camera.interior_building
	return building.interior if building != null else null


## What the ghost should preview, or null to hide it.
func _ghost_def() -> FurnitureDef:
	if mode == Mode.PLACE:
		return place_def
	if mode == Mode.MOVE and _carried != null:
		return _carried.def
	return null


func _fits(room: BuildingInterior, cell: Vector2i) -> bool:
	if mode == Mode.PLACE:
		return room.can_place(place_def, cell, null, facing) and _wallet.can_afford(place_def.cost)
	if mode == Mode.MOVE and _carried != null:
		return room.can_place(_carried.def, cell, _carried, facing)
	return false


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_carried = null
	facing = 0
	_ghost.visible = false
	mode_changed.emit()
