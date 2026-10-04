class_name JobAssignment
extends Node
## What the player told this dwarf to do. The player picks a target, and the
## kind of target decides the job. The dwarf's roles pick their own tasks.

enum Kind { NONE, FARMER, STATION, MINER }

var target: Node = null


## The job a drop on `entity` would give, or NONE if it is not a workplace.
static func kind_for(entity: Node) -> Kind:
	if entity is FarmPlot:
		return Kind.FARMER
	if entity is MineEntrance:
		return Kind.MINER
	if entity is OreNode:
		return Kind.MINER if (entity as OreNode).revealed else Kind.NONE
	# The Great Hall is a building but not a workplace: dropping a dwarf
	# there sends him back to idling.
	if entity is Building and not entity is GreatHall:
		return Kind.STATION
	return Kind.NONE


func assign(new_target: Node) -> void:
	target = new_target


func kind() -> Kind:
	if target == null:
		return Kind.NONE
	# The thing we were assigned to may have been destroyed since.
	if not is_instance_valid(target) or not target.is_inside_tree():
		target = null
		return Kind.NONE
	return kind_for(target)
