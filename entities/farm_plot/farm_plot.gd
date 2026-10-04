class_name FarmPlot
extends Placeable
## A patch of soil that grows one crop over and over. It needs planting,
## watering whenever the soil dries, and harvesting. A dry crop just pauses:
## nothing the player neglects is ever lost.

enum Task { NONE, PLANT, WATER, HARVEST }

const MAX_CROP_HEIGHT: float = 20.0
## Local y of the bottom edge of the crop visual.
const CROP_BASE_Y: float = -6.0

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
@onready var _crop_visual: ColorRect = $Crop
@onready var _clickable: Clickable = $Clickable


func _ready() -> void:
	receiver.completed.connect(_on_work_completed)
	_clickable.clicked.connect(_on_clicked)
	_crop_visual.color = crop.color
	_sync()


## What the plot needs done right now, if anything.
func current_task() -> Task:
	if not _is_planted:
		return Task.PLANT
	if is_ripe():
		return Task.HARVEST
	if watered_seconds_left <= 0.0:
		return Task.WATER
	return Task.NONE


func is_ripe() -> bool:
	return _is_planted and growth_seconds >= crop.grow_seconds


func sim_tick(delta: float) -> void:
	# Only watered soil grows the crop. Dry soil pauses it.
	if _is_planted and not is_ripe() and watered_seconds_left > 0.0:
		growth_seconds += delta
		watered_seconds_left -= delta
	_sync()


## Points the work receiver at the current task and refreshes the visuals.
func _sync() -> void:
	var task: Task = current_task()
	if task != _receiver_task:
		_receiver_task = task
		receiver.reset(_work_for(task))
	_soil.color = wet_soil_color if watered_seconds_left > 0.0 else dry_soil_color
	var height: float = 0.0
	if _is_planted:
		height = maxf(2.0, MAX_CROP_HEIGHT * growth_seconds / crop.grow_seconds)
	_crop_visual.size.y = minf(height, MAX_CROP_HEIGHT)
	_crop_visual.position.y = CROP_BASE_Y - _crop_visual.size.y
	_crop_visual.color = crop.color.lightened(0.3) if is_ripe() else crop.color


func _work_for(task: Task) -> float:
	match task:
		Task.PLANT:
			return crop.plant_work
		Task.WATER:
			return crop.water_work
		Task.HARVEST:
			return crop.harvest_work
	return 1.0


func _on_work_completed(worker: Node) -> void:
	match _receiver_task:
		Task.PLANT:
			_is_planted = true
		Task.WATER:
			watered_seconds_left = crop.watered_seconds
		Task.HARVEST:
			Payout.give(crop.produce, crop.yield_count, worker, world.hall.storage)
			_is_planted = false
			growth_seconds = 0.0
	_sync()


func _on_clicked(manual_work: float) -> void:
	if current_task() != Task.NONE:
		receiver.apply_work(manual_work)
