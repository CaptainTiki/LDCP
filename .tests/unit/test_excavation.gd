extends GutTest
## Autonomous tunnelling must stay organic and must never trap a dwarf:
## every cell a tunnel opens stays reachable from the landing. Miners with
## no tunnel end open new tunnels off the shaft, digging it deeper for room.

const TERRAIN_SCENE: PackedScene = preload("res://world/mine/terrain.tscn")
const LEVEL_DEF: MineLevelDef = preload("res://data/mine/level_1.tres")

var nav: NavGrid
var terrain: Terrain
var shaft: Shaft
var excavation: Excavation
var def: MineLevelDef
var landing := Vector2i(60, 8)
var bounds := Rect2i(0, 3, 120, 30)


func before_each() -> void:
	nav = add_child_autofree(NavGrid.new())
	terrain = add_child_autofree(TERRAIN_SCENE.instantiate())
	terrain.size_cells = Vector2i(120, 36)
	terrain.setup(nav)
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			terrain.set_cell(Vector2i(x, y), Terrain.Cell.DIRT)
	for dx: int in range(-2, 3):
		terrain.set_cell(landing + Vector2i(dx, -1), Terrain.Cell.AIR)
		terrain.set_cell(landing + Vector2i(dx, 0), Terrain.Cell.AIR)
	# Not in the tree: nothing to draw, just the ladder's nav cells.
	shaft = autofree(Shaft.new())
	shaft.column = landing.x
	shaft.setup(nav, terrain, landing.y)
	excavation = add_child_autofree(Excavation.new())


func _start(seed_value: int, stress: bool = true) -> void:
	def = LEVEL_DEF.duplicate()
	def.noise_seed = seed_value
	if stress:
		# Lots of slopes and forks, to stress the safety rule.
		def.slope_chance = 0.3
		def.fork_chance = 0.15
		def.max_heads = 8
	excavation.setup(terrain, def, bounds, shaft)
	excavation.add_head(landing + Vector2i(-2, 0), -1)
	excavation.add_head(landing + Vector2i(2, 0), 1)


## Digs with several miners at once, in a shuffled order, until done.
func _dig_everything(miner_count: int) -> int:
	var miners: Array[Node] = []
	for i: int in miner_count:
		miners.append(autofree(Node.new()))
	var cells_dug: int = 0
	for step: int in 20000:
		var miner: Node = miners[randi() % miner_count]
		var head: DigHead = excavation.claim_head(miner, landing)
		if head == null:
			if excavation.head_count() == 0:
				break
			continue
		assert_true(nav.is_walkable(head.stand_cell), "miners can stand at the tunnel end")
		excavation.finish_dig_cell(head)
		cells_dug += 1
		if randf() < 0.3:
			excavation.release_head(head, miner)
	return cells_dug


## Digs out the head's current column (or shaft cell) in one go.
func _finish(head: DigHead) -> void:
	while not head.pending.is_empty():
		excavation.finish_dig_cell(head)


func _unreachable_cells() -> int:
	var reached: Dictionary[Vector2i, bool] = {landing: true}
	var frontier: Array[Vector2i] = [landing]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for next: Vector2i in nav.neighbors(cell):
			if not reached.has(next):
				reached[next] = true
				frontier.append(next)
	var stranded: int = 0
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			if nav.is_walkable(cell) and not reached.has(cell):
				stranded += 1
	return stranded


func test_tunnels_never_strand_a_cell() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		before_each()
		seed(seed_value)
		_start(seed_value)
		var dug: int = _dig_everything(4)
		assert_gt(dug, 40, "seed %d dug a real tunnel network" % seed_value)
		assert_eq(_unreachable_cells(), 0, "seed %d left every tunnel reachable" % seed_value)
		assert_null(excavation.claim_head(autofree(Node.new()), landing), "seed %d: a dug-out mine has no room left" % seed_value)


func test_tunnels_stay_inside_the_level() -> void:
	_start(11)
	_dig_everything(3)
	for x: int in range(0, 120):
		if x != shaft.column:  # The shaft comes down through the top row.
			assert_false(terrain.is_open(Vector2i(x, bounds.position.y)), "top row is never dug")
		assert_false(terrain.is_open(Vector2i(x, bounds.end.y - 1)), "bottom row is never dug")


func test_rock_takes_more_work_than_dirt() -> void:
	_start(1)
	terrain.set_cell(Vector2i(5, 5), Terrain.Cell.ROCK)
	assert_gt(excavation.dig_work(Vector2i(5, 5)), excavation.dig_work(Vector2i(6, 5)))


func test_landing_tunnels_come_first_then_the_shaft() -> void:
	_start(1, false)
	var first: DigHead = excavation.claim_head(autofree(Node.new()), landing)
	var second: DigHead = excavation.claim_head(autofree(Node.new()), landing)
	assert_false(first.is_shaft or second.is_shaft, "the landing's two tunnels are taken first")
	var third: DigHead = excavation.claim_head(autofree(Node.new()), landing)
	assert_true(third.is_shaft, "with no room for a branch yet, the third miner digs the shaft down")


func test_shaft_digger_opens_a_branch_once_there_is_room() -> void:
	_start(1, false)
	excavation.claim_head(autofree(Node.new()), landing)
	excavation.claim_head(autofree(Node.new()), landing)
	var digger: Node = autofree(Node.new())
	var head: DigHead = excavation.claim_head(digger, landing)
	var cells: int = 0
	while head.claimed_by == digger and cells < 30:
		_finish(head)
		cells += 1
	assert_gt(shaft.bottom_cell().y, landing.y, "the shaft got deeper")
	assert_true(nav.is_climbable(shaft.bottom_cell()), "and the ladder reaches the bottom")
	assert_null(head.claimed_by, "with room for a tunnel, the shaft lets him go")
	var branch: DigHead = excavation.claim_head(digger, landing)
	assert_false(branch.is_shaft)
	assert_eq(branch.stand_cell.x, shaft.column, "the new tunnel leaves the side of the shaft")
	var rows_below_landing: int = branch.stand_cell.y - landing.y
	assert_eq(rows_below_landing, 2 + def.branch_gap_rows, "as high as it can, the gap clear of the landing tunnel")


func test_branches_keep_their_distance() -> void:
	_start(3)
	_dig_everything(5)
	for side: int in [-1, 1]:
		var column: int = shaft.column + side
		var solid_run: int = -1  # Rows of ground since the last tunnel, -1 before the first.
		for y: int in range(bounds.position.y, bounds.end.y):
			if terrain.is_open(Vector2i(column, y)):
				if solid_run > 0:
					assert_gte(solid_run, def.branch_gap_rows, "tunnels leaving the shaft are spaced out")
				solid_run = 0
			elif solid_run >= 0:
				solid_run += 1
