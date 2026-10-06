extends GutTest
## Runs the real game scene at high speed and checks the town-feeds-the-mine
## loop end to end. Each test starts a fresh game.

const GAME_SCENE: PackedScene = preload("res://game/game.tscn")
const POTATO: ItemDef = preload("res://data/items/potato.tres")
const BARLEY: ItemDef = preload("res://data/items/barley.tres")
const COPPER: ItemDef = preload("res://data/items/copper_ore.tres")
const BARLEY_MASH: ItemDef = preload("res://data/items/barley_mash.tres")
const POTATO_MASH: ItemDef = preload("res://data/items/potato_mash.tres")
const STEW: MealDef = preload("res://data/items/stew.tres")
const GRUEL: MealDef = preload("res://data/items/gruel.tres")
const GROG: DrinkDef = preload("res://data/items/grog.tres")
const ALE: DrinkDef = preload("res://data/items/ale.tres")
const KITCHEN: BuildingDef = preload("res://data/buildings/kitchen.tres")
const BREWERY: BuildingDef = preload("res://data/buildings/brewery.tres")
const FARM_PLOT: BuildingDef = preload("res://data/buildings/farm_plot.tres")
const POTATO_CROP: CropDef = preload("res://data/crops/potato.tres")
const BARLEY_CROP: CropDef = preload("res://data/crops/barley.tres")
const CARROT_CROP: CropDef = preload("res://data/crops/carrot.tres")
const ONION_CROP: CropDef = preload("res://data/crops/onion.tres")
const ONION: ItemDef = preload("res://data/items/onion.tres")
const ONION_SOUP: MealDef = preload("res://data/items/onion_soup.tres")
const ONION_SOUP_RECIPE: RecipeDef = preload("res://data/recipes/onion_soup.tres")
const STOVE: WorkstationDef = preload("res://data/workstations/stove.tres")
const FERMENTER: WorkstationDef = preload("res://data/workstations/fermenter.tres")
const STEW_RECIPE: RecipeDef = preload("res://data/recipes/stew.tres")
const GRUEL_RECIPE: RecipeDef = preload("res://data/recipes/gruel.tres")
const BARLEY_MASH_RECIPE: RecipeDef = preload("res://data/recipes/barley_mash.tres")
const POTATO_MASH_RECIPE: RecipeDef = preload("res://data/recipes/potato_mash.tres")
const ALE_RECIPE: RecipeDef = preload("res://data/recipes/ale.tres")
const GROG_RECIPE: RecipeDef = preload("res://data/recipes/grog.tres")
const CHAIR: FurnitureDef = preload("res://data/furniture/chair.tres")
const TABLE: FurnitureDef = preload("res://data/furniture/table.tres")
const LONG_TABLE: FurnitureDef = preload("res://data/furniture/long_table.tres")

var game: Game
var world: World
var storage: Storage


func before_each() -> void:
	game = add_child_autofree(GAME_SCENE.instantiate())
	# Tests drive time by hand.
	game.clock.set_process(false)
	world = game.world
	storage = world.hall.storage


func after_each() -> void:
	# Let nodes queued for deletion during the test actually go.
	await wait_physics_frames(2)


## Keeps everyone working (and out of the pantry) for the whole test.
func _nobody_gets_hungry() -> void:
	for dwarf: Dwarf in world.dwarves.active():
		dwarf.hunger.fill(100000.0)


func _run_seconds(seconds: float) -> void:
	game.clock.advance(roundi(seconds / game.clock.tick_seconds))


func _dwarf(index: int) -> Dwarf:
	return world.dwarves.active()[index]


func _plot(index: int) -> FarmPlot:
	return world.surface.farm_plots()[index]


func test_starting_state() -> void:
	assert_eq(world.dwarves.active_count(), 4)
	assert_eq(world.surface.farm_plots().size(), 9, "a 3x3 starting farm")
	var tables: int = 0
	for piece: Furniture in world.hall.interior.furniture():
		if piece.def == TABLE:
			tables += 1
	assert_eq(tables, 2, "two tables")
	assert_eq(world.hall.interior.seat_count(), 4, "a chair for every starting dwarf")
	assert_eq(game.wallet.coins, game.tuning.starting_coins)
	assert_gt(storage.count(GRUEL), 0)
	assert_gt(storage.count(GROG), 0)
	assert_false(world.nav.find_path(world.hall.door_cell(), world.mine_level.landing_cell()).is_empty(),
		"town, shaft and mine are one connected world")


func test_farmer_waters_harvests_and_hauls_but_never_sows() -> void:
	_nobody_gets_hungry()
	world.hand.select_seeds(POTATO_CROP)
	_click_plot(_plot(0))
	_click_plot(_plot(1))
	world.hand.put_away()
	_dwarf(0).assignment.assign(_plot(0))
	_run_seconds(POTATO_CROP.grow_seconds + 150.0)
	assert_eq(storage.count(POTATO), POTATO_CROP.yield_count * 2, "both plants watered, harvested and hauled")
	assert_false(_plot(0).is_planted(), "left empty for the player to sow again")
	assert_false(_plot(2).is_planted(), "farmers never sow")


func test_unwatered_crops_pause_and_never_die() -> void:
	var plot: FarmPlot = _plot(0)
	plot.sow(POTATO_CROP)
	plot.water()
	var wet_for: float = plot.watered_seconds_left
	assert_false(plot.water(), "wet soil takes no more water")
	_run_seconds(wet_for + 5.0)
	var grown: float = plot.growth_seconds
	assert_almost_eq(grown, wet_for, 0.5, "grew while watered")
	_run_seconds(120)
	assert_eq(plot.growth_seconds, grown, "growth paused while dry")
	assert_eq(plot.current_task(), FarmPlot.Task.WATER, "still alive, just thirsty")


func test_every_plant_takes_exactly_its_crops_waterings() -> void:
	var plots: Array[FarmPlot] = world.surface.farm_plots()
	var waterings: Dictionary[FarmPlot, int] = {}
	for plot: FarmPlot in plots:
		plot.sow(POTATO_CROP)
		waterings[plot] = 0
	var longest: float = POTATO_CROP.grow_seconds * (1.0 + POTATO_CROP.grow_spread)
	for _second: int in ceili(longest) + 5:
		for plot: FarmPlot in plots:
			if plot.current_task() == FarmPlot.Task.WATER and plot.water():
				waterings[plot] += 1
		_run_seconds(1)
	for plot: FarmPlot in plots:
		assert_true(plot.is_ripe(), "ripe within the spread")
		assert_eq(waterings[plot], POTATO_CROP.waterings, "however its numbers fell")


func test_a_field_sown_together_ripens_and_dries_unevenly() -> void:
	var ripe_at: Array[float] = []
	var wet_for: Array[float] = []
	for plot: FarmPlot in world.surface.farm_plots():
		plot.sow(POTATO_CROP)
		plot.water()
		ripe_at.append(plot.ripe_seconds())
		wet_for.append(plot.watered_seconds_left)
	var grow: float = POTATO_CROP.grow_seconds
	var spread: float = POTATO_CROP.grow_spread
	for seconds: float in ripe_at:
		assert_between(seconds, grow * (1.0 - spread), grow * (1.0 + spread), "near the crop's grow time")
	# Nine rolls landing within 5 seconds of each other is vanishingly unlikely.
	assert_gt(ripe_at.max() - ripe_at.min(), 5.0, "each plant ripens in its own time")
	assert_gt(wet_for.max() - wet_for.min(), 5.0, "and its soil dries in its own time")


