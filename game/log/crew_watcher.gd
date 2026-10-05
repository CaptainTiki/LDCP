class_name CrewWatcher
extends LogWatcher
## Logs the dwarves: hires, jobs given, tools taken, going idle (and why),
## and waiting on an empty pantry. Tallies where each dwarf's time goes,
## tick by tick, which is the heart of tuning: how much is work, and how
## much is walking, climbing, eating or waiting. Counts what's eaten and
## drunk, and how often each dwarf comes in for a meal.

## Ways to spend a tick, in the order they're reported. "wait" is standing
## at the job while it sorts itself out (a crop growing, a stove cooking);
## "idle" is having nothing to do at all.
const ACTIVITIES: Array[String] = ["work", "haul", "walk", "climb", "eat", "wait", "idle", "no food", "no seat"]

var _jobs: Dictionary[Dwarf, String] = {}
var _tools: Dictionary[Dwarf, String] = {}
## When each idle dwarf went idle, in game seconds, and why.
var _idle_since: Dictionary[Dwarf, float] = {}
var _idle_reason: Dictionary[Dwarf, String] = {}
var _hungry_since: Dictionary[Dwarf, float] = {}
## Per dwarf: {"minute": {activity: ticks}, "total": {...}, "idle": {reason: ticks}}.
var _ticks: Dictionary[Dwarf, Dictionary] = {}
## What's been eaten and drunk, by name: this minute, and all game.
var _consumed: Dictionary[String, Dictionary] = {"minute": {}, "total": {}}
## When each dwarf finished each meal, in game seconds.
var _meal_times: Dictionary[Dwarf, Array] = {}


func _start() -> void:
	var names: PackedStringArray = []
	for dwarf: Dwarf in _game.world.dwarves.active():
		_meet(dwarf)
		names.append(dwarf.dwarf_name)
	_game_log.event("Start: %d dwarves (%s)" % [names.size(), ", ".join(names)])


func sim_tick() -> void:
	for dwarf: Dwarf in _game.world.dwarves.active():
		if not _ticks.has(dwarf):
			continue
		var activity: String = _activity(dwarf)
		var ticks: Dictionary = _ticks[dwarf]
		ticks.minute[activity] = ticks.minute.get(activity, 0) + 1
		ticks.total[activity] = ticks.total.get(activity, 0) + 1
		if activity == "idle":
			ticks.idle[dwarf.idler.reason] = ticks.idle.get(dwarf.idler.reason, 0) + 1


func check() -> void:
	for dwarf: Dwarf in _game.world.dwarves.active():
		if not _ticks.has(dwarf):
			_meet(dwarf)
			_game_log.event("Hired %s (%d dwarves)" % [dwarf.dwarf_name, _game.world.dwarves.active_count()])
		_check_job(dwarf)
		_check_idle(dwarf)
		_check_hunger(dwarf)


func minute_report() -> void:
	if not _consumed.minute.is_empty():
		_game_log.line("Eaten and drunk: %s" % LogFormat.counts(_consumed.minute))
		_consumed.minute = {}
	_game_log.line("Dwarves:")
	for dwarf: Dwarf in _ticks:
		var drink: String = dwarf.thirst.drink.display_name if dwarf.thirst.ratio() > 0.0 else "thirsty"
		_game_log.line("  %s (%s): %s | food %d%%, %s %d%%" % [
				dwarf.dwarf_name, _jobs[dwarf], LogFormat.shares(_ticks[dwarf].minute, ACTIVITIES),
				roundi(dwarf.hunger.ratio() * 100.0), drink, roundi(dwarf.thirst.multiplier() * 100.0)])
		_ticks[dwarf].minute = {}


func totals_report() -> void:
	_game_log.line("Eaten and drunk: %s" % LogFormat.counts(_consumed.total))
	_game_log.line("Dwarves:")
	for dwarf: Dwarf in _ticks:
		_game_log.line("  %s: %s%s" % [dwarf.dwarf_name, LogFormat.shares(_ticks[dwarf].total, ACTIVITIES), _meal_pace(dwarf)])
		var idle: Dictionary = _ticks[dwarf].idle
		if not idle.is_empty():
			var parts: PackedStringArray = []
			for reason: String in idle:
				parts.append("%s %s" % [reason, LogFormat.time(idle[reason] * _game_log.tick_seconds())])
			_game_log.line("    idle: %s" % ", ".join(parts))


