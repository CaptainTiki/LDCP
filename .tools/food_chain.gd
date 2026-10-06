extends SceneTree
## Dev tool: runs the real game headless with a steady player (every empty
## plot is resown with potatoes at once) and prints the food chain: how fast
## potatoes grow, how fast the kitchen cooks them, how fast the dwarves eat,
## and so how many dwarves a plot and a stove can feed. Re-run it after
## changing grow times, recipes or meal lengths.
##
## The crew: 1 farmer, 1 cook (one stove), 2 miners, on the 9 starting plots.
## Food is counted in work-seconds: a meal's shift_seconds, the work it lasts.
##
## Usage: godot --headless --path . -s .tools/food_chain.gd [-- <game minutes>]

const GAME_SCENE: String = "res://game/game.tscn"
const POTATO_CROP: String = "res://data/crops/potato.tres"
const KITCHEN: String = "res://data/buildings/kitchen.tres"

var _game: Game
var _eaten: Dictionary[Dwarf, float] = {}
var _meals_eaten: Dictionary[String, int] = {}
var _work_ticks: Dictionary[Dwarf, int] = {}
var _hungry_ticks: Dictionary[Dwarf, int] = {}
var _stove_ticks: Dictionary[String, int] = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var minutes: int = 90
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		minutes = args[0].to_int()
	_game = (load(GAME_SCENE) as PackedScene).instantiate() as Game
	root.add_child(_game)
	_game.clock.set_process(false)
	var world: World = _game.world
	var potato: CropDef = load(POTATO_CROP)
	var kitchen: Building = world.surface.build(load(KITCHEN) as BuildingDef, Vector2i(40, 1)) as Building
	var stove: Workstation = kitchen.workstations()[0]
	var crew: Array[Dwarf] = world.dwarves.active()
	crew[0].assignment.assign(world.surface.farm_plots()[0])
	crew[1].assignment.assign(kitchen)
	crew[2].assignment.assign(world.mine_entrance)
	crew[3].assignment.assign(world.mine_entrance)
	for dwarf: Dwarf in crew:
		_eaten[dwarf] = 0.0
		_work_ticks[dwarf] = 0
		_hungry_ticks[dwarf] = 0
		dwarf.hunger.ate.connect(_on_ate.bind(dwarf))

	var ticks_per_minute: int = roundi(60.0 / _game.clock.tick_seconds)
	var first_harvest_minute: float = -1.0
	for tick: int in minutes * ticks_per_minute:
		if tick % 10 == 0:
			for plot: FarmPlot in world.surface.farm_plots():
				if not plot.is_planted():
					plot.sow(potato)
		_game.clock.advance(1)
		for dwarf: Dwarf in crew:
			if dwarf.worker.did_work_this_tick():
				_work_ticks[dwarf] += 1
			if dwarf.meal_break.is_waiting_for_food:
				_hungry_ticks[dwarf] += 1
		var state: String = Workstation.State.keys()[stove.state]
		_stove_ticks[state] = _stove_ticks.get(state, 0) + 1
		if first_harvest_minute < 0.0 and world.ledger.count(&"harvested:potato") > 0:
			first_harvest_minute = float(tick) / ticks_per_minute
	_report(minutes, first_harvest_minute, crew, ticks_per_minute)
	quit()


func _on_ate(meal: MealDef, dwarf: Dwarf) -> void:
	_eaten[dwarf] += meal.shift_seconds
	_meals_eaten[meal.display_name] = _meals_eaten.get(meal.display_name, 0) + 1