func _click_plot(plot: FarmPlot) -> void:
	world.input.click(plot.global_position + Vector2(8, -8))


func test_player_farms_by_hand_with_tools() -> void:
	game.wallet.earn(100)
	var plot: FarmPlot = world.surface.build(FARM_PLOT, Vector2i(10, 5)) as FarmPlot
	var hand: PlayerHand = world.hand
	_click_plot(plot)
	assert_false(plot.is_planted(), "an empty hand does nothing to a plot")
	assert_eq(plot.current_task(), FarmPlot.Task.NONE, "an empty plot is no job for a farmer")

	hand.select_seeds(BARLEY_CROP)
	var coins: int = game.wallet.coins
	_click_plot(plot)
	assert_true(plot.is_planted(), "seeds sow an empty plot in one click")
	assert_eq(plot.crop, BARLEY_CROP)
	assert_eq(game.wallet.coins, coins - BARLEY_CROP.seed_cost, "a seed costs a coin")
	_click_plot(plot)
	assert_eq(game.wallet.coins, coins - BARLEY_CROP.seed_cost, "no paying twice for a sown plot")
	hand.select(PlayerHand.Tool.BUCKET)
	while not plot.is_ripe():
		_click_plot(plot)
		_run_seconds(5)
	hand.select(PlayerHand.Tool.SHEARS)
	_click_plot(plot)
	assert_false(plot.is_planted(), "harvested")
	assert_eq(hand.carrier.count, BARLEY_CROP.yield_count, "the crop is in the player's hand")
	assert_eq(storage.count(BARLEY), 0, "not in the hall yet")
	world.input.click(world.hall.global_position + Vector2(40, -40))
	assert_eq(storage.count(BARLEY), BARLEY_CROP.yield_count, "clicking the Great Hall drops it off")
	assert_eq(world.camera.current_view(), ViewCamera.View.SURFACE, "that click did not walk into the hall")
	assert_eq(plot.current_task(), FarmPlot.Task.NONE, "the player sows again, not the farmers")


func test_hoe_roots_up_a_plant() -> void:
	var plots: int = world.surface.farm_plots().size()
	var plot: FarmPlot = _plot(0)
	plot.sow(BARLEY_CROP)
	_run_seconds(1)
	world.hand.select(PlayerHand.Tool.HOE)
	_click_plot(plot)
	assert_false(plot.is_planted(), "rooted up, growing or not")
	assert_eq(world.surface.farm_plots().size(), plots, "the plot itself stays")
	assert_eq(storage.count(BARLEY), 0, "nothing harvested")
	world.input.click(_tile_point(Vector2i(10, 6)))
	assert_eq(world.surface.farm_plots().size(), plots, "the hoe doesn't make plots: they're bought in Build")


func test_look_shows_what_a_plot_is_up_to() -> void:
	var card: LookCard = game.hud.get_node("Root/LookCard")
	var spot: Vector2 = _plot(0).global_position + Vector2(8, -8)
	world.hand.select(PlayerHand.Tool.LOOK)
	world.input.hover(spot)
	assert_eq(card.current_lines()[0], "Empty plot")
	_plot(0).sow(POTATO_CROP)
	assert_eq(card.current_lines()[0], "Potato")
	assert_has(card.current_lines(), "Dry, needs water")
	assert_has(card.current_lines(), "2 more waterings")
	world.input.click(spot)
	assert_false(world.hand.is_holding_tool(), "any click puts the glass away")
	assert_true(card.current_lines().is_empty(), "and the pop-up goes with it")
	assert_eq(_plot(0).current_task(), FarmPlot.Task.WATER, "the click did nothing else")


func test_dwarf_dropped_on_an_unsown_plot_becomes_a_farmer() -> void:
	var dwarf: Dwarf = _dwarf(0)
	var plot: FarmPlot = _plot(2)
	world.input.assign_at(dwarf, plot.global_position + Vector2(8, -8))
	assert_eq(dwarf.assignment.kind(), JobAssignment.Kind.FARMER)
	_run_seconds(30)
	assert_eq(dwarf.status_text(), "Nothing sown", "with nothing sown, he has nothing to do")
	assert_lte(_cells_apart(dwarf.mover.cell, plot.work_cell()), 8, "so he potters about the plots")
	plot.sow(POTATO_CROP)
	_run_seconds(30)
	assert_gt(plot.watered_seconds_left, 0.0, "and gets to it once it's sown")
	_run_seconds(5)
	assert_true(dwarf.mover.is_at(plot.work_cell()), "while it grows, he waits by his plot")
	assert_false(dwarf.idler.is_idle(), "which isn't idling: work is coming")


func test_dragging_a_tool_sweeps_a_row_of_plots() -> void:
	world.hand.select_seeds(POTATO_CROP)
	var plots: Array[FarmPlot] = world.surface.farm_plots()
	world.input.click(plots[0].global_position + Vector2(8, -8))
	world.input.drag(plots[1].global_position + Vector2(8, -8))
	world.input.drag(plots[2].global_position + Vector2(8, -8))
	assert_true(plots[0].is_planted() and plots[1].is_planted() and plots[2].is_planted())
	assert_false(plots[3].is_planted())


func test_plants_grow_through_visible_stages() -> void:
	var plot: FarmPlot = _plot(0)
	var plant: Sprite2D = plot.get_node("Plant")
	var soil: Sprite2D = plot.get_node("Soil")
	assert_false(plant.visible, "bare soil")
	assert_eq(soil.texture, plot.dry_soil)
	plot.sow(POTATO_CROP)
	var frames: Array[int] = [plant.frame]
	while not plot.is_ripe():
		plot.water()
		assert_eq(soil.texture, plot.wet_soil, "watered soil looks wet")
		_run_seconds(5)
		if plant.frame != frames[-1]:
			frames.append(plant.frame)
	assert_eq(frames, [0, 1, 2, 3] as Array[int], "seedling, two growing stages, then ripe")


func test_holding_a_farm_tool_and_a_build_tool_are_exclusive() -> void:
	world.hand.select(PlayerHand.Tool.BUCKET)
	world.build_tool.start_destroy()
	assert_false(world.hand.is_holding_tool())
	world.hand.select(PlayerHand.Tool.SHEARS)
	assert_false(world.build_tool.is_active())


func test_hungry_dwarves_stall_and_gruel_restarts_them() -> void:
	storage.remove(GRUEL, storage.count(GRUEL))
	for dwarf: Dwarf in world.dwarves.active():
		dwarf.hunger.fill(0.0)
	_run_seconds(60)
	for dwarf: Dwarf in world.dwarves.active():
		assert_true(dwarf.meal_break.is_waiting_for_food, "%s is sitting waiting" % dwarf.dwarf_name)
		assert_not_null(world.interiors.room_at(dwarf.mover.cell), "waiting inside the hall")
	game.wallet.earn(100)
	for i: int in world.dwarves.active_count():
		assert_true(game.shop.buy_item(GRUEL))
	_run_seconds(10)
	for dwarf: Dwarf in world.dwarves.active():
		assert_false(dwarf.meal_break.in_progress, "%s is back at it" % dwarf.dwarf_name)
		assert_false(dwarf.hunger.is_empty())


