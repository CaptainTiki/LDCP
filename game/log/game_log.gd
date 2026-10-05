class_name GameLog
extends Node
## The game's log: one plain-text file per session in user://logs, written
## as the game runs, so a playthrough can be read back to see how the
## tuning plays. It opens with every tuning and content number, then notes
## events as they happen (unlocks, buildings, deposits found, dwarves going
## idle...) stamped with game time, a summary each game minute, and
## running totals every few minutes and when the game closes.
##
## The child LogWatchers do the watching, one per corner of the game.
## Only a game run as the main scene logs by itself, so tests and tools
## that make their own game don't fill the folder; they can call start().

const LOG_DIR: String = "user://logs"
## Godot's own logs share the folder and it rotates godot*.log, so ours
## are named differently.
const FILE_PREFIX: String = "game_"

## Older game logs beyond this many are deleted, oldest first.
@export var max_files: int = 100
## Running totals every this many game minutes.
@export var totals_every_minutes: int = 5

var _game: Game
var _file: FileAccess
var _ticks: int = 0
var _ticks_per_second: int = 10
var _minutes: int = 0
var _watchers: Array[LogWatcher] = []


func setup(game: Game) -> void:
	_game = game
	if get_tree().current_scene == game:
		start(LOG_DIR)


## Opens a new log in `folder` and starts writing to it.
func start(folder: String) -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	_trim_old_logs(folder)
	var stamp: String = Time.get_datetime_string_from_system().replace("T", "_").replace(":", "-")
	_file = FileAccess.open(folder.path_join("%s%s.log" % [FILE_PREFIX, stamp]), FileAccess.WRITE)
	if _file == null:
		push_warning("Game log could not be opened in %s" % folder)
		return
	_ticks_per_second = maxi(1, roundi(1.0 / _game.clock.tick_seconds))
	LogHeader.write(self, _game)
	for child: Node in get_children():
		var watcher: LogWatcher = child as LogWatcher
		watcher.setup(_game, self)
		_watchers.append(watcher)
	# Connected after the world, so each tick is seen once it's played out.
	_game.clock.ticked.connect(_on_ticked)


func is_logging() -> bool:
	return _file != null


func file_path() -> String:
	return _file.get_path() if _file != null else ""


## Game time so far, in seconds.
func seconds() -> float:
	return _ticks * _game.clock.tick_seconds


func tick_seconds() -> float:
	return _game.clock.tick_seconds


## A line stamped with the game time.
func event(text: String) -> void:
	line("%s  %s" % [LogFormat.time(seconds()), text])


func line(text: String) -> void:
	_file.store_line(text)
	_file.flush()  # A crash or a closed window still leaves a full log.


func _on_ticked(_delta: float) -> void:
	_ticks += 1
	for watcher: LogWatcher in _watchers:
		watcher.sim_tick()
	if _ticks % _ticks_per_second == 0:
		for watcher: LogWatcher in _watchers:
			watcher.check()
	if _ticks % (_ticks_per_second * 60) == 0:
		_minutes += 1
		line("")
		line("-- %s, minute %d (%s) --" % [LogFormat.time(seconds()), _minutes, Time.get_time_string_from_system()])
		for watcher: LogWatcher in _watchers:
			watcher.minute_report()
		if _minutes % totals_every_minutes == 0:
			_totals("Totals so far")


func _totals(title: String) -> void:
	line("")
	line("== %s, %s ==" % [title, LogFormat.time(seconds())])
	for watcher: LogWatcher in _watchers:
		watcher.totals_report()


func _exit_tree() -> void:
	if _file == null:
		return
	_totals("End of game")
	_file.close()
	_file = null


func _trim_old_logs(folder: String) -> void:
	var logs: Array[String] = []
	for file_name: String in DirAccess.get_files_at(folder):
		if file_name.begins_with(FILE_PREFIX) and file_name.ends_with(".log"):
			logs.append(file_name)
	logs.sort()  # Named by date and time, so oldest first.
	while logs.size() >= max_files:
		DirAccess.remove_absolute(folder.path_join(logs.pop_front()))
