extends GutTest
## Pathfinding over walkable cells, ladders, steps and door portals.

var nav: NavGrid


func before_each() -> void:
	nav = autofree(NavGrid.new())


func _floor(from_x: int, to_x: int, row: int) -> void:
	for x: int in range(from_x, to_x + 1):
		nav.set_walkable(Vector2i(x, row))


func test_walks_along_a_floor() -> void:
	_floor(0, 5, 0)
	var path: Array[Vector2i] = nav.find_path(Vector2i(0, 0), Vector2i(5, 0))
	assert_eq(path.size(), 5)
	assert_eq(path[-1], Vector2i(5, 0))


func test_no_path_across_a_gap() -> void:
	_floor(0, 2, 0)
	_floor(4, 6, 0)
	assert_true(nav.find_path(Vector2i(0, 0), Vector2i(6, 0)).is_empty())


func test_takes_one_cell_steps_but_not_two() -> void:
	_floor(0, 2, 0)
	_floor(3, 5, 1)
	assert_false(nav.find_path(Vector2i(0, 0), Vector2i(5, 1)).is_empty(), "one-cell step down")
	_floor(6, 8, 3)
	assert_true(nav.find_path(Vector2i(0, 0), Vector2i(8, 3)).is_empty(), "two-cell drop is a wall")


func test_vertical_movement_needs_a_ladder() -> void:
	_floor(0, 2, 0)
	_floor(0, 2, 5)
	assert_true(nav.find_path(Vector2i(0, 0), Vector2i(0, 5)).is_empty())
	for row: int in range(0, 6):
		nav.set_walkable(Vector2i(1, row), NavGrid.LADDER)
	var path: Array[Vector2i] = nav.find_path(Vector2i(0, 0), Vector2i(2, 5))
	assert_false(path.is_empty())
	assert_true(path.has(Vector2i(1, 3)), "the route goes down the ladder")


func test_portal_joins_far_apart_cells() -> void:
	_floor(0, 3, 0)
	_floor(100, 103, -50)
	nav.link_portal(Vector2i(3, 0), Vector2i(100, -50))
	var path: Array[Vector2i] = nav.find_path(Vector2i(0, 0), Vector2i(103, -50))
	assert_eq(path.size(), 7)
	nav.unlink_portal(Vector2i(100, -50))
	assert_true(nav.find_path(Vector2i(0, 0), Vector2i(103, -50)).is_empty())


func test_mover_follows_a_path_at_walk_speed() -> void:
	_floor(0, 10, 0)
	var mover: GridMover = autofree(GridMover.new())
	mover.nav = nav
	mover.walk_speed = 8.0  # one cell per second
	mover.place_at(Vector2i(0, 0))
	assert_true(mover.travel_to(Vector2i(10, 0)))
	for i: int in 49:
		mover.sim_tick(0.1)
	assert_true(mover.is_moving(), "not there after 4.9 cells")
	for i: int in 52:
		mover.sim_tick(0.1)
	assert_true(mover.is_at(Vector2i(10, 0)))