func test_drink_is_topped_up_on_the_meal_visit() -> void:
	var dwarf: Dwarf = _dwarf(0)
	assert_eq(dwarf.thirst.multiplier(), 0.5, "no drink yet: the floor")
	dwarf.hunger.fill(0.0)
	_run_seconds(60)
	assert_eq(dwarf.thirst.drink, GROG)
	assert_gt(dwarf.worker.rate(), 0.5 * game.tuning.base_work_rate)


func test_food_and_drink_only_go_down_while_working() -> void:
	var idler: Dwarf = _dwarf(0)
	var farmer: Dwarf = _dwarf(1)
	_plot(0).sow(POTATO_CROP)
	farmer.assignment.assign(_plot(0))
	var food_at_start: float = idler.hunger.seconds_left
	_run_seconds(60)
	assert_eq(idler.hunger.seconds_left, food_at_start, "idling and walking cost no food")
	assert_lt(farmer.hunger.seconds_left, food_at_start, "working does")
	assert_gt(farmer.hunger.seconds_left, food_at_start - 60.0, "but only the time spent working")


func test_a_cook_makes_the_best_meal_he_can_and_it_reaches_the_hall() -> void:
	_nobody_gets_hungry()
	storage.add(POTATO, 4)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	assert_eq(kitchen.workstations().size(), 1, "a new kitchen comes with a stove")
	var stove: Workstation = kitchen.workstations()[0]
	assert_true(stove.is_idle(), "a new stove has no recipe")
	_dwarf(0).assignment.assign(kitchen)
	_run_seconds(80)
	assert_eq(stove.recipe, STEW_RECIPE, "from potatoes, stew is the best he can make")
	assert_eq(stove.state, Workstation.State.PROCESSING, "he brought them, set it and loaded it")
	_run_seconds(STEW_RECIPE.process_seconds * 2 + 240)
	assert_eq(storage.count(STEW), 2, "both batches cooked and carried to the hall")
	assert_eq(storage.count(POTATO), 0)
	assert_true(stove.is_idle(), "and the stove rests with no recipe")
	assert_null(stove.recipe)


func test_brewery_needs_unlocking_then_brews_ale() -> void:
	assert_false(game.unlocks.is_unlocked(BREWERY))
	game.wallet.earn(500)
	assert_false(game.shop.unlock_building(BREWERY), "coins alone aren't enough")
	world.ledger.record_made(STEW, 10)
	assert_true(game.shop.unlock_building(BREWERY), "cook 10 meals, then trade")
	_nobody_gets_hungry()
	storage.add(BARLEY, 3)
	var brewery: Building = world.surface.build(BREWERY, Vector2i(40, 1)) as Building
	assert_eq(brewery.workstations().size(), 2, "a mash pot and a fermenter")
	_dwarf(0).assignment.assign(brewery)
	_run_seconds(BARLEY_MASH_RECIPE.process_seconds + ALE_RECIPE.process_seconds + 200)
	assert_eq(storage.count(ALE), ALE_RECIPE.output_count, "the brewer moved the mash himself, and one mash made four ales")
	assert_eq(storage.count(BARLEY_MASH), 0, "no mash left lying about")


func test_miners_tunnel_find_ore_and_haul_it_up() -> void:
	storage.add(STEW, 50)
	for dwarf: Dwarf in world.dwarves.active():
		dwarf.assignment.assign(world.mine_entrance)
	_run_seconds(400)
	var found: int = 0
	for node: OreNode in world.mine_level.ore_nodes():
		if node.revealed:
			found += 1
	assert_gt(found, 0, "tunnelling exposed an ore node")
	_run_seconds(900)
	assert_gt(storage.count(COPPER), 0, "ore was hauled up the ladder to the hall")
	var coins_before: int = game.wallet.coins
	assert_true(game.shop.sell_item(COPPER, storage.count(COPPER)))
	assert_gt(game.wallet.coins, coins_before, "ore sells for coins")
	for dwarf: Dwarf in world.dwarves.active():
		var way_home: bool = dwarf.mover.cell == world.hall.door_cell() \
				or not world.nav.find_path(dwarf.mover.cell, world.hall.door_cell()).is_empty()
		assert_true(way_home, "%s can always get home" % dwarf.dwarf_name)


func test_lift_shortens_the_trip() -> void:
	var dwarf: Dwarf = _dwarf(0)
	var ladder_seconds: float = _seconds_to_climb(dwarf)
	game.wallet.earn(game.tuning.lift_cost)
	assert_true(game.shop.buy_lift())
	var lift_seconds: float = _seconds_to_climb(dwarf)
	assert_lt(lift_seconds, ladder_seconds * 0.5, "the lift is much faster than the ladder")
	assert_false(game.shop.buy_lift(), "the lift is bought once")


func _seconds_to_climb(dwarf: Dwarf) -> float:
	var top: Vector2i = world.shaft.top_cell()
	dwarf.mover.place_at(world.mine_level.landing_cell())
	dwarf.mover.travel_to(top)
	var seconds: float = 0.0
	while not dwarf.mover.is_at(top) and seconds < 600.0:
		dwarf.mover.sim_tick(0.1)
		seconds += 0.1
	return seconds


func test_hiring_costs_coins_and_adds_a_dwarf() -> void:
	game.wallet.spend(game.wallet.coins)
	assert_false(game.shop.hire(), "no coins, no hire")
	game.wallet.earn(1000)
	var cost: int = game.shop.hire_cost()
	var coins: int = game.wallet.coins
	assert_true(game.shop.hire())
	assert_eq(world.dwarves.active_count(), 5)
	assert_eq(game.wallet.coins, coins - cost)
	assert_gt(game.shop.hire_cost(), cost, "each hire costs more")


## A point inside the given town tile.
func _tile_point(tile: Vector2i) -> Vector2:
	return world.surface.tile_to_world(tile) + Vector2(4, 4)


func test_build_move_and_destroy() -> void:
	var surface: Surface = world.surface
	var tool: BuildTool = world.build_tool
	var plots: int = surface.farm_plots().size()
	game.wallet.earn(100)
	tool.start_place(FARM_PLOT)
	world.input.click(_tile_point(Vector2i(10, 5)))
	var plot: Placeable = surface.placeable_at(Vector2i(10, 5))
	assert_not_null(plot, "placed")
	assert_eq(surface.farm_plots().size(), plots + 1)
	world.input.click(_tile_point(Vector2i(10, 5)))
	assert_eq(surface.farm_plots().size(), plots + 1, "cannot overlap what is already there")
	world.input.click(_tile_point(Vector2i(10, 9)))
	assert_eq(surface.farm_plots().size(), plots + 1, "cannot build off the edge of town")
	world.input.drag(_tile_point(Vector2i(11, 8)))
	world.input.drag(_tile_point(Vector2i(12, 8)))
	assert_eq(surface.farm_plots().size(), plots + 3, "dragging paints a row of plots")

	tool.start_move()
	world.input.click(_tile_point(Vector2i(10, 5)))
	world.input.click(_tile_point(Vector2i(14, 2)))
	assert_eq(plot.tile, Vector2i(14, 2), "moved")
	assert_null(surface.placeable_at(Vector2i(10, 5)))

	tool.start_destroy()
	world.input.click(_tile_point(Vector2i(14, 2)))
	assert_null(surface.placeable_at(Vector2i(14, 2)), "destroyed")
	world.input.click(_tile_point(world.hall.tile))
	assert_not_null(surface.placeable_at(world.hall.tile), "the Great Hall cannot be destroyed")
	tool.cancel()


