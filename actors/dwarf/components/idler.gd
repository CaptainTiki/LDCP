class_name Idler
extends Node
## When a dwarf's job has nothing at all for him to do, he potters about near
## his workplace with a "?" over his head until it does: a miner by the mine
## entrance, a cook inside his kitchen, a farmer among the plots, a dwarf
## with no job outside the Great Hall. The "?" tells the player he needs a
## new job, or that his job needs something only the player can give:
## seeds, a recipe, more mine. Staying by the workplace shows the
## assignment took, and keeps the town moving.
##
## Roles call potter() on every tick they have nothing for him, the way they
## call Worker.work_on(). The first tick none does, he gets back to work.
## Waiting that sorts itself out (a crop growing, a stove cooking) isn't
## idling: the role waits at the job instead.

## How far from home a wander may go, in nav cells.
@export var wander_cells: int = 6
@export var min_pause_seconds: float = 2.0
@export var max_pause_seconds: float = 6.0

## Why he has nothing to do, for his card. Empty while he has work.
var reason: String = ""

var _asked_this_tick: bool = false
var _home: Vector2i = NavGrid.NO_CELL
var _spot: Vector2i = NavGrid.NO_CELL
var _pause_left: float = 0.0

@onready var _dwarf: Dwarf = get_parent() as Dwarf


func begin_tick() -> void:
	_asked_this_tick = false


## One tick of having nothing to do: wander about near `home`, stopping
## now and then.
func potter(why: String, home: Vector2i, delta: float) -> void:
	_asked_this_tick = true
	reason = why
	if home != _home:
		_home = home
		_spot = NavGrid.NO_CELL
		_pause_left = 0.0
	_pause_left -= delta
	if _pause_left > 0.0:
		return
	if _spot == NavGrid.NO_CELL:
		_spot = _pick_spot()
	if _spot == NavGrid.NO_CELL:
		return  # No luck this tick; pick again next.
	if _dwarf.mover.is_at(_spot):
		_spot = NavGrid.NO_CELL
		_pause_left = randf_range(min_pause_seconds, max_pause_seconds)
	elif not _dwarf.mover.travel_to(_spot):
		_spot = NavGrid.NO_CELL


## After the role has acted. If it found him work, he gets back to it.
func end_tick() -> void:
	if _asked_this_tick or reason.is_empty():
		return
	reason = ""
	_home = NavGrid.NO_CELL
	_spot = NavGrid.NO_CELL
	_pause_left = 0.0


func is_idle() -> bool:
	return not reason.is_empty()


## A random standable cell near home, in the same place as home (the same
## room, or out in town).
func _pick_spot() -> Vector2i:
	var cell: Vector2i = _home + Vector2i(randi_range(-wander_cells, wander_cells), randi_range(-wander_cells, wander_cells))
	if not _dwarf.world.nav.is_walkable(cell) or not _same_place(cell, _home):
		return NavGrid.NO_CELL
	return cell


func _same_place(a: Vector2i, b: Vector2i) -> bool:
	var world: World = _dwarf.world
	return world.interiors.room_at(a) == world.interiors.room_at(b) \
			and world.surface.contains_cell(a) == world.surface.contains_cell(b)
