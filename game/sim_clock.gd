class_name SimClock
extends Node
## The single source of gameplay time. Everything that simulates advances in
## fixed steps from here, so debug speed-up (and later offline catch-up) is
## just "run more ticks". Visuals interpolate between ticks.

signal ticked(delta: float)

@export var tick_seconds: float = 0.1
## Safety valve: never run more than this many ticks in one rendered frame.
@export var max_ticks_per_frame: int = 40

## 1.0 is real time. The debug panel raises this.
var speed_scale: float = 1.0

var _accumulated: float = 0.0


func _process(frame_delta: float) -> void:
	_accumulated += frame_delta * speed_scale
	var ticks_run: int = 0
	while _accumulated >= tick_seconds and ticks_run < max_ticks_per_frame:
		_accumulated -= tick_seconds
		ticks_run += 1
		ticked.emit(tick_seconds)
	if ticks_run == max_ticks_per_frame:
		# We fell behind (a long hitch). Drop the backlog rather than spiral.
		_accumulated = 0.0


## How far we are between the last tick and the next one, 0..1.
func tick_fraction() -> float:
	return clampf(_accumulated / tick_seconds, 0.0, 1.0)


## Runs ticks immediately. Used by tests, and later by offline catch-up.
func advance(tick_count: int) -> void:
	for i: int in tick_count:
		ticked.emit(tick_seconds)
