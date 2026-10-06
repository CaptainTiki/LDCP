class_name FarmPlot
extends Placeable
## One tile of tilled soil holding one plant. The player sows it, then the
## plant needs watering whenever the soil dries, grows through visible
## stages, and is harvested, leaving the plot empty for the next sowing.
## A dry plant just pauses: nothing the player neglects is ever lost.
##
## Each plant rolls its own grow time and each watering its own length, so
## a field sown together ripens and dries out unevenly, like a real one.
##
## Farmers water and harvest. Only the player sows.

enum Task { NONE, WATER, HARVEST }

## Number of growth stages drawn between sown and ripe. The crop's
## growth_frames hold one frame per stage, then the ripe frame.
const GROWTH_STAGES: int = 3
## The last watering lasts at least this long past ripe, so rounding in the
## sim can never leave a plant a hair short of ripe on dry soil.
const LAST_WATERING_SLACK_SECONDS: float = 1.0

@export var dry_soil: Texture2D
@export var wet_soil: Texture2D

## The crop growing here, or the last one harvested.
var crop: CropDef = null
var growth_seconds: float = 0.0
var watered_seconds_left: float = 0.0

var _is_planted: bool = false
## Watered seconds this plant needs to ripen, rolled when it was sown.
var _ripe_seconds: float = 0.0
## Waterings this plant still needs, counting the one in the soil now as done.
var _waterings_left: int = 0
## The task the work receiver is currently set up for.
var _receiver_task: Task = Task.NONE

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _soil: Sprite2D = $Soil
@onready var _plant: Sprite2D = $Plant


func _ready() -> void:
	receiver.completed.connect(_on_work_completed)
	_sync()


## What the plot needs a farmer to do right now, if anything.
func current_task() -> Task:
	if not _is_planted:
		return Task.NONE
	if is_ripe():
		return Task.HARVEST
	if watered_seconds_left <= 0.0:
		return Task.WATER
	return Task.NONE


func is_planted() -> bool:
	return _is_planted


func is_ripe() -> bool:
	return _is_planted and growth_seconds >= _ripe_seconds


## Watered seconds this plant needs to ripen: its crop's grow time, give or
## take the crop's spread.
func ripe_seconds() -> float:
	return _ripe_seconds


func sim_tick(delta: float) -> void:
	# Wet soil dries whatever is in it, and only wet soil grows the plant.
	# Dry soil pauses it.
	if watered_seconds_left > 0.0:
		if _is_planted and not is_ripe():
			growth_seconds += delta
		watered_seconds_left = maxf(0.0, watered_seconds_left - delta)
	_sync()


## Sows `new_crop` if the plot is empty. Returns whether it did.
func sow(new_crop: CropDef) -> bool:
	if _is_planted:
		return false
	crop = new_crop
	_is_planted = true
	growth_seconds = 0.0
	_ripe_seconds = crop.grow_seconds * randf_range(1.0 - crop.grow_spread, 1.0 + crop.grow_spread)
	_waterings_left = crop.waterings
	_sync()
	return true


## Wets dry soil under a growing plant. Returns whether it needed it.
func water() -> bool:
	if not _is_planted or is_ripe() or watered_seconds_left > 0.0:
		return false
	watered_seconds_left = _next_watering_seconds()
	_waterings_left = maxi(0, _waterings_left - 1)
	_sync()
	return true


## Pulls up a ripe plant and returns what it yielded, or 0 if not ripe.
## The caller decides where the produce goes.
func harvest() -> int:
	if not is_ripe():
		return 0
	_is_planted = false
	growth_seconds = 0.0
	_sync()
	world.ledger.record_harvest(crop.produce, crop.yield_count)
	return crop.yield_count


## Roots up whatever is growing, ripe or not, and throws it away. For
## clearing a slow crop to make room for another. Returns whether it did.
func uproot() -> bool:
	if not _is_planted:
		return false
	_is_planted = false
	growth_seconds = 0.0
	_sync()
	return true


## What the Look tool shows: the crop, how far along it is, and its soil.
func look_lines() -> PackedStringArray:
	if not _is_planted:
		return ["Empty plot", "Sow some seeds"]
	if is_ripe():
		return [crop.display_name, "Ripe, ready to harvest"]
	var percent: int = roundi(100.0 * growth_seconds / _ripe_seconds)
	var lines: PackedStringArray = [crop.display_name,
			"%d%% grown, %ds to go" % [percent, ceili(_ripe_seconds - growth_seconds)]]
	if watered_seconds_left > 0.0:
		lines.append("Wet for %ds" % ceili(watered_seconds_left))
	else:
		lines.append("Dry, needs water")
	match _waterings_left:
		0:
			lines.append("Last watering")
		1:
			lines.append("1 more watering")
		_:
			lines.append("%d more waterings" % _waterings_left)
	return lines


## A farmer finished the job the receiver was set up for.
func _on_work_completed(worker: Node) -> void:
	match _receiver_task:
		Task.WATER:
			water()
		Task.HARVEST:
			Payout.give(crop.produce, harvest(), worker, world.hall.storage)


## Points the work receiver at the current task and refreshes the visuals.
func _sync() -> void:
	var task: Task = current_task()
	if task != _receiver_task:
		_receiver_task = task
		receiver.reset(_work_for(task))
	_soil.texture = wet_soil if watered_seconds_left > 0.0 else dry_soil
	_plant.visible = _is_planted
	if _is_planted:
		_plant.texture = crop.growth_frames
		_plant.frame = _growth_stage()


## 0 when just sown, rising to GROWTH_STAGES when ripe.
func _growth_stage() -> int:
	if is_ripe():
		return GROWTH_STAGES
	return mini(GROWTH_STAGES - 1, floori(GROWTH_STAGES * growth_seconds / _ripe_seconds))


## How long a watering keeps the soil wet: an even share of the growing still
## to do, give or take the crop's spread. The last one always lasts until the
## plant is ripe, so every plant takes exactly its crop's waterings.
func _next_watering_seconds() -> float:
	var still_to_grow: float = _ripe_seconds - growth_seconds
	var share: float = still_to_grow / maxi(1, _waterings_left)
	var seconds: float = share * randf_range(1.0 - crop.water_spread, 1.0 + crop.water_spread)
	if _waterings_left <= 1:
		seconds = maxf(seconds, still_to_grow + LAST_WATERING_SLACK_SECONDS)
	return seconds


func _work_for(task: Task) -> float:
	match task:
		Task.WATER:
			return crop.water_work
		Task.HARVEST:
			return crop.harvest_work
	return 1.0
