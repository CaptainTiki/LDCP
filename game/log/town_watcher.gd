class_name TownWatcher
extends LogWatcher
## Logs the town: buildings put up or knocked down, crops sown, recipes
## picked, the hall's furniture, game speed and the player's clicks. Tallies
## how the farm plots and stations spend their time, to show what's waiting
## on what.

const PLOT_STATES: Array[String] = ["growing", "dry", "ripe", "empty"]
const STATION_STATES: Array[String] = ["working", "loading", "unattended", "no ingredients", "done", "idle"]

## Things on the town grid, by instance id, and how they read in the log.
var _placeables: Dictionary[int, String] = {}
## What each plot has in it, by instance id ("" when empty).
var _plot_crops: Dictionary[int, String] = {}
var _recipes: Dictionary[int, String] = {}
var _station_names: Dictionary[int, String] = {}
var _hall_furniture: String = ""
var _speed: float = 1.0
var _clicks: Dictionary[String, int] = {"minute": 0, "total": 0}
var _sown: Dictionary = {}
var _plot_ticks: Dictionary[String, Dictionary] = {"minute": {}, "total": {}}
## Station tallies by instance id: {"minute": {...}, "total": {...}}.
var _station_ticks: Dictionary[int, Dictionary] = {}


func _start() -> void:
	for placeable: Placeable in _game.world.surface.placeables():
		_placeables[placeable.get_instance_id()] = _describe(placeable)
	for plot: FarmPlot in _game.world.surface.farm_plots():
		_plot_crops[plot.get_instance_id()] = _crop_in(plot)
	for station: Workstation in _stations():
		_recipes[station.get_instance_id()] = LogFormat.name_of(station.recipe)
	_hall_furniture = _furniture_in_hall()
	_speed = _game.clock.speed_scale
	_game.world.input.player_clicked.connect(_on_player_clicked)
	var buildings: Dictionary = {}
	for placeable: Placeable in _game.world.surface.placeables():
		buildings[placeable.def.display_name] = buildings.get(placeable.def.display_name, 0) + 1
	_game_log.event("Start: %s; hall has %s" % [LogFormat.counts(buildings), _hall_furniture])


func sim_tick() -> void:
	for plot: FarmPlot in _game.world.surface.farm_plots():
		_tally(_plot_ticks, _plot_state(plot))
	for station: Workstation in _stations():
		var id: int = station.get_instance_id()
		if not _station_ticks.has(id):
			_station_ticks[id] = {"minute": {}, "total": {}}
		_tally(_station_ticks[id], _station_state(station))


func check() -> void:
	_check_placeables()
	_check_plots()
	_check_recipes()
	var furniture: String = _furniture_in_hall()
	if furniture != _hall_furniture:
		_game_log.event("Hall furniture now %s" % furniture)
		_hall_furniture = furniture
	if not is_equal_approx(_game.clock.speed_scale, _speed):
		_speed = _game.clock.speed_scale
		_game_log.event("Game speed x%s" % _speed)


func minute_report() -> void:
	var plots: int = _game.world.surface.farm_plots().size()
	_game_log.line("Plots (%d): %s" % [plots, LogFormat.shares(_plot_ticks.minute, PLOT_STATES)])
	_plot_ticks.minute = {}
	for id: int in _station_ticks:
		var ticks: Dictionary = _station_ticks[id]
		if not ticks.minute.is_empty():
			_game_log.line("%s: %s" % [_station_names.get(id, "?"), LogFormat.shares(ticks.minute, STATION_STATES)])
		ticks.minute = {}
	var sown: String = (", sowed " + LogFormat.counts(_sown)) if not _sown.is_empty() else ""
	_game_log.line("Player: %d clicks%s" % [_clicks.minute, sown])
	_clicks.minute = 0
	_sown = {}


func totals_report() -> void:
	_game_log.line("Plots: %s" % LogFormat.shares(_plot_ticks.total, PLOT_STATES))
	for id: int in _station_ticks:
		_game_log.line("%s: %s" % [_station_names.get(id, "?"), LogFormat.shares(_station_ticks[id].total, STATION_STATES)])
	_game_log.line("Player clicks: %d" % _clicks.total)


