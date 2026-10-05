class_name Workstation
extends Furniture
## A stove, mash pot, fermenter and the like. The rhythm:
##   1. a recipe is chosen (by the player; a fermenter takes its from the mash
##      poured in),
##   2. the ingredients go in. A dwarf brings one kind per trip and drops it
##      in; the player's clicks draw straight on the Great Hall,
##   3. someone works the station to load it, filling its bar. Ingredients
##      are only used up when the bar is full,
##   4. the station runs on its own timer,
##   5. the output waits here until someone takes it away.
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
var _ledger: Ledger
var _seconds_left: float = 0.0
## Ingredients dropped in so far for the current batch.
var _stock: Dictionary[ItemDef, int] = {}
var _jiggle_time: float = 0.0

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _bar_back: ColorRect = $BarBack
@onready var _bar_fill: ColorRect = $BarFill


func _ready() -> void:
	receiver.completed.connect(_on_loaded)
	receiver.progressed.connect(_update_bar)
	set_process(false)


## Called by the room once the station is in place.
func setup(hall_storage: Storage, ledger: Ledger) -> void:
	_hall_storage = hall_storage
	_ledger = ledger
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


## True once any ingredient has gone in for the current batch.
func is_holding_input() -> bool:
	return not _stock.is_empty()


## True when everything for the batch is inside: only the bar is left.
func is_stocked() -> bool:
	if state != State.LOADING:
		return false
	for stack: ItemStack in recipe.inputs:
		if still_needs(stack.item) > 0:
			return false
	return true


## How many more of `item` the batch still needs dropped in.
func still_needs(item: ItemDef) -> int:
	if state != State.LOADING:
		return 0
	return maxi(0, recipe.needs(item) - _stock.get(item, 0))


## The floor cell a dwarf stands in to use the station.
func work_cell() -> Vector2i:
	return front_nav_cell()


## Sets what the station makes. Only while it isn't busy cooking. Switching
## recipe hands back anything already put in.
func select_recipe(new_recipe: RecipeDef) -> void:
	if state == State.PROCESSING or state == State.OUTPUT_READY:
		return
	if new_recipe != recipe:
		_return_stock()
	recipe = new_recipe
	state = State.LOADING
	receiver.reset(recipe.load_work)
	_update_bar()


## The recipe that uses `item`, or null.
func recipe_for_input(item: ItemDef) -> RecipeDef:
	for candidate: RecipeDef in station_def().recipes:
		if candidate.needs(item) > 0:
			return candidate
	return null


## Can this station-fed station take `item` (a mash) right now?
func accepts(item: ItemDef) -> bool:
	return is_fed_by_station() and state == State.IDLE and recipe_for_input(item) != null


## Gets ready for something arriving: a fermenter picks its recipe.
func prepare_for(item: ItemDef) -> void:
	if accepts(item):
		select_recipe(recipe_for_input(item))


## Drops in what the carrier holds, as much as the batch still needs.
## Returns whether anything went in.
func deposit(carrier: Carrier) -> bool:
	if carrier.is_empty():
		return false
	var item: ItemDef = carrier.item
	prepare_for(item)
	var amount: int = mini(still_needs(item), carrier.count)
	if amount <= 0:
		return false
	carrier.remove(item, amount)
	_stock[item] = _stock.get(item, 0) + amount
	_update_bar()
	return true


## Pours a finished station's output straight in. Loading still takes work.
func pour_from(source: Workstation) -> bool:
	if not source.has_output() or not accepts(source.recipe.output):
		return false
	var mash: ItemDef = source.recipe.output
	select_recipe(recipe_for_input(mash))
	_stock[mash] = _stock.get(mash, 0) + source.recipe.output_count
	source.empty_output()
	_update_bar()
	return true


## Pours from the player's hands, if they hold something this takes.
func pour_from_carrier(carrier: Carrier) -> bool:
	if carrier.is_empty() or not accepts(carrier.item):
		return false
	return deposit(carrier)


## Could the player's clicks load this right now? Everything must be inside
## already, or (for storage-fed stations) waiting in the hall.
func can_load_by_hand() -> bool:
	if state != State.LOADING:
		return false
	if is_stocked():
		return true
	if is_fed_by_station():
		return false
	for stack: ItemStack in recipe.inputs:
		if _hall_storage.count(stack.item) < still_needs(stack.item):
			return false
	return true


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


## Puts anything inside (ingredients, finished goods) back into the hall.
## For when the station is taken away.
func return_contents() -> void:
	_return_stock()
	if has_output():
		_hall_storage.add(recipe.output, recipe.output_count)
		state = State.IDLE


func sim_tick(delta: float) -> void:
	if state != State.PROCESSING:
		return
	_seconds_left -= delta
	if _seconds_left <= 0.0:
		state = State.OUTPUT_READY
		set_process(false)
		_sprite.scale = Vector2.ONE
		_ledger.record_made(recipe.output, recipe.output_count)
	_update_bar()


## A line of text for the Look tool and the top bar.
func describe() -> String:
	return "%s: %s" % [def.display_name, status_text()]


## What the station is up to, or waiting for, in a few words.
func status_text() -> String:
	match state:
		State.IDLE:
			return "empty, pour in some mash" if is_fed_by_station() else "pick a recipe"
		State.LOADING:
			if can_load_by_hand():
				return "%s, click to load (%d%%)" % [recipe.display_name, roundi(receiver.ratio() * 100.0)]
			if is_fed_by_station():
				return "%s, waiting for mash" % recipe.display_name
			return "%s, waiting for %s" % [recipe.display_name, _missing_text()]
		State.PROCESSING:
			return "making %s, %ds to go" % [recipe.display_name, ceili(_seconds_left)]
	return "%d %s ready" % [recipe.output_count, recipe.output.display_name]


## The ingredients the hall can't supply yet, e.g. "1 Potato".
func _missing_text() -> String:
	var parts: PackedStringArray = []
	for stack: ItemStack in recipe.inputs:
		var wanted: int = still_needs(stack.item)
		if wanted > _hall_storage.count(stack.item):
			parts.append("%d %s" % [wanted, stack.item.display_name])
	return ", ".join(parts) if not parts.is_empty() else "a cook"


func _process(delta: float) -> void:
	# Only runs while a jiggly station is working.
	_jiggle_time += delta
	var wobble: float = sin(_jiggle_time * 9.0) * 0.06
	_sprite.scale = Vector2(1.0 + wobble, 1.0 - wobble)


## The bar is full: use up the ingredients and start the timer. Dwarves only
## work a station once everything is inside; for the player, whatever is
## missing comes from the hall now.
func _on_loaded(worker: Node) -> void:
	if not is_stocked():
		if worker != null or is_fed_by_station() or not _take_missing_from_hall():
			return
	_stock.clear()
	state = State.PROCESSING
	_seconds_left = recipe.process_seconds
	set_process(jiggle_while_working)
	_update_bar()


func _take_missing_from_hall() -> bool:
	for stack: ItemStack in recipe.inputs:
		if _hall_storage.count(stack.item) < still_needs(stack.item):
			return false
	for stack: ItemStack in recipe.inputs:
		var amount: int = still_needs(stack.item)
		_hall_storage.remove(stack.item, amount)
		_stock[stack.item] = _stock.get(stack.item, 0) + amount
	return true


func _return_stock() -> void:
	for item: ItemDef in _stock:
		_hall_storage.add(item, _stock[item])
	_stock.clear()


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
