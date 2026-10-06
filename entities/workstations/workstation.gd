class_name Workstation
extends Furniture
## A stove, mash pot, fermenter and the like. A station rests with no
## recipe. A batch goes:
##   1. a batch starts: a worker picks the best he can make and sets it as he
##      brings the first ingredients; the player's click on a free station
##      starts their own pick (player_recipe); a fermenter takes its recipe
##      from the mash poured in,
##   2. the ingredients go in. A dwarf brings one kind per trip and drops it
##      in; the player's clicks draw straight on the Great Hall,
##   3. someone works the station to load it, filling its bar. Ingredients
##      are only used up when the bar is full,
##   4. the station runs on its own timer,
##   5. the output waits here until someone takes it away, and the station
##      is free again.
## A batch can be cancelled until it's done; what went in goes back to the
## hall. It is placed, turned and moved like any furniture, and worked from
## the cell in front of it.

enum State { IDLE, LOADING, PROCESSING, OUTPUT_READY }

## Width of the progress bar over the station, in pixels.
const BAR_WIDTH: float = 14.0

@export var loading_color: Color = Color(0.91, 0.75, 0.31)
@export var busy_color: Color = Color(0.95, 0.55, 0.15)
@export var ready_color: Color = Color(0.35, 0.85, 0.35)
## Bubble and wobble while working (fermenters).
@export var jiggle_while_working: bool = false

var state: State = State.IDLE
## The batch's recipe, or null while the station is free.
var recipe: RecipeDef = null
## What the player makes here by hand: their click on the free station starts
## a batch of it. Dwarves pick their own and never look at this.
var player_recipe: RecipeDef = null

var _hall_storage: Storage
var _ledger: Ledger
var _seconds_left: float = 0.0
## Ingredients dropped in so far for the current batch.
var _stock: Dictionary[ItemDef, int] = {}
## What the batch cooking now was made from, so a cancel hands back exactly
## that (a recipe taking "any crop" doesn't say which).
var _used: Dictionary[ItemDef, int] = {}
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
		if still_needs_for(stack) > 0:
			return false
	return true


## How many more of `item` the batch still needs dropped in.
func still_needs(item: ItemDef) -> int:
	if state != State.LOADING:
		return 0
	var stack: ItemStack = recipe.stack_for(item)
	return still_needs_for(stack) if stack != null else 0


## How many more the batch needs for one of its ingredients. For "any
## crop", whatever crops are in already count.
func still_needs_for(stack: ItemStack) -> int:
	if state != State.LOADING:
		return 0
	var inside: int = 0
	for item: ItemDef in _stock:
		if stack.accepts(item):
			inside += _stock[item]
	return maxi(0, stack.count - inside)


## The floor cell a dwarf stands in to use the station.
func work_cell() -> Vector2i:
	return front_nav_cell()


## Starts a batch of `new_recipe` on the free station. Returns whether it did.
func start_batch(new_recipe: RecipeDef) -> bool:
	if state != State.IDLE:
		return false
	recipe = new_recipe
	state = State.LOADING
	receiver.reset(recipe.load_work)
	_update_bar()
	return true


## Could a batch of `new_recipe` start here now, with everything for it in
## the hall?
func can_start(new_recipe: RecipeDef) -> bool:
	return state == State.IDLE and RecipeChooser.can_make(new_recipe, _hall_storage)


## Stops the batch being loaded or made. Whatever went in goes back to the
## hall, even from a pot already cooking, so nothing is lost. A finished
## batch isn't cancelled, just taken. Returns whether there was one to stop.
func cancel_batch() -> bool:
	match state:
		State.LOADING:
			_return_stock()
		State.PROCESSING:
			for item: ItemDef in _used:
				_hall_storage.add(item, _used[item])
			set_process(false)
			_sprite.scale = Vector2.ONE
		_:
			return false
	_free_up()
	return true


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
		start_batch(recipe_for_input(item))


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
	start_batch(recipe_for_input(mash))
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
		if stack.available_in(_hall_storage) < still_needs_for(stack):
			return false
	return true


## Hands the finished goods to a dwarf or the player. False if no room.
func take_output(carrier: Carrier) -> bool:
	if not has_output() or not carrier.has_room_for(recipe.output, recipe.output_count):
		return false
	carrier.add(recipe.output, recipe.output_count)
	empty_output()
	return true


## The output has gone: the station is free for whoever starts the next batch.
func empty_output() -> void:
	_free_up()


## Puts anything inside (ingredients, finished goods) back into the hall.
## For when the station is taken away.
func return_contents() -> void:
	if has_output():
		_hall_storage.add(recipe.output, recipe.output_count)
		_free_up()
	else:
		cancel_batch()


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


## What the Look tool shows: the station, its recipe, what it's up to,
## what has gone in so far, and who is working it.
func look_lines() -> PackedStringArray:
	var lines: PackedStringArray = [def.display_name]
	if recipe != null:
		lines.append("%s > %d %s" % [recipe.describe_inputs(), recipe.output_count, recipe.output.display_name])
	lines.append(status_text())
	if state == State.LOADING:
		for stack: ItemStack in recipe.inputs:
			lines.append("%d of %s in" % [stack.count - still_needs_for(stack), stack.describe()])
	var worker: Node = receiver.claimed_by
	if worker != null and is_instance_valid(worker) and worker is Dwarf:
		lines.append("Worked by %s" % (worker as Dwarf).dwarf_name)
	if player_recipe != null:
		lines.append("Your pick: %s" % player_recipe.display_name)
	return lines


## What the station is up to, or waiting for, in a few words.
func status_text() -> String:
	match state:
		State.IDLE:
			if is_fed_by_station():
				return "empty, pour in some mash"
			return "empty, click to make %s" % player_recipe.display_name if player_recipe != null else "empty"
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
		var wanted: int = still_needs_for(stack)
		if wanted > stack.available_in(_hall_storage):
			parts.append(stack.describe(wanted))
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
	_used = _stock.duplicate()
	_stock.clear()
	state = State.PROCESSING
	_seconds_left = recipe.process_seconds
	set_process(jiggle_while_working)
	_update_bar()


func _take_missing_from_hall() -> bool:
	for stack: ItemStack in recipe.inputs:
		if stack.available_in(_hall_storage) < still_needs_for(stack):
			return false
	for stack: ItemStack in recipe.inputs:
		var wanted: int = still_needs_for(stack)
		while wanted > 0:
			# "Any crop" may come from several kinds: cheapest first.
			var item: ItemDef = stack.pick_from(_hall_storage)
			var amount: int = mini(wanted, _hall_storage.count(item))
			_hall_storage.remove(item, amount)
			_stock[item] = _stock.get(item, 0) + amount
			wanted -= amount
	return true


func _return_stock() -> void:
	for item: ItemDef in _stock:
		_hall_storage.add(item, _stock[item])
	_stock.clear()


func _free_up() -> void:
	state = State.IDLE
	recipe = null
	receiver.reset(1.0)
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