func _report(minutes: int, first_harvest: float, crew: Array[Dwarf], ticks_per_minute: int) -> void:
	var world: World = _game.world
	var plots: int = world.surface.farm_plots().size()
	var potatoes: int = world.ledger.count(&"harvested:potato")
	# Growing time after the first harvest, so the first sowing's wait doesn't count.
	var growing_minutes: float = maxf(1.0, minutes - first_harvest)
	var potato_crop: CropDef = load(POTATO_CROP)
	var potatoes_after_first: float = potatoes - plots * potato_crop.yield_count
	var per_plot_minute: float = maxf(0.0, potatoes_after_first) / plots / growing_minutes

	var food_made: float = 0.0
	var made: PackedStringArray = []
	for item: ItemDef in _game.catalog.items:
		var meal: MealDef = item as MealDef
		var count: int = world.ledger.count(StringName("made:%s" % item.id))
		if meal != null and count > 0:
			food_made += count * meal.shift_seconds
			made.append("%d %s" % [count, meal.display_name])
	var food_eaten: float = 0.0
	for dwarf: Dwarf in crew:
		food_eaten += _eaten[dwarf]

	var stew: MealDef = load("res://data/items/stew.tres")
	var stew_recipe: RecipeDef = load("res://data/recipes/stew.tres")
	var stew_per_potato: float = stew.shift_seconds / stew_recipe.needs(load("res://data/items/potato.tres"))
	var plot_food: float = per_plot_minute * stew_per_potato
	var dwarf_food: float = food_eaten / crew.size() / minutes
	var stove_food: float = food_made / minutes

	print("")
	print("== Food chain, %d game minutes: %d plots of potatoes kept sown, 1 farmer, 1 cook, 2 miners ==" % [minutes, plots])
	print("Potatoes: %d harvested, first at minute %.1f. After that, %.2f per plot per minute (%d every %.1f min)." % [
			potatoes, first_harvest, per_plot_minute, potato_crop.yield_count,
			potato_crop.yield_count / maxf(per_plot_minute, 0.001)])
	print("Kitchen (1 stove): made %s = %d work-seconds of food, %.0f a minute. Stove: %s" % [
			", ".join(made), roundi(food_made), stove_food, _shares(_stove_ticks)])
	print("Eaten: %s = %d work-seconds, %.1f a minute per dwarf." % [
			LogFormat.counts(_meals_eaten), roundi(food_eaten), dwarf_food])
	for dwarf: Dwarf in crew:
		var share: float = 100.0 * _work_ticks[dwarf] / (minutes * ticks_per_minute)
		var hungry: float = 100.0 * _hungry_ticks[dwarf] / (minutes * ticks_per_minute)
		print("  %s (%s): working %d%% of the time, waiting for food %d%%, ate %d work-seconds" % [
				dwarf.dwarf_name, dwarf.job_title(), roundi(share), roundi(hungry), roundi(_eaten[dwarf])])
	print("So, cooked as stew (%d work-seconds per potato):" % roundi(stew_per_potato))
	print("  one plot grows %.0f work-seconds of food a minute and a dwarf eats %.1f: 1 plot feeds %.1f dwarves (%.2f plots per dwarf)." % [
			plot_food, dwarf_food, plot_food / maxf(dwarf_food, 0.001), dwarf_food / maxf(plot_food, 0.001)])
	print("  one stove cooked %.0f a minute: 1 stove fed %.1f dwarves (it was idle or waiting the rest of the time)." % [
			stove_food, stove_food / maxf(dwarf_food, 0.001)])
	print("Hall at the end: %s" % _hall_food())


func _shares(ticks: Dictionary[String, int]) -> String:
	var total: int = 0
	for state: String in ticks:
		total += ticks[state]
	var parts: PackedStringArray = []
	for state: String in ticks:
		parts.append("%s %d%%" % [state.to_lower().replace("_", " "), roundi(100.0 * ticks[state] / total)])
	return ", ".join(parts)


func _hall_food() -> String:
	var storage: Storage = _game.world.hall.storage
	var parts: PackedStringArray = []
	for item: ItemDef in _game.catalog.items:
		if storage.count(item) > 0 and (item is MealDef or item.id == &"potato"):
			parts.append("%d %s" % [storage.count(item), item.display_name])
	return ", ".join(parts)