func test_dwarves_walk_around_buildings_not_through_them() -> void:
	var hall: GreatHall = world.hall
	var inside: Vector2i = hall.work_cell()
	assert_false(world.nav.is_walkable(inside), "a building's footprint is solid")
	assert_true(world.nav.is_walkable(hall.door_cell()), "the doorstep is open")
	var left: Vector2i = hall.door_cell() + Vector2i(-12, -4)
	var right: Vector2i = hall.door_cell() + Vector2i(12, -4)
	var path: Array[Vector2i] = world.nav.find_path(left, right)
	assert_false(path.is_empty(), "there is a way round")
	for cell: Vector2i in path:
		assert_true(world.nav.is_walkable(cell))


func test_building_cannot_block_a_door() -> void:
	var plots: int = world.surface.farm_plots().size()
	game.wallet.earn(100)
	world.build_tool.start_place(FARM_PLOT)
	var doorstep: Vector2i = world.hall.tile + Vector2i(1, world.hall.def.footprint.y)
	world.input.click(_tile_point(doorstep))
	assert_eq(world.surface.farm_plots().size(), plots, "the row in front of a door stays clear")
	world.build_tool.cancel()


func test_moving_buildings_keeps_their_doors_working() -> void:
	var hall: GreatHall = world.hall
	world.build_tool.start_move()
	world.input.click(_tile_point(hall.tile))
	world.input.click(_tile_point(Vector2i(90, 2)))
	world.input.click(_tile_point(world.mine_entrance.tile))
	world.input.click(_tile_point(Vector2i(20, 4)))
	world.build_tool.cancel()
	assert_eq(hall.tile, Vector2i(90, 2))
	assert_eq(world.mine_entrance.tile, Vector2i(20, 4))
	var dwarf: Dwarf = _dwarf(0)
	assert_false(world.nav.find_path(dwarf.mover.cell, hall.storage_cell()).is_empty(),
		"dwarves can still walk into the moved hall")
	assert_false(world.nav.find_path(hall.storage_cell(), world.mine_level.landing_cell()).is_empty(),
		"and from there down the moved mine entrance")


func test_assignment_by_drop_and_views() -> void:
	var dwarf: Dwarf = _dwarf(0)
	var plot_point: Vector2 = _plot(0).global_position + Vector2(8, -8)
	assert_true(world.input.can_assign_at(plot_point))
	world.input.assign_at(dwarf, plot_point)
	assert_eq(dwarf.assignment.kind(), JobAssignment.Kind.FARMER)
	world.input.assign_at(dwarf, world.mine_entrance.global_position + Vector2(16, -8))
	assert_eq(dwarf.assignment.kind(), JobAssignment.Kind.MINER)
	assert_false(world.input.can_assign_at(_tile_point(Vector2i(5, 7))), "empty ground is not a job")

	# Inside a workplace, anywhere in the room will do: a stove, or the floor.
	game.wallet.earn(100)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	world.camera.show_interior(kitchen)
	var stove: Workstation = kitchen.workstations()[0]
	world.input.assign_at(dwarf, _room_point(kitchen.interior, stove.cell))
	assert_eq(dwarf.assignment.target, kitchen, "dropped on the stove, he cooks")
	world.input.assign_at(_dwarf(1), _room_point(kitchen.interior, Vector2i(0, 0)))
	assert_eq(_dwarf(1).assignment.target, kitchen, "dropped on the floor, he cooks too")
	world.camera.show_interior(world.hall)
	world.input.assign_at(dwarf, _room_point(world.hall.interior, Vector2i(0, 0)))
	assert_eq(dwarf.assignment.kind(), JobAssignment.Kind.NONE, "dropped in the hall, he's off duty")
	world.camera.show_surface()

	assert_eq(world.camera.current_view(), ViewCamera.View.SURFACE)
	world.input.click(world.mine_entrance.global_position + Vector2(16, -8))
	assert_eq(world.camera.current_view(), ViewCamera.View.MINE, "clicking the mine entrance opens the mine")
	world.camera.pan(Vector2(0, -5000))
	assert_eq(world.camera.current_view(), ViewCamera.View.MINE, "panning never leaves the mine")
	world.camera.show_surface()
	world.input.click(world.hall.global_position + Vector2(40, -40))
	assert_eq(world.camera.current_view(), ViewCamera.View.INTERIOR, "clicking a building goes inside")
	world.camera.show_surface()
	assert_eq(world.camera.current_view(), ViewCamera.View.SURFACE)


## A point in the middle of a hall floor cell (counted from the floor's corner).
func _hall_point(room_cell: Vector2i) -> Vector2:
	return Vector2((world.hall.interior.origin_cell() + room_cell) * NavGrid.CELL) + Vector2(4, 4)


func test_furniture_is_bought_moved_and_removed_in_the_hall() -> void:
	var room: BuildingInterior = world.hall.interior
	var tool: FurnitureTool = world.furniture_tool
	world.camera.show_interior(world.hall)
	game.wallet.earn(100)
	var coins: int = game.wallet.coins
	tool.start_place(LONG_TABLE)
	world.input.click(_hall_point(Vector2i(10, 7)))
	var table: Furniture = room.furniture_at(Vector2i(10, 7))
	assert_not_null(table, "placed")
	assert_eq(game.wallet.coins, coins - LONG_TABLE.cost)
	world.input.click(_hall_point(Vector2i(12, 7)))
	assert_eq(room.furniture().size(), 7, "can't stack on top of it")
	world.input.click(_hall_point(Vector2i(4, 1)))
	assert_eq(room.furniture().size(), 7, "the storage pile stays clear")

	tool.start_place(CHAIR)
	world.input.click(_hall_point(Vector2i(10, 6)))
	world.input.drag(_hall_point(Vector2i(11, 6)))
	assert_eq(room.seat_count(), 6, "click and drag places a row of chairs")
	assert_true(world.nav.is_walkable(room.origin_cell() + Vector2i(10, 6)), "chairs are sat on, not walked around")
	assert_false(world.nav.is_walkable(room.origin_cell() + Vector2i(10, 7)), "tables are walked around")

	tool.start_move()
	world.input.click(_hall_point(Vector2i(10, 7)))
	world.input.click(_hall_point(Vector2i(24, 1)))
	assert_eq(table.cell, Vector2i(24, 1), "moved")
	assert_true(world.nav.is_walkable(room.origin_cell() + Vector2i(10, 7)), "its old spot is floor again")

	tool.start_destroy()
	world.input.click(_hall_point(Vector2i(25, 1)))
	assert_null(room.furniture_at(Vector2i(24, 1)), "removed")
	tool.cancel()


func test_furniture_can_never_wall_off_the_floor() -> void:
	var room: BuildingInterior = world.hall.interior
	# A wall of long tables right across the room, leaving one gap.
	for x: int in [0, 4, 8, 12, 16, 20, 24]:
		assert_true(room.can_place(LONG_TABLE, Vector2i(x, 7)))
		room.place_furniture(LONG_TABLE, Vector2i(x, 7))
	assert_false(room.can_place(LONG_TABLE, Vector2i(26, 7)), "closing the last gap would trap the back of the room")
	assert_true(room.can_place(CHAIR, Vector2i(28, 7)), "a chair doesn't block anyone")


