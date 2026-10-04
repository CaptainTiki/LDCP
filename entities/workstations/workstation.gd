class_name Workstation
extends Node2D
## A stove, fermenter and the like. The rhythm: a dwarf spends a short burst
## of work loading ingredients, the station then runs on its own timer, and
## the finished output waits here until someone carries it to the Great Hall.
## Interiors are seen from above: a dwarf stands on the floor cell in front
## of (below) the station to use it.

enum State { WAITING_FOR_INPUT, PROCESSING, OUTPUT_READY }

@export var idle_color: Color = Color(0.35, 0.35, 0.35)
@export var busy_color: Color = Color(0.95, 0.55, 0.15)
@export var ready_color: Color = Color(0.35, 0.85, 0.35)

var def: WorkstationDef
var state: State = State.WAITING_FOR_INPUT

var _hall_storage: Storage
var _process_seconds_left: float = 0.0

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _indicator: ColorRect = $Indicator
@onready var _clickable: Clickable = $Clickable


func _ready() -> void:
	receiver.completed.connect(_on_loaded)
	_clickable.clicked.connect(_on_clicked)


func setup(station_def: WorkstationDef, hall_storage: Storage) -> void:
	def = station_def
	_hall_storage = hall_storage
	receiver.reset(def.load_work)
	_update_indicator()


func needs_loading() -> bool:
	return state == State.WAITING_FOR_INPUT


func has_output() -> bool:
	return state == State.OUTPUT_READY


## The floor cell in front of the station.
func work_cell() -> Vector2i:
	return NavGrid.world_to_cell(global_position) + Vector2i.DOWN


func sim_tick(delta: float) -> void:
	if state != State.PROCESSING:
		return
	_process_seconds_left -= delta
	if _process_seconds_left <= 0.0:
		state = State.OUTPUT_READY
	_update_indicator()


## Hands the finished goods to a dwarf.
func take_output(carrier: Carrier) -> void:
	if not has_output() or not carrier.can_take(def.output):
		return
	carrier.add(def.output, def.output_count)
	state = State.WAITING_FOR_INPUT
	_update_indicator()


## Loading work is done: use up the ingredients and start the timer.
func _on_loaded(worker: Node) -> void:
	if not _consume_inputs(worker):
		return
	state = State.PROCESSING
	_process_seconds_left = def.process_seconds
	_update_indicator()


## A dwarf brings the ingredients on his back. A player click takes them
## straight from the hall.
func _consume_inputs(worker: Node) -> bool:
	var dwarf: Dwarf = worker as Dwarf
	if dwarf != null:
		return dwarf.carrier.remove(def.input, def.input_count)
	return _hall_storage.remove(def.input, def.input_count)


func _on_clicked(manual_work: float) -> void:
	match state:
		State.WAITING_FOR_INPUT:
			if _hall_storage.count(def.input) >= def.input_count:
				receiver.apply_work(manual_work)
		State.OUTPUT_READY:
			_hall_storage.add(def.output, def.output_count)
			state = State.WAITING_FOR_INPUT
			_update_indicator()


func _update_indicator() -> void:
	match state:
		State.WAITING_FOR_INPUT:
			_indicator.color = idle_color
		State.PROCESSING:
			_indicator.color = busy_color
		State.OUTPUT_READY:
			_indicator.color = ready_color
