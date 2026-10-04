class_name IdleRole
extends DwarfRole
## An unassigned dwarf potters about near the Great Hall.

## How far from the hall door a wander may go, in nav cells.
@export var wander_cells: int = 14
@export var min_pause_seconds: float = 3.0
@export var max_pause_seconds: float = 8.0

var _spot: Vector2i = NavGrid.NO_CELL
var _pause_left: float = 0.0


func act(delta: float) -> void:
	# Left holding something from an old job? Put it away first.
	if not dwarf.carrier.is_empty():
		_haul_to_hall()
		return
	_pause_left -= delta
	if _pause_left > 0.0:
		return
	if _spot == NavGrid.NO_CELL:
		_spot = dwarf.world.hall.door_cell() + Vector2i(
				randi_range(-wander_cells, wander_cells), randi_range(0, wander_cells / 2))
		if not dwarf.world.nav.is_walkable(_spot):
			_spot = NavGrid.NO_CELL
			return
	if _walk_to(_spot):
		_spot = NavGrid.NO_CELL
		_pause_left = randf_range(min_pause_seconds, max_pause_seconds)


func release() -> void:
	_spot = NavGrid.NO_CELL
	_pause_left = 0.0
