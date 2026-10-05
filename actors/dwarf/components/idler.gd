class_name Idler
extends Node
## When a dwarf's job has nothing at all for him to do, he goes and sits in
## the Great Hall with a "?" over his head until it does. The "?" tells the
## player he needs a new job, or that his job needs something only the
## player can give: seeds, a recipe, more mine.
##
## Roles call sit_out() on every tick they have nothing for him, the way
## they call Worker.work_on(). The first tick none does, he gets up.
## Waiting that sorts itself out (a crop growing, a stove cooking) isn't
## idling: the role waits at the job instead.

## Why he has nothing to do, for his card. Empty while he has work.
var reason: String = ""
## In a hall chair, rather than on his way or standing because every chair
## is taken.
var is_seated: bool = false

var _asked_this_tick: bool = false

@onready var _dwarf: Dwarf = get_parent() as Dwarf


func begin_tick() -> void:
	_asked_this_tick = false


## One tick of having nothing to do: head for a free chair in the hall, or
## the storage pile if there isn't one.
func sit_out(why: String) -> void:
	_asked_this_tick = true
	reason = why
	var hall: GreatHall = _dwarf.world.hall
	var seat: Vector2i = hall.claim_idle_seat(_dwarf)
	var spot: Vector2i = seat if seat != NavGrid.NO_CELL else hall.storage_cell()
	is_seated = seat != NavGrid.NO_CELL and _dwarf.mover.is_at(spot)
	if not _dwarf.mover.is_at(spot):
		_dwarf.mover.travel_to(spot)


## After the role has acted. If it found him work, he gets up.
func end_tick() -> void:
	if _asked_this_tick or reason.is_empty():
		return
	reason = ""
	is_seated = false
	_dwarf.world.hall.release_idle_seat(_dwarf)


func is_idle() -> bool:
	return not reason.is_empty()
