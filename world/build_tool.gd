class_name BuildTool
extends Node2D
## The player's building hand: place new buildings and plots on the town
## grid, pick one up and move it, or knock one down. The Ghost child previews
## where a building would land, green when it fits and red when it does not.

signal mode_changed

enum Mode { NONE, PLACE, MOVE, DESTROY }

@export var valid_color: Color = Color(0.3, 1.0, 0.3, 0.45)
@export var invalid_color: Color = Color(1.0, 0.3, 0.3, 0.45)

var mode: Mode = Mode.NONE

var _world: World
var _wallet: Wallet
## What PLACE mode is placing.
var _def: BuildingDef
## What MOVE mode has picked up, or null if nothing yet.
var _carried: Placeable

@onready var _ghost: ColorRect = $Ghost


func setup(world: World, wallet: Wallet) -> void:
	_world = world
	_wallet = wallet
	_ghost.visible = false


func is_active() -> bool:
	return mode != Mode.NONE


func start_place(def: BuildingDef) -> void:
	_def = def
	_set_mode(Mode.PLACE)


func start_move() -> void:
	_set_mode(Mode.MOVE)


func start_destroy() -> void:
	_set_mode(Mode.DESTROY)


func cancel() -> void:
	_set_mode(Mode.NONE)


func hover(world_point: Vector2) -> void:
	var def: BuildingDef = _ghost_def()
	_ghost.visible = def != null
	if def == null:
		return
	var tile: Vector2i = _world.surface.tile_at(world_point)
	_ghost.global_position = _world.surface.tile_to_world(tile)
	_ghost.size = Vector2(def.footprint * Placeable.TILE_PIXELS)
	_ghost.color = valid_color if _fits(tile) else invalid_color


func click(world_point: Vector2, clickable: Clickable) -> void:
	var tile: Vector2i = _world.surface.tile_at(world_point)
	match mode:
		Mode.PLACE:
			if _on_surface() and _fits(tile) and _wallet.spend(_def.cost):
				_world.surface.build(_def, tile)
		Mode.MOVE:
			if _on_surface():
				_click_move(tile)
		Mode.DESTROY:
			_click_destroy(tile, clickable)
	hover(world_point)


func _click_move(tile: Vector2i) -> void:
	if _carried == null:
		var picked: Placeable = _world.surface.placeable_at(tile)
		if picked != null and picked.def.can_move:
			_carried = picked
	elif _fits(tile):
		_world.surface.move(_carried, tile)
		_carried = null


func _click_destroy(tile: Vector2i, clickable: Clickable) -> void:
	# Indoors the tool removes workstations. In town, buildings and plots.
	var indoors: Building = _world.camera.interior_building
	if indoors != null:
		if clickable != null and clickable.entity() is Workstation:
			indoors.interior.remove_workstation(clickable.entity() as Workstation)
		return
	if not _on_surface():
		return
	var target: Placeable = _world.surface.placeable_at(tile)
	if target != null and target.def.can_destroy:
		_world.surface.demolish(target)


## Building only happens in the town view.
func _on_surface() -> bool:
	return _world.camera.current_view() == ViewCamera.View.SURFACE


## What the ghost should preview, or null to hide it.
func _ghost_def() -> BuildingDef:
	if not _on_surface():
		return null
	if mode == Mode.PLACE:
		return _def
	if mode == Mode.MOVE and _carried != null:
		return _carried.def
	return null


func _fits(tile: Vector2i) -> bool:
	if mode == Mode.PLACE:
		return _world.surface.is_free(_def, tile) and _wallet.can_afford(_def.cost)
	if mode == Mode.MOVE and _carried != null:
		return _world.surface.is_free(_carried.def, tile, _carried)
	return false


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_carried = null
	_ghost.visible = false
	mode_changed.emit()
