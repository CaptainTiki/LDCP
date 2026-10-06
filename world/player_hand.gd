class_name PlayerHand
extends Node
## What the player is holding. The Farming tab hands out the tools:
##   Hoe     roots up a plant, to clear the plot for something else
##   Look    shows what whatever is under the cursor is up to. Any click
##           in the world puts it away
##   Bucket  waters a growing plant
##   Shears  harvests a ripe plant into the player's hands
##   Seeds   sow an empty plot (costs the crop's seed price)
## Harvested crops stay in hand until the player clicks the Great Hall.
## Dwarves never sow: what gets planted is always the player's choice.
##
## With no tool in hand, clicking a station selects it (the room tab shows
## its recipes), loads it a little, or takes its finished goods into hand.
## Clicking an empty fermenter asks for a finished mash pot to pour from.

signal changed

enum Tool { NONE, HOE, LOOK, BUCKET, SHEARS, SEEDS }

var tool: Tool = Tool.NONE
## Which crop the SEEDS tool sows.
var seed_crop: CropDef = null
## What the Look tool is over: a station, plot, building or deposit, or null.
var looked_at: Node = null
## The station whose recipes the room tab shows.
var selected_station: Workstation = null
## An empty station waiting for the player to pick a finished one to pour
## from.
var pour_target: Workstation = null

var _wallet: Wallet

## The crops in hand. The hand holds far more than a dwarf can carry.
@onready var carrier: Carrier = $Carrier


func setup(wallet: Wallet, tuning: GameTuning) -> void:
	_wallet = wallet
	carrier.capacity = tuning.hand_capacity


func select(new_tool: Tool) -> void:
	_set_tool(new_tool)


func select_seeds(crop: CropDef) -> void:
	seed_crop = crop
	_set_tool(Tool.SEEDS)


func put_away() -> void:
	_set_tool(Tool.NONE)


func is_holding_tool() -> bool:
	return tool != Tool.NONE


## Points the Look tool at whatever is under the cursor. Ignored unless the
## Look tool is in hand.
func set_looked_at(entity: Node) -> void:
	looked_at = entity if tool == Tool.LOOK else null


## Something about a station changed that the UI should show.
func notify_changed() -> void:
	changed.emit()


## A click on a station with no tool in hand.
func use_station(station: Workstation, manual_work: float) -> void:
	if pour_target != null and station != pour_target:
		# Second click of a pour: take the mash from this one.
		pour_target.pour_from(station)
		selected_station = pour_target
		pour_target = null
		changed.emit()
		return
	selected_station = station
	pour_target = null
	if station.has_output():
		station.take_output(carrier)
	elif station.can_load_by_hand():
		station.receiver.apply_work(manual_work)
	elif station.is_idle() and station.is_fed_by_station():
		if not station.pour_from_carrier(carrier):
			pour_target = station
	changed.emit()


## Uses whatever is in hand on the thing clicked (null for open ground).
## Returns true if the click was used up.
func use_on(entity: Node) -> bool:
	var used: bool = false
	if entity is GreatHall and not carrier.is_empty():
		carrier.unload_into((entity as GreatHall).storage)
		used = true
	else:
		used = _use_tool(entity)
	if used:
		changed.emit()
	return used


func _use_tool(entity: Node) -> bool:
	var plot: FarmPlot = entity as FarmPlot
	match tool:
		Tool.HOE:
			return plot != null and plot.uproot()
		Tool.SEEDS:
			return plot != null and _sow(plot)
		Tool.BUCKET:
			return plot != null and plot.water()
		Tool.SHEARS:
			return plot != null and _harvest(plot)
	return false


func _sow(plot: FarmPlot) -> bool:
	if plot.is_planted() or not _wallet.can_afford(seed_crop.seed_cost):
		return false
	_wallet.spend(seed_crop.seed_cost)
	return plot.sow(seed_crop)


## One kind of crop in hand at a time, like a dwarf.
func _harvest(plot: FarmPlot) -> bool:
	if not plot.is_ripe() or not carrier.can_take(plot.crop.produce):
		return false
	carrier.add(plot.crop.produce, plot.harvest())
	return true


func _set_tool(new_tool: Tool) -> void:
	tool = new_tool
	looked_at = null
	selected_station = null
	pour_target = null
	changed.emit()