func test_dwarves_wait_for_a_free_chair() -> void:
	var room: BuildingInterior = world.hall.interior
	for piece: Furniture in room.furniture():
		if piece.def.is_seat:
			room.remove_furniture(piece)
	var dwarf: Dwarf = _dwarf(0)
	dwarf.hunger.fill(0.0)
	_run_seconds(60)
	assert_true(dwarf.meal_break.is_waiting_for_seat, "no chairs, no meal")
	assert_true(dwarf.hunger.is_empty())
	room.place_furniture(CHAIR, Vector2i(9, 4))
	_run_seconds(20)
	assert_false(dwarf.hunger.is_empty(), "sat down and ate once a chair appeared")


func test_the_hall_tab_replaces_the_usual_tabs_inside_the_hall() -> void:
	var farm_button: Button = game.hud.get_node("Root/Layout/SidePanel/Row/TabColumn/Tabs/FarmButton")
	var hall_button: Button = game.hud.get_node("Root/Layout/SidePanel/Row/TabColumn/Tabs/RoomButton")
	var pages: TabContainer = game.hud.get_node("Root/Layout/SidePanel/Row/Pages")
	assert_true(farm_button.visible)
	assert_false(hall_button.visible)
	world.camera.show_interior(world.hall)
	assert_false(farm_button.visible, "the farming tab hides in the hall")
	assert_true(hall_button.visible)
	assert_eq(pages.get_current_tab_control().name, &"Room")
	world.camera.show_surface()
	assert_true(farm_button.visible, "and comes back outside")
	assert_eq(pages.get_current_tab_control().name, &"Farming")


func test_furniture_turns() -> void:
	var room: BuildingInterior = world.hall.interior
	var tool: FurnitureTool = world.furniture_tool
	world.camera.show_interior(world.hall)
	game.wallet.earn(100)
	tool.start_place(LONG_TABLE)
	tool.turn_held_piece()
	world.input.click(_hall_point(Vector2i(24, 2)))
	var table: Furniture = room.furniture_at(Vector2i(24, 2))
	assert_not_null(table)
	assert_eq(table.rect().size, Vector2i(2, 4), "a turned long table runs the other way")

	tool.start_turn()
	world.input.click(_hall_point(Vector2i(24, 2)))
	assert_eq(table.facing, 2)
	assert_eq(table.rect().size, Vector2i(4, 2), "and back again")

	var chair: Furniture = room.furniture_at(Vector2i(9, 4))
	assert_eq(chair.facing, 3, "starting chairs face their tables")
	world.input.click(_hall_point(Vector2i(9, 4)))
	assert_eq(chair.facing, 0, "a chair turns in place")

	tool.start_move()
	world.input.click(_hall_point(Vector2i(9, 4)))
	tool.turn_held_piece()
	world.input.click(_hall_point(Vector2i(9, 6)))
	assert_eq(chair.cell, Vector2i(9, 6))
	assert_eq(chair.facing, 1, "picked up facing its way, turned once more while carried")

	var by_the_wall: Furniture = room.place_furniture(LONG_TABLE, Vector2i(0, 8))
	assert_false(room.turn_furniture(by_the_wall), "won't turn where the turned piece doesn't fit")
	assert_eq(by_the_wall.facing, 0)
	tool.cancel()



func _room_point(room: BuildingInterior, room_cell: Vector2i) -> Vector2:
	return Vector2((room.origin_cell() + room_cell) * NavGrid.CELL) + Vector2(4, 4)


func test_kitchen_stoves_are_placed_turned_and_worked_from_the_front() -> void:
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var room: BuildingInterior = kitchen.interior
	var tool: FurnitureTool = world.furniture_tool
	world.camera.show_interior(kitchen)
	game.wallet.earn(200)
	var coins: int = game.wallet.coins

	tool.start_place(STOVE)
	world.input.click(_room_point(room, Vector2i(2, 2)))
	assert_eq(kitchen.workstations().size(), 2, "a second stove")
	assert_eq(game.wallet.coins, coins - STOVE.cost)
	var second: Workstation = room.furniture_at(Vector2i(2, 2)) as Workstation
	assert_eq(second.work_cell(), room.origin_cell() + Vector2i(2, 4), "worked from the cell below it")

	tool.start_place(CHAIR)
	world.input.click(_room_point(room, Vector2i(2, 4)))
	assert_null(room.furniture_at(Vector2i(2, 4)), "nothing may stand where the cook stands")

	tool.start_turn()
	world.input.click(_room_point(room, Vector2i(2, 2)))
	assert_eq(second.facing, 1)
	assert_eq(second.work_cell(), room.origin_cell() + Vector2i(1, 2), "turned, it's worked from the side")

	tool.start_place(STOVE)
	assert_false(room.can_place(STOVE, Vector2i(5, 6)), "a stove can't face the wall")
	tool.cancel()

	_nobody_gets_hungry()
	storage.add(POTATO, 4)
	_dwarf(0).assignment.assign(kitchen)
	_run_seconds(STEW_RECIPE.process_seconds + 120)
	assert_eq(storage.count(STEW), 2, "both stoves cooked, turned or not")


func test_room_tab_follows_the_building() -> void:
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var tools: GridContainer = game.hud.get_node("Root/Layout/SidePanel/Row/Pages/Room/Column/Tools")
	world.camera.show_interior(kitchen)
	var tips: Array[String] = []
	for slot: Node in tools.get_children():
		tips.append((slot as IconSlot).tooltip_text)
	assert_has(tips, "Stove", "the kitchen sells stoves")
	assert_does_not_have(tips, "Chair", "but not hall furniture")
	world.camera.show_interior(world.hall)
	tips.clear()
	for slot: Node in tools.get_children():
		if not slot.is_queued_for_deletion():
			tips.append((slot as IconSlot).tooltip_text)
	assert_has(tips, "Chair")
	assert_does_not_have(tips, "Stove")


func _click_station(station: Workstation) -> void:
	world.input.click(station.global_position + Vector2(8, 8))


func test_the_players_pick_starts_only_when_they_click_and_the_hall_has_it() -> void:
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	world.camera.show_interior(kitchen)
	assert_eq(storage.count(POTATO), 0)
	var slot: RecipeSlot = add_child_autofree((load("res://ui/recipe_slot.tscn") as PackedScene).instantiate()) as RecipeSlot
	slot.setup(GRUEL_RECIPE)
	slot.refresh(stove, storage)
	assert_false(slot.disabled, "no potatoes yet, but gruel can still be picked")
	assert_eq((slot.get_node("Margin/Row/In1Count") as Label).modulate, RecipeSlot.SHORT_COLOR, "the missing potato shows in red")
	stove.player_recipe = GRUEL_RECIPE
	slot.refresh(stove, storage)
	assert_true(slot.button_pressed, "the player's pick shows pressed")
	assert_true(stove.is_idle(), "picking alone starts nothing")
	assert_eq(stove.status_text(), "empty, click to make Gruel")
	_click_station(stove)
	assert_true(stove.is_idle(), "no potatoes: the click can't start it")
	storage.add(POTATO, 1)
	slot.refresh(stove, storage)
	assert_eq((slot.get_node("Margin/Row/In1Count") as Label).modulate, Color.WHITE)
	_click_station(stove)
	assert_eq(stove.recipe, GRUEL_RECIPE, "now a click starts the player's gruel")
	assert_string_contains(stove.status_text(), "click to load")


