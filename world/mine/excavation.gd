class_name Excavation
extends Node
## Decides where miners tunnel when they have no ore node to work.
##
## Tunnels are two cells tall and grow one column at a time from "heads".
## They run mostly flat, sometimes step up or down by one cell, and sometimes
## fork into an upper and a lower branch.
##
## The rule that keeps dwarves from ever being trapped: a column is only dug
## if the cell above it and the cell below it are solid and stay solid. So no
## dig can take the floor out from under an existing tunnel, and every new
## column is a single step away from the one before it.

var _terrain: Terrain
var _def: MineLevelDef
var _bounds: Rect2i
var _heads: Array[DigHead] = []
## Cells some head is about to dig, and cells some head needs to stay solid.
var _reserved_dig: Dictionary[Vector2i, bool] = {}
var _reserved_solid: Dictionary[Vector2i, bool] = {}
var _rng := RandomNumberGenerator.new()


func setup(terrain: Terrain, def: MineLevelDef, bounds: Rect2i) -> void:
	_terrain = terrain
	_def = def
	_bounds = bounds
	_rng.seed = def.noise_seed


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


## Gives the miner a tunnel end to work: the one he already has, or the
## nearest free one. Null when every tunnel is taken or finished.
func claim_head(miner: Node, near: Vector2i) -> DigHead:
	var best: DigHead = null
	for head: DigHead in _heads:
		if head.claimed_by == miner:
			return head
		if head.claimed_by != null and is_instance_valid(head.claimed_by):
			continue
		if best == null or _distance(head.stand_cell, near) < _distance(best.stand_cell, near):
			best = head
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
	if head.pending.is_empty():
		_complete_column(head)


func _complete_column(head: DigHead) -> void:
	_unreserve(head)
	var column: int = head.stand_cell.x + head.direction
	if head.is_fork:
		_split(head, column)
	else:
		head.stand_cell = Vector2i(column, head.stand_cell.y + head.step)
		if head.step != 0:
			_terrain.add_plank(head.stand_cell)
			if head.step == head.slope_dir:
				head.slope_steps_left -= 1
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
	if _wants_fork(head) and _fork_ok(column, feet_row):
		head.is_fork = true
		head.step = 0
		_reserve(head, column, feet_row - 2, feet_row + 1)
		return true
	for step: int in _step_options(head):
		if _column_ok(column, feet_row + step):
			head.step = step
			_reserve(head, column, feet_row + step - 1, feet_row + step)
			return true
	return false


func _wants_fork(head: DigHead) -> bool:
	if head.straight_left > 0 or head.slope_steps_left > 0:
		return false
	return _heads.size() < _def.max_heads and _rng.randf() < _def.fork_chance


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


## Can a two-tall column with its floor at `feet_row` be dug here?
func _column_ok(column: int, feet_row: int) -> bool:
	return _span_ok(column, feet_row - 1, feet_row)


func _fork_ok(column: int, feet_row: int) -> bool:
	return _span_ok(column, feet_row - 2, feet_row + 1)


## Checks a vertical run of cells to dig, plus the cap above and below it.
func _span_ok(column: int, top_row: int, bottom_row: int) -> bool:
	if column <= _bounds.position.x or column >= _bounds.end.x - 1:
		return false
	if top_row - 1 < _bounds.position.y or bottom_row + 1 >= _bounds.end.y:
		return false
	for row: int in range(top_row, bottom_row + 1):
		var cell := Vector2i(column, row)
		if not _terrain.is_diggable(cell) or _reserved_dig.has(cell) or _reserved_solid.has(cell):
			return false
	for cap: Vector2i in [Vector2i(column, top_row - 1), Vector2i(column, bottom_row + 1)]:
		if _terrain.is_open(cap) or _reserved_dig.has(cap):
			return false
	return true


func _reserve(head: DigHead, column: int, top_row: int, bottom_row: int) -> void:
	head.pending.clear()
	# Dig from the top down so the miner always has a floor to stand by.
	for row: int in range(top_row, bottom_row + 1):
		var cell := Vector2i(column, row)
		head.pending.append(cell)
		head.reserved_dig.append(cell)
		_reserved_dig[cell] = true
	for cap: Vector2i in [Vector2i(column, top_row - 1), Vector2i(column, bottom_row + 1)]:
		head.reserved_solid.append(cap)
		_reserved_solid[cap] = true


func _unreserve(head: DigHead) -> void:
	for cell: Vector2i in head.reserved_dig:
		_reserved_dig.erase(cell)
	for cell: Vector2i in head.reserved_solid:
		_reserved_solid.erase(cell)
	head.reserved_dig.clear()
	head.reserved_solid.clear()


func _retire(head: DigHead) -> void:
	head.is_dead = true
	head.claimed_by = null
	_heads.erase(head)


func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
