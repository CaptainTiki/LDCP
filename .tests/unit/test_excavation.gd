extends GutTest
## Autonomous tunnelling must stay organic and must never trap a dwarf:
## every cell a tunnel opens stays reachable from the landing.

const TERRAIN_SCENE: PackedScene = preload("res://world/mine/terrain.tscn")
const LEVEL_DEF: MineLevelDef = preload("res://data/mine/level_1.tres")

var nav: NavGrid
var terrain: Terrain
var excavation: Excavation
var landing := Vector2i(60, 12)
var bounds := Rect2i(0, 3, 120, 18)


func before_each() -> void:
	nav = add_child_autofree(NavGrid.new())
	terrain = add_child_autofree(TERRAIN_SCENE.instantiate())
	terrain.size_cells = Vector2i(120, 24)
	terrain.setup(nav)
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			terrain.set_cell(Vector2i(x, y), Terrain.Cell.DIRT)
	for dx: int in range(-2, 3):
		terrain.set_cell(landing + Vector2i(dx, -1), Terrain.Cell.AIR)
		terrain.set_cell(landing + Vector2i(dx, 0), Terrain.Cell.AIR)
	excavation = add_child_autofree(Excavation.new())


func _start(seed_value: int) -> void:
	var def: MineLevelDef = LEVEL_DEF.duplicate()
	def.noise_seed = seed_value
	# Lots of slopes and forks, to stress the safety rule.
	def.slope_chance = 0.3
	def.fork_chance = 0.15
	def.max_heads = 8
	excavation.setup(terrain, def, bounds)
	excavation.add_head(landing + Vector2i(-2, 0), -1)
	excavation.add_head(landing + Vector2i(2, 0), 1)


## Digs with several miners at once, in a shuffled order, until done.
func _dig_everything(miner_count: int) -> int:
	var miners: Array[Node] = []
	for i: int in miner_count:
		miners.append(autofree(Node.new()))
	var cells_dug: int = 0
	for step: int in 6000:
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


func test_tunnels_stay_inside_the_level() -> void:
	_start(11)
	_dig_everything(3)
	for x: int in range(0, 120):
		assert_false(terrain.is_open(Vector2i(x, bounds.position.y)), "top row is never dug")
		assert_false(terrain.is_open(Vector2i(x, bounds.end.y - 1)), "bottom row is never dug")


func test_rock_takes_more_work_than_dirt() -> void:
	_start(1)
	terrain.set_cell(Vector2i(5, 5), Terrain.Cell.ROCK)
	assert_gt(excavation.dig_work(Vector2i(5, 5)), excavation.dig_work(Vector2i(6, 5)))
