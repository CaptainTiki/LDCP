class_name Workstation
extends Furniture
## A stove, fermenter and the like. The rhythm: a dwarf spends a short burst
## of work loading ingredients, the station then runs on its own timer, and
## the finished output waits here until someone carries it to the Great Hall.
## It is placed, turned and moved like any furniture, and worked from the
## cell in front of it.

enum State { WAITING_FOR_INPUT, PROCESSING, OUTPUT_READY }

@export var idle_color: Color = Color(0.45, 0.42, 0.4)
@export var busy_color: Color = Color(0.95, 0.55, 0.15)
@export var ready_color: Color = Color(0.35, 0.85, 0.35)

var state: State = State.WAITING_FOR_INPUT

var _hall_storage: Storage
var _process_seconds_left: float = 0.0

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _indicator: ColorRect = $Indicator
@onready var _clickable: Clickable = $Clickable


func _ready() -> void:
	receiver.completed.connect(_on_loaded)
	_clickable.clicked.connect(_on_clicked)


## Called by the room once the station is in place.
func setup(hall_storage: Storage) -> void:
	_hall_storage = hall_storage
	receiver.reset(recipe().load_work)
	_update_indicator()


func recipe() -> WorkstationDef:
	return def as WorkstationDef


func needs_loading() -> bool:
	return state == State.WAITING_FOR_INPUT


func has_output() -> bool:
	return state == State.OUTPUT_READY


## The floor cell a dwarf stands in to use the station.
func work_cell() -> Vector2i:
	return front_nav_cell()


## A line of text for the Look tool.
func describe() -> String:
	var r: WorkstationDef = recipe()
	match state:
		State.PROCESSING:
			return "%s: working, %ds to go" % [r.display_name, ceili(_process_seconds_left)]
		State.OUTPUT_READY:
			return "%s: %s ready to collect" % [r.display_name, r.output.display_name]
	return "%s: needs %d %s" % [r.display_name, r.input_count, r.input.display_name]


func sim_tick(delta: float) -> void:
	if state != State.PROCESSING:
		return
	_process_seconds_left -= delta
	if _process_seconds_left <= 0.0:
		state = State.OUTPUT_READY
	_update_indicator()


## Hands the finished goods to a dwarf.
func take_output(carrier: Carrier) -> void:
	if not has_output() or not carrier.can_take(recipe().output):
		return
	carrier.add(recipe().output, recipe().output_count)
	state = State.WAITING_FOR_INPUT
	_update_indicator()


## Loading work is done: use up the ingredients and start the timer.
func _on_loaded(worker: Node) -> void:
	if not _consume_inputs(worker):
		return
	state = State.PROCESSING
	_process_seconds_left = recipe().process_seconds
	_update_indicator()


## A dwarf brings the ingredients on his back. A player click takes them
## straight from the hall.
func _consume_inputs(worker: Node) -> bool:
	var dwarf: Dwarf = worker as Dwarf
	if dwarf != null:
		return dwarf.carrier.remove(recipe().input, recipe().input_count)
	return _hall_storage.remove(recipe().input, recipe().input_count)


func _on_clicked(manual_work: float) -> void:
	match state:
		State.WAITING_FOR_INPUT:
			if _hall_storage.count(recipe().input) >= recipe().input_count:
				receiver.apply_work(manual_work)
		State.OUTPUT_READY:
			_hall_storage.add(recipe().output, recipe().output_count)
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