func test_cancelling_a_batch_puts_what_went_in_back() -> void:
	storage.add(POTATO, 2)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	var cancel: Button = game.hud.get_node("Root/Layout/SidePanel/Row/Pages/Room/Column/Station/CancelButton")
	world.camera.show_interior(kitchen)
	stove.player_recipe = STEW_RECIPE
	_click_station(stove)
	assert_true(cancel.visible, "a batch on: it can be cancelled")
	while stove.needs_loading():
		_click_station(stove)
	assert_eq(stove.state, Workstation.State.PROCESSING)
	assert_eq(storage.count(POTATO), 0, "cooking: the potatoes are in the pot")
	cancel.pressed.emit()
	assert_true(stove.is_idle(), "cancelled")
	assert_null(stove.recipe)
	assert_eq(storage.count(POTATO), 2, "and the potatoes are back in the hall")
	assert_false(cancel.visible, "nothing left to cancel")
	assert_false(stove.cancel_batch())


func test_player_cooks_by_picking_a_recipe_and_clicking() -> void:
	storage.add(POTATO, 2)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	world.camera.show_interior(kitchen)
	_click_station(stove)
	assert_eq(world.hand.selected_station, stove, "clicking a station selects it")
	assert_true(stove.is_idle(), "nothing happens until a recipe is picked")

	stove.player_recipe = STEW_RECIPE
	_click_station(stove)
	assert_eq(stove.recipe, STEW_RECIPE, "a click on the free stove starts the player's pick")
	assert_gt(stove.receiver.progress, 0.0, "each click fills the bar a little")
	assert_eq(storage.count(POTATO), 2, "ingredients stay in the hall until the bar is full")
	var clicks: int = 1
	while stove.needs_loading() and clicks < 100:
		_click_station(stove)
		clicks += 1
	assert_eq(clicks, ceili(STEW_RECIPE.load_work / game.tuning.manual_work_per_click))
	assert_eq(stove.state, Workstation.State.PROCESSING, "full bar: cooking on its own")
	assert_eq(storage.count(POTATO), 0, "and now the potatoes are used")

	_run_seconds(STEW_RECIPE.process_seconds + 1)
	assert_true(stove.has_output())
	var stew_before: int = storage.count(STEW)
	_click_station(stove)
	assert_eq(world.hand.carrier.item, STEW, "the stew is in the player's hands")
	assert_true(stove.is_idle(), "the stove is free again")
	world.camera.show_surface()
	world.input.click(world.hall.global_position + Vector2(40, -40))
	assert_eq(storage.count(STEW), stew_before + 1, "dropped off at the hall")


func test_player_pours_mash_from_pot_to_fermenter() -> void:
	game.wallet.earn(500)
	game.shop.unlock_building(BREWERY)
	storage.add(POTATO, 2)
	var brewery: Building = world.surface.build(BREWERY, Vector2i(40, 1)) as Building
	var pot: Workstation = brewery.workstations()[0]
	var fermenter: Workstation = brewery.workstations()[1]
	world.camera.show_interior(brewery)
	pot.player_recipe = POTATO_MASH_RECIPE
	_click_station(pot)
	while pot.needs_loading():
		_click_station(pot)
	_run_seconds(POTATO_MASH_RECIPE.process_seconds + 1)
	assert_true(pot.has_output(), "potato mash is ready")

	_click_station(fermenter)
	assert_eq(world.hand.pour_target, fermenter, "an empty fermenter asks for a mash pot")
	_click_station(pot)
	assert_null(world.hand.pour_target)
	assert_false(pot.has_output(), "the mash left the pot")
	assert_true(fermenter.is_holding_input(), "and is in the fermenter")
	assert_eq(fermenter.recipe, GROG_RECIPE, "potato mash brews grog")
	assert_true(fermenter.needs_loading(), "pouring still takes work")

	while fermenter.needs_loading():
		_click_station(fermenter)
	assert_eq(fermenter.state, Workstation.State.PROCESSING)
	_run_seconds(GROG_RECIPE.process_seconds + 1)
	_click_station(fermenter)
	assert_eq(world.hand.carrier.count, GROG_RECIPE.output_count, "one mash, four grogs")


func test_gruel_and_grog_both_come_from_potatoes() -> void:
	assert_eq(GRUEL_RECIPE.inputs[0].item, POTATO)
	assert_eq(POTATO_MASH_RECIPE.inputs[0].item, POTATO)
	assert_eq(GROG_RECIPE.inputs[0].item, POTATO_MASH)


func test_ledger_counts_harvests_meals_and_ore() -> void:
	var plot: FarmPlot = _plot(0)
	plot.sow(POTATO_CROP)
	while not plot.is_ripe():
		plot.water()
		_run_seconds(5)
	world.hand.select(PlayerHand.Tool.SHEARS)
	_click_plot(plot)
	assert_eq(world.ledger.count(Ledger.HARVESTED), POTATO_CROP.yield_count)
	assert_eq(world.ledger.count(&"harvested:potato"), POTATO_CROP.yield_count)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	storage.add(POTATO, 1)
	stove.start_batch(GRUEL_RECIPE)
	stove.receiver.apply_work(100.0)
	_run_seconds(GRUEL_RECIPE.process_seconds + 1)
	assert_eq(world.ledger.count(Ledger.MEALS_MADE), 1)
	assert_eq(world.ledger.count(&"made:gruel"), 1)


func test_carrots_unlock_by_harvesting_then_trading_coins() -> void:
	var unlocks: Unlocks = game.unlocks
	assert_true(unlocks.is_unlocked(POTATO_CROP), "potatoes are open from the start")
	assert_false(unlocks.is_unlocked(CARROT_CROP))
	assert_false(unlocks.can_trade(CARROT_CROP), "milestone not met yet")
	world.ledger.record_harvest(POTATO, 12)
	assert_eq(unlocks.progress(CARROT_CROP), 12)
	world.ledger.record_harvest(BARLEY, 8)
	assert_true(unlocks.milestone_met(CARROT_CROP), "any crops count towards it")
	var coins: int = game.wallet.coins
	assert_true(unlocks.trade(CARROT_CROP))
	assert_eq(game.wallet.coins, coins - CARROT_CROP.unlock.coins)
	assert_true(unlocks.is_unlocked(CARROT_CROP))
	assert_false(unlocks.trade(CARROT_CROP), "only bought once")


func test_onion_soup_takes_two_trips_and_appears_with_onions() -> void:
	assert_false(game.unlocks.recipe_available(ONION_SOUP_RECIPE, game.catalog), "no onions, no onion soup")
	world.ledger.record_made(STEW, 15)
	assert_true(game.unlocks.trade(ONION_CROP))
	assert_true(game.unlocks.recipe_available(ONION_SOUP_RECIPE, game.catalog))

	_nobody_gets_hungry()
	storage.add(ONION, 1)
	storage.add(POTATO, 2)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	var cook: Dwarf = _dwarf(0)
	cook.assignment.assign(kitchen)
	var carried: Array[ItemDef] = []
	for i: int in 3000:  # Two round trips to the hall take a while.
		game.clock.advance(1)
		if not cook.carrier.is_empty() and not carried.has(cook.carrier.item):
			carried.append(cook.carrier.item)
		if stove.state == Workstation.State.PROCESSING:
			break
	assert_eq(stove.recipe, ONION_SOUP_RECIPE, "with an onion in, onion soup is the best he can make")
	assert_eq(stove.state, Workstation.State.PROCESSING, "the cook stocked it and worked the bar")
	assert_has(carried, ONION, "one trip for the onion")
	assert_has(carried, POTATO, "another for the potatoes")
	_run_seconds(ONION_SOUP_RECIPE.process_seconds + 60)
	assert_eq(storage.count(ONION_SOUP), 1)


