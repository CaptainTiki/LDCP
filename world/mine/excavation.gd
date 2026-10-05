class_name Excavation
extends Node
## Decides where miners tunnel when they have no ore node to work.
##
## Tunnels are two cells tall and grow one column at a time from "heads".
## They run mostly flat, sometimes step up or down by one cell, and sometimes
## fork into an upper and a lower branch. Two tunnels start from the landing;
## after that, new ones leave the side of the shaft as miners need them, and
## the shaft is dug deeper to make room (ShaftDigging). DigSafety makes sure
## no dig can ever trap a dwarf.

var _terrain: Terrain
var _def: MineLevelDef
var _bounds: Rect2i
var _safety: DigSafety
var _shaft_digging: ShaftDigging
var _heads: Array[DigHead] = []
var _rng := RandomNumberGenerator.new()
## Distances are measured from here for a miner who isn't down the mine yet.
var _entry_cell: Vector2i


func setup(terrain: Terrain, def: MineLevelDef, bounds: Rect2i, shaft: Shaft) -> void:
	_terrain = terrain
	_def = def
	_bounds = bounds
	_rng.seed = def.noise_seed
	_safety = DigSafety.new(terrain, bounds)
	_shaft_digging = ShaftDigging.new(shaft, _safety, def, bounds.position.y)
	_entry_cell = Vector2i(shaft.column, bounds.position.y)
	var shaft_head: DigHead = _shaft_digging.make_shaft_head()
	if _shaft_digging.plan(shaft_head):
		_heads.append(shaft_head)


## Starts a tunnel leading away from `stand_cell`.
func add_head(stand_cell: Vector2i, direction: int) -> void:
	var head := DigHead.new()
	head.stand_cell = stand_cell
	head.direction = direction
	head.straight_left = _def.straight_start_columns
	if _plan(head):
		_heads.append(head)


func head_count() -> int:
	return _heads.size()


## Gives the miner a place to dig: the head he already has, else the nearest
## free tunnel end, else a new tunnel off the shaft, else the shaft itself to
## dig deeper. Null when the mine has no room for him.
func claim_head(miner: Node, near: Vector2i) -> DigHead:
	if not _bounds.has_point(near):
		near = _entry_cell
	var best: DigHead = null
	var shaft_head: DigHead = null
	for head: DigHead in _heads:
		if head.claimed_by == miner:
			return head
		if head.claimed_by != null and is_instance_valid(head.claimed_by):
			continue
		if head.is_shaft:
			shaft_head = head
		elif best == null or _distance(head.stand_cell, near) < _distance(best.stand_cell, near):
			best = head
	if best == null:
		best = _open_branch()
	if best == null:
		best = shaft_head
	if best != null:
		best.claimed_by = miner
	return best


func release_head(head: DigHead, miner: Node) -> void:
	if head != null and head.claimed_by == miner:
		head.claimed_by = null


func next_dig_cell(head: DigHead) -> Vector2i:
	if head.is_dead or head.pending.is_empty():
		return NavGrid.NO_CELL
	return head.pending[0]


func dig_work(cell: Vector2i) -> float:
	return _def.rock_work if _terrain.get_cell(cell) == Terrain.Cell.ROCK else _def.dirt_work


## Call when the miner has finished chipping out next_dig_cell().
func finish_dig_cell(head: DigHead) -> void:
	if head.pending.is_empty():
		return
	_terrain.dig(head.pending.pop_front())
	if not head.pending.is_empty():
		return
	_safety.unreserve(head)
	if head.is_shaft:
		_deepen_shaft(head)
	else:
		_complete_column(head)


func _open_branch() -> DigHead:
	var head: DigHead = _shaft_digging.open_branch()
	if head == null or not _plan(head):
		return null
	_heads.append(head)
	return head


func _deepen_shaft(head: DigHead) -> void:
	_shaft_digging.deepen(head)
	if not _shaft_digging.plan(head):
		_retire(head)
	elif _shaft_digging.has_branch_spot():
		# Deep enough for a new tunnel: the shaft digger goes and opens it.
		# The shaft waits for whoever next has nowhere else to dig.
		head.claimed_by = null


func _complete_column(head: DigHead) -> void:
	var column: int = head.stand_cell.x + head.direction
	if head.is_fork:
		_split(head, column)
	else:
		head.stand_cell = Vector2i(column, head.stand_cell.y + head.step)
		if head.step != 0:
			_terrain.add_plank(head.stand_cell)
		if head.slope_steps_left > 0:
			# A slope that couldn't go on (the surface, a deposit in the way) is
			# over. Left pending, it would block new slopes and forks for good.
			head.slope_steps_left = head.slope_steps_left - 1 if head.step == head.slope_dir else 0
		head.straight_left = maxi(0, head.straight_left - 1)
	if not _plan(head):
		_retire(head)


## A fork column is four cells tall. The upper tunnel leaves from a plank
## half way up, and the lower one carries on from the bottom.
func _split(head: DigHead, column: int) -> void:
	var upper := Vector2i(column, head.stand_cell.y - 1)
	_terrain.add_plank(upper)
	var branch := DigHead.new()
	branch.stand_cell = upper
	branch.direction = head.direction
	branch.slope_dir = -1
	branch.slope_steps_left = _rng.randi_range(2, 3)
	if _plan(branch):
		_heads.append(branch)
	head.stand_cell = Vector2i(column, head.stand_cell.y + 1)
	head.slope_dir = 1
	head.slope_steps_left = _rng.randi_range(2, 3)
	head.is_fork = false


## Chooses the head's next column and reserves its cells.
## Returns false if the tunnel has nowhere left to go.
func _plan(head: DigHead) -> bool:
	var column: int = head.stand_cell.x + head.direction
	var feet_row: int = head.stand_cell.y
	if _wants_fork(head) and _safety.span_ok(column, feet_row - 2, feet_row + 1):
		head.is_fork = true
		head.step = 0
		_safety.reserve(head, column, feet_row - 2, feet_row + 1)
		return true
	for step: int in _step_options(head):
		if _safety.span_ok(column, feet_row + step - 1, feet_row + step):
			head.step = step
			_safety.reserve(head, column, feet_row + step - 1, feet_row + step)
			return true
	return false


func _wants_fork(head: DigHead) -> bool:
	if head.straight_left > 0 or head.slope_steps_left > 0:
		return false
	return _tunnel_count() < _def.max_heads and _rng.randf() < _def.fork_chance


func _tunnel_count() -> int:
	var count: int = 0
	for head: DigHead in _heads:
		if not head.is_shaft:
			count += 1
	return count


## Steps to try, most wanted first: -1 up, 0 flat, 1 down.
func _step_options(head: DigHead) -> Array[int]:
	var either_way: int = 1 if _rng.randf() < 0.5 else -1
	if head.straight_left > 0:
		return [0, either_way, -either_way]
	if head.slope_steps_left <= 0 and _rng.randf() < _def.slope_chance:
		head.slope_dir = either_way
		head.slope_steps_left = _rng.randi_range(1, 3)
	if head.slope_steps_left > 0:
		return [head.slope_dir, 0, -head.slope_dir]
	return [0, either_way, -either_way]


func _retire(head: DigHead) -> void:
	head.is_dead = true
	head.claimed_by = null
	_heads.erase(head)


func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
