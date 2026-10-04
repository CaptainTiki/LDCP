class_name PlayerHand
extends Node
## What the player is holding. The Farming tab hands out the tools:
##   Hoe     roots up a plant, to clear the plot for something else
##   Look    inspects whatever is clicked
##   Bucket  waters a growing plant
##   Shears  harvests a ripe plant into the player's hands
##   Seeds   sow an empty plot (costs the crop's seed price)
## Harvested crops stay in hand until the player clicks the Great Hall.
## Dwarves never sow: what gets planted is always the player's choice.

signal changed

enum Tool { NONE, HOE, LOOK, BUCKET, SHEARS, SEEDS }

var tool: Tool = Tool.NONE
## Which crop the SEEDS tool sows.
var seed_crop: CropDef = null
## What the Look tool last saw.
var inspect_text: String = ""

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
		Tool.LOOK:
			inspect_text = _describe(entity)
			return entity != null
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


func _describe(entity: Node) -> String:
	if entity is FarmPlot:
		return (entity as FarmPlot).describe()
	if entity is Workstation:
		return (entity as Workstation).describe()
	if entity is OreNode:
		return "%s deposit" % (entity as OreNode).ore.display_name
	if entity is Placeable:
		return (entity as Placeable).def.display_name
	return ""


func _set_tool(new_tool: Tool) -> void:
	tool = new_tool
	inspect_text = ""
	changed.emit()
