class_name PlayerHand
extends Node
## What the player is holding: a farming tool, and any crops just harvested.
## Seeds sow an empty plot, the bucket waters a growing plant, and the
## harvest tool pulls up a ripe one. Harvested crops stay in hand until the
## player clicks the Great Hall to drop them off.

signal changed

enum Tool { NONE, SEEDS, BUCKET, HARVEST }

var tool: Tool = Tool.NONE
## Which crop the SEEDS tool sows.
var seed_crop: CropDef = null

## The crops in hand. The hand holds far more than a dwarf can carry.
@onready var carrier: Carrier = $Carrier


func select_seeds(crop: CropDef) -> void:
	seed_crop = crop
	_set_tool(Tool.SEEDS)


func select_bucket() -> void:
	_set_tool(Tool.BUCKET)


func select_harvest() -> void:
	_set_tool(Tool.HARVEST)


func put_away() -> void:
	_set_tool(Tool.NONE)


func is_holding_tool() -> bool:
	return tool != Tool.NONE


## Uses whatever is in hand on the thing that was clicked.
## Returns true if the click was used up.
func use_on(entity: Node) -> bool:
	var used: bool = false
	if entity is GreatHall and not carrier.is_empty():
		carrier.unload_into((entity as GreatHall).storage)
		used = true
	elif entity is FarmPlot:
		used = _use_on_plot(entity as FarmPlot)
	if used:
		changed.emit()
	return used


func _use_on_plot(plot: FarmPlot) -> bool:
	match tool:
		Tool.SEEDS:
			return plot.sow(seed_crop)
		Tool.BUCKET:
			return plot.water()
		Tool.HARVEST:
			# One kind of crop in hand at a time, like a dwarf.
			if plot.is_ripe() and carrier.can_take(plot.crop.produce):
				carrier.add(plot.crop.produce, plot.harvest())
				return true
	return false


func _set_tool(new_tool: Tool) -> void:
	tool = new_tool
	changed.emit()
