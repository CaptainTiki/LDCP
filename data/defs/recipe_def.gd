class_name RecipeDef
extends Resource
## One thing a station can make: what goes in, what comes out, how much work
## it takes to load, and how long the station then runs on its own.
## A dwarf brings each kind of ingredient on its own trip.

@export var id: StringName
@export var display_name: String = ""
## One or two kinds of ingredient, with how many of each. A stack can take
## any item of a category ("1 any crop").
@export var inputs: Array[ItemStack] = []
@export var output: ItemDef
@export var output_count: int = 1
## Work to load the station: a dozen clicks for the player, a few seconds
## for a dwarf.
@export var load_work: float = 5.0
## Seconds the station then runs unattended.
@export var process_seconds: float = 60.0


## The ingredient `item` would count as, or null if it isn't one.
func stack_for(item: ItemDef) -> ItemStack:
	for stack: ItemStack in inputs:
		if stack.accepts(item):
			return stack
	return null


## How many of `item` one batch takes (0 if it isn't an ingredient).
func needs(item: ItemDef) -> int:
	var stack: ItemStack = stack_for(item)
	return stack.count if stack != null else 0


func describe_inputs() -> String:
	var parts: PackedStringArray = []
	for stack: ItemStack in inputs:
		parts.append(stack.describe())
	return " + ".join(parts)
