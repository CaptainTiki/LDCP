class_name UnlockDef
extends Resource
## What it takes to unlock something: first a milestone read from the town's
## Ledger, then a trade. Crops and buildings carry one of these; with none,
## a thing is open from the start.

## The Ledger counter the milestone reads, e.g. "harvested",
## "harvested:barley", "meals_made", "made:stew", "mined".
@export var counter: StringName = &"harvested"
@export var needed: int = 10
## How the milestone reads in the UI, e.g. "Harvest crops".
@export var label: String = ""

@export_group("Trade")
@export var coins: int = 0
## Ore, ingots and the like, taken from the Great Hall. For later unlocks.
@export var items: Array[ItemStack] = []


func describe_price() -> String:
	var parts: PackedStringArray = []
	if coins > 0:
		parts.append("%d coins" % coins)
	for stack: ItemStack in items:
		parts.append("%d %s" % [stack.count, stack.item.display_name])
	return ", ".join(parts) if not parts.is_empty() else "free"