func _check_placeables() -> void:
	var seen: Dictionary[int, bool] = {}
	for placeable: Placeable in _game.world.surface.placeables():
		var id: int = placeable.get_instance_id()
		seen[id] = true
		if not _placeables.has(id):
			_placeables[id] = _describe(placeable)
			_game_log.event("Built %s" % _placeables[id])
	for id: int in _placeables.keys():
		if not seen.has(id):
			_game_log.event("Removed %s" % _placeables[id])
			_placeables.erase(id)


## Only the player sows, so every new crop in the ground is one of theirs.
func _check_plots() -> void:
	for plot: FarmPlot in _game.world.surface.farm_plots():
		var id: int = plot.get_instance_id()
		var crop: String = _crop_in(plot)
		if crop != "" and _plot_crops.get(id, "") == "":
			_sown[crop] = _sown.get(crop, 0) + 1
		_plot_crops[id] = crop


func _check_recipes() -> void:
	for station: Workstation in _stations():
		var id: int = station.get_instance_id()
		var recipe: String = LogFormat.name_of(station.recipe)
		if _recipes.get(id, "-") != recipe and recipe != "-":
			_game_log.event("%s set to %s" % [_station_names[id], recipe])
		_recipes[id] = recipe


## Every station in every building, naming new ones as they turn up.
func _stations() -> Array[Workstation]:
	var stations: Array[Workstation] = []
	for placeable: Placeable in _game.world.surface.placeables():
		var building: Building = placeable as Building
		if building == null:
			continue
		for station: Workstation in building.workstations():
			stations.append(station)
			if not _station_names.has(station.get_instance_id()):
				_station_names[station.get_instance_id()] = _unique_name(
						"%s %s" % [building.def.display_name, station.def.display_name])
	return stations


func _unique_name(base: String) -> String:
	var taken: Array = _station_names.values()
	if not taken.has(base):
		return base
	var n: int = 2
	while taken.has("%s %d" % [base, n]):
		n += 1
	return "%s %d" % [base, n]


func _plot_state(plot: FarmPlot) -> String:
	if not plot.is_planted():
		return "empty"
	match plot.current_task():
		FarmPlot.Task.HARVEST:
			return "ripe"
		FarmPlot.Task.WATER:
			return "dry"
	return "growing"


func _station_state(station: Workstation) -> String:
	match station.state:
		Workstation.State.PROCESSING:
			return "working"
		Workstation.State.LOADING:
			return _loading_state(station)
		Workstation.State.OUTPUT_READY:
			return "done"
	return "idle"


## A station with a recipe set is waiting on one of three things, and the log
## keeps them apart because each has a different fix: a worker is stocking or
## loading it ("loading"), everything is to hand but nobody is on it, so the
## workers are short ("unattended"), or the hall lacks an ingredient, so the
## farm is short ("no ingredients").
func _loading_state(station: Workstation) -> String:
	var claimant: Node = station.receiver.claimed_by
	if claimant != null and is_instance_valid(claimant):
		return "loading"
	if station.can_load_by_hand():
		return "unattended"
	return "no ingredients"


func _crop_in(plot: FarmPlot) -> String:
	return plot.crop.display_name if plot.is_planted() else ""


func _describe(placeable: Placeable) -> String:
	return "%s at %s" % [placeable.def.display_name, placeable.tile]


func _furniture_in_hall() -> String:
	var amounts: Dictionary = {}
	for piece: Furniture in _game.world.hall.interior.furniture():
		amounts[piece.def.display_name] = amounts.get(piece.def.display_name, 0) + 1
	return LogFormat.counts(amounts)


func _tally(ticks: Dictionary, state: String) -> void:
	ticks.minute[state] = ticks.minute.get(state, 0) + 1
	ticks.total[state] = ticks.total.get(state, 0) + 1


func _on_player_clicked() -> void:
	_clicks.minute += 1
	_clicks.total += 1
