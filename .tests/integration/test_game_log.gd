extends GutTest
## The game log writes a readable record of a session: the tuning up top,
## events stamped with game time, a summary each game minute, and totals
## when the game closes.

const GAME_SCENE: PackedScene = preload("res://game/game.tscn")
const POTATO_CROP: CropDef = preload("res://data/crops/potato.tres")
const GRUEL: MealDef = preload("res://data/items/gruel.tres")
const GROG: DrinkDef = preload("res://data/items/grog.tres")
const POTATO: ItemDef = preload("res://data/items/potato.tres")
const KITCHEN: BuildingDef = preload("res://data/buildings/kitchen.tres")
const GRUEL_RECIPE: RecipeDef = preload("res://data/recipes/gruel.tres")
const TEST_DIR: String = "user://test_logs"

var game: Game


func before_each() -> void:
	_clear_test_logs()
	game = add_child_autofree(GAME_SCENE.instantiate())
	game.clock.set_process(false)


func after_each() -> void:
	await wait_physics_frames(2)
	_clear_test_logs()


func _clear_test_logs() -> void:
	if DirAccess.dir_exists_absolute(TEST_DIR):
		for file_name: String in DirAccess.get_files_at(TEST_DIR):
			DirAccess.remove_absolute(TEST_DIR.path_join(file_name))


func _run_seconds(seconds: float) -> void:
	game.clock.advance(roundi(seconds / game.clock.tick_seconds))


func _log_text() -> String:
	return FileAccess.get_file_as_string(game.game_log.file_path())


func test_a_game_made_by_a_test_keeps_no_log_unless_asked() -> void:
	assert_false(game.game_log.is_logging(), "only the main scene logs by itself")
	game.game_log.start(TEST_DIR)
	assert_true(game.game_log.is_logging())
	assert_true(game.game_log.file_path().get_file().begins_with(GameLog.FILE_PREFIX))


func test_the_log_reads_like_a_session() -> void:
	game.game_log.start(TEST_DIR)
	var farmer: Dwarf = game.world.dwarves.active()[0]
	var plot: FarmPlot = game.world.surface.farm_plots()[0]
	plot.sow(POTATO_CROP)
	farmer.assignment.assign(plot)
	# A plant can roll up to grow_spread longer, and the farmer has two waterings to walk to.
	_run_seconds(POTATO_CROP.grow_seconds * (1.0 + POTATO_CROP.grow_spread) + 120.0)
	var text: String = _log_text()
	assert_string_contains(text, "== Tuning ==")
	assert_string_contains(text, "grow_seconds=", "crop numbers are in the header")
	assert_string_contains(text, "process_seconds=", "and recipe numbers")
	assert_string_contains(text, "First harvested: Potato")
	assert_string_contains(text, "%s: Farmer" % farmer.dwarf_name, "jobs given are noted")
	assert_string_contains(text, "idle: No job", "and dwarves going idle, with why")
	assert_string_contains(text, "-- 0:01:00, minute 1 (", "a summary each game minute, with the clock time")
	assert_string_contains(text, "sowed 1 Potato", "the player's sowing")
	assert_string_contains(text, "Plots (9):")
	assert_string_contains(text, "  %s (Farmer): " % farmer.dwarf_name, "each dwarf's minute")


func test_a_station_says_whether_it_waits_on_the_farm_or_on_workers() -> void:
	game.game_log.start(TEST_DIR)
	var kitchen: Building = game.world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	_run_seconds(60)
	game.world.hall.storage.add(POTATO, GRUEL_RECIPE.needs(POTATO))
	_run_seconds(60)
	game.world.dwarves.active()[0].assignment.assign(kitchen)
	_run_seconds(60)
	var minutes: PackedStringArray = _log_text().split("-- 0:0")
	assert_string_contains(minutes[1], "Kitchen Stove: no ingredients 100%", "no potatoes: waiting on the farm")
	assert_string_contains(minutes[2], "Kitchen Stove: unattended 100%", "a potato but no cook: waiting on workers")
	assert_string_contains(minutes[3], "loading", "a cook on it")


func test_closing_the_game_writes_the_totals() -> void:
	game.game_log.start(TEST_DIR)
	var path: String = game.game_log.file_path()
	game.wallet.earn(1000)
	assert_true(game.shop.hire())
	var dwarf: Dwarf = game.world.dwarves.active()[0]
	dwarf.hunger.eat(GRUEL)
	_run_seconds(2)
	dwarf.hunger.eat(GRUEL)
	dwarf.thirst.drink_up(GROG)
	_run_seconds(3)
	remove_child(game)
	var text: String = FileAccess.get_file_as_string(path)
	assert_string_contains(text, "Hired ")
	assert_string_contains(text, "== End of game, 0:00:05 ==")
	assert_string_contains(text, "Coins ")
	assert_string_contains(text, "Eaten and drunk: 2 Gruel, 1 Grog", "what was eaten and drunk")
	assert_string_contains(text, "2 meals, one every 0:00:02", "and how often each dwarf eats")


func test_old_logs_are_trimmed() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	for i: int in 5:
		FileAccess.open(TEST_DIR.path_join("game_2000-01-0%d.log" % (i + 1)), FileAccess.WRITE).close()
	game.game_log.max_files = 3
	game.game_log.start(TEST_DIR)
	var logs: PackedStringArray = DirAccess.get_files_at(TEST_DIR)
	assert_eq(logs.size(), 3, "the newest two old ones, plus this one")
	assert_false(logs.has("game_2000-01-01.log"), "oldest first")
