class_name FarmPlot
extends Placeable
## One tile of tilled soil holding one plant. The plant is sown, watered
## whenever the soil dries, grows through visible stages, and is harvested.
## Then the plot is sown again. A dry plant just pauses: nothing the player
## neglects is ever lost.
##
## The plot remembers the last crop sown in it. That is how farmers know
## what to replant: the player chooses the crop once, by sowing it.

enum Task { NONE, PLANT, WATER, HARVEST }

## Number of growth stages drawn between sown and ripe.
const GROWTH_STAGES: int = 3
## Size of the leaves at each growth stage, then when ripe.
const LEAF_SIZES: Array[Vector2] = [Vector2(4, 2), Vector2(6, 4), Vector2(9, 6), Vector2(12, 8)]
## Local position of the point the plant grows up from.
const PLANT_BASE: Vector2 = Vector2(8, -4)

## The crop this plot grows. Null until something has been sown here.
@export var crop: CropDef
@export var dry_soil_color: Color = Color(0.5, 0.36, 0.22)
@export var wet_soil_color: Color = Color(0.3, 0.2, 0.13)

var growth_seconds: float = 0.0
var watered_seconds_left: float = 0.0

var _is_planted: bool = false
## The task the work receiver is currently set up for.
var _receiver_task: Task = Task.NONE

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _soil: ColorRect = $Soil
@onready var _leaves: ColorRect = $Leaves
@onready var _produce: ColorRect = $Produce


func _ready() -> void:
	receiver.completed.connect(_on_work_completed)
	_sync()


## What the plot needs a farmer to do right now, if anything.
func current_task() -> Task:
	if not _is_planted:
		# Farmers only sow plots the player has chosen a crop for.
		return Task.PLANT if crop != null else Task.NONE
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
	return crop.yield_count


## A farmer finished the job the receiver was set up for.
func _on_work_completed(worker: Node) -> void:
	match _receiver_task:
		Task.PLANT:
			sow(crop)
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
	_soil.color = wet_soil_color if watered_seconds_left > 0.0 else dry_soil_color
	_leaves.visible = _is_planted
	_produce.visible = is_ripe()
	if not _is_planted:
		return
	var leaf_size: Vector2 = LEAF_SIZES[_growth_stage()]
	_leaves.size = leaf_size
	_leaves.position = PLANT_BASE - Vector2(leaf_size.x * 0.5, leaf_size.y)
	_leaves.color = crop.color
	_produce.color = crop.produce.color


## 0 when just sown, rising to GROWTH_STAGES when ripe.
func _growth_stage() -> int:
	if is_ripe():
		return GROWTH_STAGES
	return mini(GROWTH_STAGES - 1, floori(GROWTH_STAGES * growth_seconds / crop.grow_seconds))


func _work_for(task: Task) -> float:
	match task:
		Task.PLANT:
			return crop.plant_work
		Task.WATER:
			return crop.water_work
		Task.HARVEST:
			return crop.harvest_work
	return 1.0
