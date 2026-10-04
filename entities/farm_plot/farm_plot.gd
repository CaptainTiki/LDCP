class_name FarmPlot
extends Placeable
## One tile of tilled soil holding one plant. The player sows it, then the
## plant needs watering whenever the soil dries, grows through visible
## stages, and is harvested, leaving the plot empty for the next sowing.
## A dry plant just pauses: nothing the player neglects is ever lost.
##
## Farmers water and harvest. Only the player sows.

enum Task { NONE, WATER, HARVEST }

## Number of growth stages drawn between sown and ripe. The crop's
## growth_frames hold one frame per stage, then the ripe frame.
const GROWTH_STAGES: int = 3

@export var dry_soil: Texture2D
@export var wet_soil: Texture2D

## The crop growing here, or the last one harvested.
var crop: CropDef = null
var growth_seconds: float = 0.0
var watered_seconds_left: float = 0.0

var _is_planted: bool = false
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
	return _is_planted and growth_seconds >= crop.grow_seconds


func sim_tick(delta: float) -> void:
	# Only watered soil grows the plant. Dry soil pauses it.
	if _is_planted and not is_ripe() and watered_seconds_left > 0.0:
		growth_seconds += delta
		watered_seconds_left -= delta
	_sync()


## Sows `new_crop` if the plot is empty. Returns whether it did.
func sow(new_crop: CropDef) -> bool:
	if _is_planted:
		return false
	crop = new_crop
	_is_planted = true
	growth_seconds = 0.0
	_sync()
	return true


## Wets the soil under a growing plant. Returns whether it needed it.
func water() -> bool:
	if not _is_planted or is_ripe():
		return false
	watered_seconds_left = crop.watered_seconds
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


## A line of text for the Look tool.
func describe() -> String:
	if not _is_planted:
		return "Empty plot: sow some seeds"
	if is_ripe():
		return "%s: ripe, ready to harvest" % crop.display_name
	var percent: int = roundi(100.0 * growth_seconds / crop.grow_seconds)
	var soil: String = "watered" if watered_seconds_left > 0.0 else "dry, needs water"
	return "%s: %d%% grown, %s" % [crop.display_name, percent, soil]


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
	return mini(GROWTH_STAGES - 1, floori(GROWTH_STAGES * growth_seconds / crop.grow_seconds))


func _work_for(task: Task) -> float:
	match task:
		Task.WATER:
			return crop.water_work
		Task.HARVEST:
			return crop.harvest_work
	return 1.0
