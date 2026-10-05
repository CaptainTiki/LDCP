class_name LogWatcher
extends Node
## One part of the game log. Each watcher looks after one corner of the
## game and writes down what changed there. GameLog drives them all on the
## game's clock.

var _game: Game
var _game_log: GameLog


func setup(game: Game, game_log: GameLog) -> void:
	_game = game
	_game_log = game_log
	_start()


## Logging has begun: note how things stand, so only changes get logged.
func _start() -> void:
	pass


## Every sim tick, for tallies of where time goes.
func sim_tick() -> void:
	pass


## Once a game second: log anything that changed since last time.
func check() -> void:
	pass


## Once a game minute: a few lines on how the minute went.
func minute_report() -> void:
	pass


## Every few minutes, and at the end: how the whole game has gone.
func totals_report() -> void:
	pass
