class_name RecipeChooser
extends RefCounted
## What a worker makes at a free station: the best-quality recipe whose
## ingredients are all in the Great Hall. Tools are the exception: nothing
## wears out, so a tool is only made while some dwarf in its job still
## lacks one that good.


## The recipe a worker would start at `station`, or null if nothing is worth
## making right now.
static func best_for(station: Workstation, world: World) -> RecipeDef:
	var best: RecipeDef = null
	for recipe: RecipeDef in station.station_def().recipes:
		if not can_make(recipe, world.hall.storage) or not is_wanted(recipe, world):
			continue
		if best == null or recipe.output.quality > best.output.quality:
			best = recipe
	return best


## Is everything for one batch in `storage`?
static func can_make(recipe: RecipeDef, storage: Storage) -> bool:
	for stack: ItemStack in recipe.inputs:
		if storage.count(stack.item) < stack.count:
			return false
	return true


## Could the station make anything at all from what's in `storage`, wanted
## or not?
static func any_makeable(station: Workstation, storage: Storage) -> bool:
	for recipe: RecipeDef in station.station_def().recipes:
		if can_make(recipe, storage):
			return true
	return false


## Food, drink and metal are always wanted. A tool is wanted while more
## dwarves in its job lack one that good than there are tools waiting in the
## hall or being made.
static func is_wanted(recipe: RecipeDef, world: World) -> bool:
	var tool: ToolDef = recipe.output as ToolDef
	if tool == null:
		return true
	var lacking: int = 0
	for dwarf: Dwarf in world.dwarves.active():
		var has_as_good: bool = dwarf.tool != null and dwarf.tool.work_multiplier >= tool.work_multiplier
		if dwarf.assignment.kind() == tool.job and not has_as_good:
			lacking += 1
	return lacking > world.hall.storage.count(tool) + _being_made(tool, world)


static func _being_made(tool: ToolDef, world: World) -> int:
	var count: int = 0
	for placeable: Placeable in world.surface.placeables():
		var building: Building = placeable as Building
		if building == null:
			continue
		for station: Workstation in building.workstations():
			if not station.is_idle() and station.recipe != null and station.recipe.output == tool:
				count += station.recipe.output_count
	return count
