class_name Workstation
extends Furniture
## A stove, mash pot, fermenter and the like. The rhythm:
##   1. a recipe is chosen (by the player; a fermenter takes its from the mash
##      poured in),
##   2. someone works the station to load it, filling its bar. The
##      ingredients are used up only when the bar is full,
##   3. the station runs on its own timer,
##   4. the output waits here until someone takes it away.
## Storage-fed stations then go straight back to loading the same recipe, so
## the cooks can keep it going. It is placed, turned and moved like any
## furniture, and worked from the cell in front of it.

enum State { IDLE, LOADING, PROCESSING, OUTPUT_READY }

## Width of the progress bar over the station, in pixels.
const BAR_WIDTH: float = 14.0

@export var loading_color: Color = Color(0.91, 0.75, 0.31)
@export var busy_color: Color = Color(0.95, 0.55, 0.15)
@export var ready_color: Color = Color(0.35, 0.85, 0.35)
## Bubble and wobble while working (fermenters).
@export var jiggle_while_working: bool = false

var state: State = State.IDLE
## The recipe being made, or the last one made.
var recipe: RecipeDef = null

var _hall_storage: Storage
var _seconds_left: float = 0.0
## Ingredients already inside (mash the player poured in), so finishing the
## load uses up nothing else.
var _holding_input: bool = false
var _jiggle_time: float = 0.0

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _bar_back: ColorRect = $BarBack
@onready var _bar_fill: ColorRect = $BarFill


func _ready() -> void:
	receiver.completed.connect(_on_loaded)
	receiver.progressed.connect(_update_bar)
	set_process(false)


## Called by the room once the station is in place.
func setup(hall_storage: Storage) -> void:
	_hall_storage = hall_storage
	_update_bar()


func station_def() -> WorkstationDef:
	return def as WorkstationDef


func is_fed_by_station() -> bool:
	return station_def().fed_by != null


func is_idle() -> bool:
	return state == State.IDLE


func needs_loading() -> bool:
	return state == State.LOADING


func has_output() -> bool:
	return state == State.OUTPUT_READY


func is_holding_input() -> bool:
	return _holding_input


## The floor cell a dwarf stands in to use the station.
func work_cell() -> Vector2i:
	return front_nav_cell()


## Sets what the station makes. Only while it isn't busy cooking.
func select_recipe(new_recipe: RecipeDef) -> void:
	if state == State.PROCESSING or state == State.OUTPUT_READY:
		return
	if new_recipe != recipe:
		_holding_input = false
	recipe = new_recipe
	state = State.LOADING
	receiver.reset(recipe.load_work)
	_update_bar()


## The recipe that uses `item`, or null.
func recipe_for_input(item: ItemDef) -> RecipeDef:
	for candidate: RecipeDef in station_def().recipes:
		if candidate.input == item:
			return candidate
	return null


## Can this station-fed station take `item` (a mash) right now?
func accepts(item: ItemDef) -> bool:
	return is_fed_by_station() and state == State.IDLE and recipe_for_input(item) != null


## Gets ready for a dwarf bringing `item`: picks the matching recipe.
func prepare_for(item: ItemDef) -> void:
	if accepts(item):
		select_recipe(recipe_for_input(item))


## Pours a finished station's output straight in. Loading still takes work.
func pour_from(source: Workstation) -> bool:
	if not source.has_output() or not accepts(source.recipe.output):
		return false
	select_recipe(recipe_for_input(source.recipe.output))
	source.empty_output()
	_holding_input = true
	_update_bar()
	return true


## Pours from the player's hands, if they hold something this takes.
func pour_from_carrier(carrier: Carrier) -> bool:
	if carrier.is_empty() or not accepts(carrier.item):
		return false
	var wanted: RecipeDef = recipe_for_input(carrier.item)
	if not carrier.remove(wanted.input, wanted.input_count):
		return false
	select_recipe(wanted)
	_holding_input = true
	_update_bar()
	return true


## Could the player's clicks load this right now? (The ingredients have to
## be in the hall, or already poured in.)
func can_load_by_hand() -> bool:
	if state != State.LOADING:
		return false
	if _holding_input:
		return true
	return not is_fed_by_station() and _hall_storage.count(recipe.input) >= recipe.input_count


## Hands the finished goods to a dwarf or the player. False if no room.
func take_output(carrier: Carrier) -> bool:
	if not has_output() or not carrier.has_room_for(recipe.output, recipe.output_count):
		return false
	carrier.add(recipe.output, recipe.output_count)
	empty_output()
	return true


## The output has gone. Storage-fed stations get ready to make it again.
func empty_output() -> void:
	if is_fed_by_station():
		state = State.IDLE
	else:
		state = State.LOADING
		receiver.reset(recipe.load_work)
	_update_bar()


func sim_tick(delta: float) -> void:
	if state != State.PROCESSING:
		return
	_seconds_left -= delta
	if _seconds_left <= 0.0:
		state = State.OUTPUT_READY
		set_process(false)
		_sprite.scale = Vector2.ONE
	_update_bar()


## A line of text for the Look tool and the top bar.
func describe() -> String:
	var name_text: String = def.display_name
	match state:
		State.IDLE:
			if is_fed_by_station():
				return "%s: empty, pour in some mash" % name_text
			return "%s: pick a recipe" % name_text
		State.LOADING:
			if can_load_by_hand():
				return "%s: %s, click to load (%d%%)" % [name_text, recipe.display_name, roundi(receiver.ratio() * 100.0)]
			if is_fed_by_station():
				return "%s: %s, waiting for mash" % [name_text, recipe.display_name]
			return "%s: %s, needs %d %s" % [name_text, recipe.display_name, recipe.input_count, recipe.input.display_name]
		State.PROCESSING:
			return "%s: making %s, %ds to go" % [name_text, recipe.display_name, ceili(_seconds_left)]
	return "%s: %d %s ready" % [name_text, recipe.output_count, recipe.output.display_name]


func _process(delta: float) -> void:
	# Only runs while a jiggly station is working.
	_jiggle_time += delta
	var wobble: float = sin(_jiggle_time * 9.0) * 0.06
	_sprite.scale = Vector2(1.0 + wobble, 1.0 - wobble)


## The bar is full: use up the ingredients and start the timer. A dwarf
## brings them on his back; the player's come from the hall (or were
## poured in already).
func _on_loaded(worker: Node) -> void:
	var dwarf: Dwarf = worker as Dwarf
	if _holding_input:
		_holding_input = false
	elif dwarf != null:
		if not dwarf.carrier.remove(recipe.input, recipe.input_count):
			return
	elif is_fed_by_station() or not _hall_storage.remove(recipe.input, recipe.input_count):
		return
	state = State.PROCESSING
	_seconds_left = recipe.process_seconds
	set_process(jiggle_while_working)
	_update_bar()


func _update_bar() -> void:
	var ratio: float = 0.0
	var color: Color = loading_color
	match state:
		State.LOADING:
			ratio = receiver.ratio()
		State.PROCESSING:
			ratio = 1.0 - _seconds_left / recipe.process_seconds
			color = busy_color
		State.OUTPUT_READY:
			ratio = 1.0
			color = ready_color
	_bar_back.visible = state != State.IDLE
	_bar_fill.visible = _bar_back.visible
	_bar_fill.size.x = roundf(BAR_WIDTH * ratio)
	_bar_fill.color = color