func _meet(dwarf: Dwarf) -> void:
	_ticks[dwarf] = {"minute": {}, "total": {}, "idle": {}}
	_jobs[dwarf] = _job_of(dwarf)
	_tools[dwarf] = _tool_of(dwarf)
	_meal_times[dwarf] = []
	dwarf.hunger.ate.connect(_on_ate.bind(dwarf))
	dwarf.thirst.drank.connect(_on_drank)


func _on_ate(meal: MealDef, dwarf: Dwarf) -> void:
	_count(meal.display_name)
	_meal_times[dwarf].append(_game_log.seconds())


func _on_drank(drink: DrinkDef) -> void:
	_count(drink.display_name)


func _count(item_name: String) -> void:
	for span: String in ["minute", "total"]:
		_consumed[span][item_name] = _consumed[span].get(item_name, 0) + 1


## "; 4 meals, one every 2:45" from the dwarf's first meal to his last.
func _meal_pace(dwarf: Dwarf) -> String:
	var times: Array = _meal_times[dwarf]
	if times.size() < 2:
		return "; no meals" if times.is_empty() else "; 1 meal"
	var gap: float = (times[-1] - times[0]) / (times.size() - 1)
	return "; %d meals, one every %s" % [times.size(), LogFormat.time(gap)]


func _activity(dwarf: Dwarf) -> String:
	if dwarf.worker.did_work_this_tick():
		return "work"
	var meal: MealBreak = dwarf.meal_break
	if meal.is_waiting_for_food:
		return "no food"
	if meal.is_waiting_for_seat:
		return "no seat"
	if meal.in_progress and meal.is_seated:
		return "eat"
	if dwarf.idler.is_idle():
		return "idle"
	if dwarf.mover.is_climbing():
		return "climb"
	if dwarf.mover.is_moving():
		return "walk" if dwarf.carrier.is_empty() else "haul"
	return "wait"


func _check_job(dwarf: Dwarf) -> void:
	var job: String = _job_of(dwarf)
	if job != _jobs[dwarf]:
		_game_log.event("%s: %s" % [dwarf.dwarf_name, job])
		_jobs[dwarf] = job
	var tool: String = _tool_of(dwarf)
	if tool != _tools[dwarf]:
		_game_log.event("%s took a %s" % [dwarf.dwarf_name, tool])
		_tools[dwarf] = tool


func _check_idle(dwarf: Dwarf) -> void:
	var now: float = _game_log.seconds()
	if dwarf.idler.is_idle():
		var reason: String = dwarf.idler.reason
		if not _idle_since.has(dwarf):
			_idle_since[dwarf] = now
			_game_log.event("%s idle: %s" % [dwarf.dwarf_name, reason])
		elif reason != _idle_reason[dwarf]:
			_game_log.event("%s still idle: %s" % [dwarf.dwarf_name, reason])
		_idle_reason[dwarf] = reason
	elif _idle_since.has(dwarf):
		_game_log.event("%s back to work after %s idle" % [dwarf.dwarf_name, LogFormat.time(now - _idle_since[dwarf])])
		_idle_since.erase(dwarf)
		_idle_reason.erase(dwarf)


func _check_hunger(dwarf: Dwarf) -> void:
	var now: float = _game_log.seconds()
	if dwarf.meal_break.is_waiting_for_food:
		if not _hungry_since.has(dwarf):
			_hungry_since[dwarf] = now
			_game_log.event("%s is waiting for food" % dwarf.dwarf_name)
	elif _hungry_since.has(dwarf):
		_game_log.event("%s got fed after waiting %s" % [dwarf.dwarf_name, LogFormat.time(now - _hungry_since[dwarf])])
		_hungry_since.erase(dwarf)


func _job_of(dwarf: Dwarf) -> String:
	var node: OreNode = dwarf.assignment.target as OreNode
	if node != null:
		return "Miner at %s" % node.name
	return dwarf.job_title()


func _tool_of(dwarf: Dwarf) -> String:
	return dwarf.tool.display_name if dwarf.tool != null else "old pick"