func test_removing_a_station_returns_what_was_in_it() -> void:
	storage.add(POTATO, 2)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	stove.start_batch(STEW_RECIPE)
	var carrier: Carrier = world.hand.carrier
	carrier.add(POTATO, 2)
	storage.remove(POTATO, 2)
	assert_true(stove.deposit(carrier))
	kitchen.interior.remove_furniture(stove)
	assert_eq(storage.count(POTATO), 2, "the potatoes went back to the hall")


func test_brewing_crops_unlock_from_drinks_and_brew_new_drinks() -> void:
	var wheat_crop: CropDef = load("res://data/crops/wheat.tres")
	var radish_crop: CropDef = load("res://data/crops/radish.tres")
	assert_true(game.unlocks.is_unlocked(POTATO_CROP), "potatoes from the start")
	for crop: CropDef in [BARLEY_CROP, wheat_crop, radish_crop]:
		assert_false(game.unlocks.is_unlocked(crop), "%s waits for the brewery" % crop.display_name)
	assert_false(game.unlocks.recipe_available(BARLEY_MASH_RECIPE, game.catalog), "no barley mash without barley")
	game.wallet.earn(200)
	world.ledger.record_made(GROG, 4)
	assert_true(game.unlocks.trade(BARLEY_CROP), "barley after the first batch of grog")
	assert_true(game.unlocks.recipe_available(BARLEY_MASH_RECIPE, game.catalog))
	world.ledger.record_made(ALE, 6)
	assert_true(game.unlocks.trade(wheat_crop), "wheat after 10 drinks")
	assert_false(game.unlocks.can_trade(radish_crop), "radishes take more")
	world.ledger.record_made(ALE, 10)
	assert_true(game.unlocks.trade(radish_crop), "radishes after 20 drinks")

	var fermenter_def: WorkstationDef = FERMENTER
	var outputs: Array[String] = []
	for r: RecipeDef in fermenter_def.recipes:
		outputs.append(r.output.display_name)
	assert_has(outputs, "Wheat beer")
	assert_has(outputs, "Radish spirit")
	var beer: DrinkDef = load("res://data/items/wheat_beer.tres")
	var spirit: DrinkDef = load("res://data/items/radish_spirit.tres")
	assert_gt(beer.duration_seconds, ALE.duration_seconds, "wheat beer: long and steady")
	assert_gt(spirit.high_multiplier, ALE.high_multiplier, "radish spirit: a sharp kick")
	assert_lt(spirit.duration_seconds, ALE.duration_seconds, "but short")


func test_smeltery_and_forge_unlock_with_ore_and_ingots() -> void:
	var smeltery: BuildingDef = load("res://data/buildings/smeltery.tres")
	var forge: BuildingDef = load("res://data/buildings/forge.tres")
	var ingot: ItemDef = load("res://data/items/copper_ingot.tres")
	game.wallet.earn(500)
	world.ledger.record_mined(COPPER, 15)
	assert_false(game.unlocks.can_trade(smeltery), "the trade wants copper ore too")
	storage.add(COPPER, 5)
	assert_true(game.unlocks.trade(smeltery))
	assert_eq(storage.count(COPPER), 0, "the ore was traded away")
	world.ledger.record_made(ingot, 5)
	storage.add(ingot, 3)
	assert_true(game.unlocks.trade(forge))
	assert_eq(storage.count(ingot), 0)


func test_ore_becomes_ingots_becomes_a_pick_that_speeds_up_a_miner() -> void:
	var smeltery_def: BuildingDef = load("res://data/buildings/smeltery.tres")
	var forge_def: BuildingDef = load("res://data/buildings/forge.tres")
	var ingot: ItemDef = load("res://data/items/copper_ingot.tres")
	var pick: ToolDef = load("res://data/items/copper_pick.tres")
	_nobody_gets_hungry()
	storage.add(COPPER, 6)
	var smeltery: Building = world.surface.build(smeltery_def, Vector2i(40, 1)) as Building
	var forge: Building = world.surface.build(forge_def, Vector2i(44, 1)) as Building
	var smelter: Workstation = smeltery.workstations()[0]
	var anvil: Workstation = forge.workstations()[0]
	_dwarf(0).assignment.assign(smeltery)
	var smith: Dwarf = _dwarf(1)
	smith.assignment.assign(forge)
	_run_seconds(600)
	assert_eq(world.ledger.count(&"made:copper_ingot"), 2, "six ore smelted into two ingots")
	assert_true(anvil.is_idle(), "no miner lacks a pick, so nothing is forged")
	assert_eq(smith.status_text(), "Nothing needed")

	var miner: Dwarf = _dwarf(2)
	miner.assignment.assign(world.mine_entrance)
	_run_seconds(1)
	var bare_rate: float = miner.worker.rate()
	_run_seconds(400)
	assert_eq(world.ledger.count(&"made:copper_pick"), 1, "a miner without a pick: the smith forges one, and only one")
	miner.equip_best_tool(storage)
	assert_eq(miner.tool, pick, "a miner at the hall takes the pick")
	assert_eq(storage.count(pick), 0)
	_run_seconds(1)
	assert_almost_eq(miner.worker.rate(), bare_rate * pick.work_multiplier, 0.001, "and digs faster with it")

	var farmer: Dwarf = _dwarf(3)
	farmer.assignment.assign(_plot(0))
	storage.add(pick, 1)
	farmer.equip_best_tool(storage)
	assert_null(farmer.tool, "a pick is no use to a farmer")


func test_a_reassigned_dwarf_swaps_tools_before_anything_else() -> void:
	var sickle: ToolDef = load("res://data/items/copper_sickle.tres")
	var pick: ToolDef = load("res://data/items/copper_pick.tres")
	_nobody_gets_hungry()
	var dwarf: Dwarf = _dwarf(0)
	dwarf.assignment.assign(_plot(0))
	storage.add(sickle, 1)
	dwarf.equip_best_tool(storage)
	assert_eq(dwarf.tool, sickle, "a farmer with his sickle")
	storage.add(pick, 1)

	dwarf.assignment.assign(world.mine_entrance)
	_run_seconds(0.1)
	assert_eq(dwarf.status_text(), "Swapping tools", "first job as a miner: go and swap tools")
	_run_seconds(60)
	assert_eq(dwarf.tool, pick, "he took the pick")
	assert_eq(storage.count(sickle), 1, "and left the sickle for a farmer")
	assert_eq(dwarf.status_text(), "Miner", "then off to the mine")

	dwarf.assignment.assign(null)
	_run_seconds(60)
	assert_null(dwarf.tool, "made idle, he puts his pick away too")
	assert_eq(storage.count(pick), 1)


