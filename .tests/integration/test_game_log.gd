extends GutTest
## The game log writes a readable record of a session: the tuning up top,
## events stamped with game time, a summary each game minute, and totals
## when the game closes.

const GAME_SCENE: PackedScene = preload("res://game/game.tscn")
const POTATO_CROP: CropDef = preload("res://data/crops/potato.tres")
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
	_run_seconds(150)
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


func test_closing_the_game_writes_the_totals() -> void:
	game.game_log.start(TEST_DIR)
	var path: String = game.game_log.file_path()
	game.wallet.earn(1000)
	assert_true(game.shop.hire())
	_run_seconds(5)
	remove_child(game)
	var text: String = FileAccess.get_file_as_string(path)
	assert_string_contains(text, "Hired ")
	assert_string_contains(text, "== End of game, 0:00:05 ==")
	assert_string_contains(text, "Coins ")


func test_old_logs_are_trimmed() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	for i: int in 5:
		FileAccess.open(TEST_DIR.path_join("game_2000-01-0%d.log" % (i + 1)), FileAccess.WRITE).close()
	game.game_log.max_files = 3
	game.game_log.start(TEST_DIR)
	var logs: PackedStringArray = DirAccess.get_files_at(TEST_DIR)
	assert_eq(logs.size(), 3, "the newest two old ones, plus this one")
	assert_false(logs.has("game_2000-01-01.log"), "oldest first")