func test_hovering_a_dwarf_points_him_out_and_shows_his_card() -> void:
	var dwarf: Dwarf = _dwarf(1)
	dwarf.mover.place_at(world.hall.door_cell() + Vector2i(6, 2))
	_run_seconds(0.1)
	await wait_process_frames(2)
	var spot: Vector2 = dwarf.global_position + Vector2(0, -8)
	world.input.hover(spot)
	assert_eq(world.dwarves.hovered, dwarf, "found under the cursor")
	var card: DwarfCard = game.hud.get_node("Root/DwarfCard")
	assert_true(card.visible, "his card shows")
	await wait_process_frames(2)
	assert_eq((card.get_node("Column/Name") as Label).text, dwarf.dwarf_name)
	assert_true((dwarf.get_node("Visual/Marker") as Sprite2D).visible, "an arrow over his head")
	world.input.hover(spot + Vector2(200, 0))
	assert_null(world.dwarves.hovered)
	assert_false(card.visible)

	world.hand.select(PlayerHand.Tool.LOOK)
	world.input.hover(spot)
	assert_true(card.visible, "with the Look tool too, he gets his own card")
	assert_null(world.hand.looked_at, "so the Look pop-up stays out of the way")


func test_clicking_a_roster_entry_jumps_to_the_dwarf() -> void:
	var miner: Dwarf = _dwarf(0)
	miner.mover.place_at(world.mine_level.landing_cell())
	_run_seconds(0.1)
	world.camera.show_dwarf(miner)
	assert_eq(world.camera.current_view(), ViewCamera.View.MINE, "he's in the mine, so the mine view")
	assert_lt(world.camera.position.distance_to(miner.mover.position), 200.0, "centred on him (as far as the edges allow)")

	var cook: Dwarf = _dwarf(1)
	cook.mover.place_at(world.hall.storage_cell())
	world.camera.show_dwarf(cook)
	assert_eq(world.camera.interior_building, world.hall, "he's in the hall, so the hall opens")

	var farmer: Dwarf = _dwarf(2)
	farmer.mover.place_at(_plot(0).work_cell())
	_run_seconds(0.1)
	world.camera.show_dwarf(farmer)
	assert_eq(world.camera.current_view(), ViewCamera.View.SURFACE)


func test_follow_mode_sticks_to_a_dwarf_across_views() -> void:
	var dwarf: Dwarf = _dwarf(0)
	_nobody_gets_hungry()
	world.camera.set_follow(true)
	world.camera.show_dwarf(dwarf)
	dwarf.assignment.assign(world.mine_entrance)
	var went_down: bool = false
	for i: int in 200:
		_run_seconds(1)
		await wait_process_frames(1)
		if world.camera.current_view() == ViewCamera.View.MINE:
			went_down = true
			break
	assert_true(went_down, "the camera followed him down into the mine")
	assert_lt(world.camera.position.distance_to(dwarf.position), 200.0, "keeping him in view")
	world.camera.set_follow(false)
	world.camera.show_surface()
	await wait_process_frames(2)
	assert_eq(world.camera.current_view(), ViewCamera.View.SURFACE, "follow off: the camera stays put")


func _cells_apart(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func test_a_dwarf_with_no_job_potters_outside_the_hall_with_a_question_mark() -> void:
	var dwarf: Dwarf = _dwarf(0)
	_run_seconds(30)
	assert_true(world.surface.contains_cell(dwarf.mover.cell), "out in town, not shut in the hall")
	assert_lte(_cells_apart(dwarf.mover.cell, world.hall.door_cell()), 8, "near the hall")
	assert_eq(dwarf.status_text(), "No job", "his card says why")
	assert_eq(dwarf.job_badge(), "?")
	await wait_process_frames(2)
	assert_true((dwarf.get_node("Visual/IdleMark") as Sprite2D).visible, "a ? over his head")
	var visited: Dictionary[Vector2i, bool] = {}
	for i: int in 30:
		_run_seconds(1)
		visited[dwarf.mover.cell] = true
	assert_gt(visited.size(), 2, "pottering about, not standing still")
	dwarf.assignment.assign(_plot(0))
	_plot(0).sow(POTATO_CROP)
	_run_seconds(1)
	assert_false(dwarf.idler.is_idle(), "given work, he gets to it")
	await wait_process_frames(2)
	assert_false((dwarf.get_node("Visual/IdleMark") as Sprite2D).visible)


func test_cooks_with_nothing_to_cook_wait_in_their_kitchen() -> void:
	_nobody_gets_hungry()
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	var cook: Dwarf = _dwarf(0)
	cook.assignment.assign(kitchen)
	_run_seconds(40)
	assert_eq(cook.status_text(), "Missing ingredients", "nothing in the hall he can cook")
	assert_eq(world.interiors.room_at(cook.mover.cell), kitchen.interior, "he stays in, so you can see he's the cook")
	storage.add(POTATO, 2)
	_run_seconds(60)
	assert_false(cook.idler.is_idle(), "potatoes in: he picks a meal and gets to it")
	assert_ne(stove.state, Workstation.State.IDLE)


func test_a_miner_with_nowhere_to_dig_waits_by_the_mine_entrance() -> void:
	# Other miners have every tunnel end, and the shaft is too short for a new one.
	var excavation: Excavation = world.mine_level.excavation
	while excavation.claim_head(autofree(Node.new()), world.mine_level.landing_cell()) != null:
		pass
	var miner: Dwarf = _dwarf(0)
	miner.assignment.assign(world.mine_entrance)
	_run_seconds(40)
	assert_eq(miner.status_text(), "No tunnel to dig")
	assert_true(world.surface.contains_cell(miner.mover.cell), "up in town")
	assert_lte(_cells_apart(miner.mover.cell, world.mine_entrance.door_cell()), 8, "by the mine entrance")


func test_spare_miners_dig_the_shaft_deeper_and_branch_off_it() -> void:
	storage.add(STEW, 50)
	var landing: Vector2i = world.mine_level.landing_cell()
	assert_lt(landing.y, 8, "the shaft starts short, in the dirt")
	for dwarf: Dwarf in world.dwarves.active():
		dwarf.assignment.assign(world.mine_entrance)
	_run_seconds(300)
	assert_gt(world.shaft.bottom_cell().y, landing.y, "miners dug the shaft deeper")
	var tunnels_off_the_shaft: int = 0
	for side: int in [-1, 1]:
		for y: int in range(landing.y + 2, world.shaft.bottom_cell().y + 1):
			if world.terrain.is_open(Vector2i(world.shaft.column + side, y)):
				tunnels_off_the_shaft += 1
				break
	assert_gt(tunnels_off_the_shaft, 0, "and opened new tunnels off its side")


func _mouse(area: WorldArea, button: MouseButton) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = button
	press.pressed = true
	area._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = button
	area._gui_input(release)


func test_right_click_puts_tools_away_and_the_wheel_turns_a_held_piece() -> void:
	var area: WorldArea = game.hud.get_node("Root/WorldArea") as WorldArea
	var tool: FurnitureTool = world.furniture_tool
	world.camera.show_interior(world.hall)
	tool.start_place(LONG_TABLE)
	_mouse(area, MOUSE_BUTTON_WHEEL_DOWN)
	assert_eq(tool.facing, 1, "one wheel notch, one quarter turn")
	_mouse(area, MOUSE_BUTTON_RIGHT)
	assert_false(tool.is_active(), "right-click puts the piece away")
	world.camera.show_surface()
	world.build_tool.start_place(FARM_PLOT)
	_mouse(area, MOUSE_BUTTON_RIGHT)
	assert_false(world.build_tool.is_active(), "and the build tool")
	world.hand.select(PlayerHand.Tool.BUCKET)
	_mouse(area, MOUSE_BUTTON_RIGHT)
	assert_false(world.hand.is_holding_tool(), "and a farming tool")
