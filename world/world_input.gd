class_name WorldInput
extends Node
## Turns "the player clicked / dropped a dwarf at this world position" into
## the right action. The HUD's WorldArea feeds it positions.

var _world: World
var _tuning: GameTuning


func setup(world: World, tuning: GameTuning) -> void:
	_world = world
	_tuning = tuning


func click(world_point: Vector2) -> void:
	var clickable: Clickable = clickable_at(world_point)
	if _world.build_tool.is_active():
		_world.build_tool.click(world_point, clickable)
		return
	if clickable == null:
		return
	var entity: Node = clickable.entity()
	if entity is Building:
		_world.camera.show_interior(entity as Building)
	elif entity is MineEntrance:
		_world.camera.show_mine()
	else:
		# Stations do their own thing with a click: a little manual work.
		clickable.clicked.emit(_tuning.manual_work_per_click)


func hover(world_point: Vector2) -> void:
	_world.build_tool.hover(world_point)


## Can a dwarf dropped here be given a job (or sent back to idling)?
func can_assign_at(world_point: Vector2) -> bool:
	var clickable: Clickable = clickable_at(world_point)
	if clickable == null:
		return false
	var entity: Node = clickable.entity()
	return entity is GreatHall or JobAssignment.kind_for(entity) != JobAssignment.Kind.NONE


func assign_at(dwarf: Dwarf, world_point: Vector2) -> void:
	if can_assign_at(world_point):
		dwarf.assignment.assign(clickable_at(world_point).entity())


## The smallest clickable under the point, so a station inside a bigger
## thing wins over the thing around it.
func clickable_at(world_point: Vector2) -> Clickable:
	var best: Clickable = null
	for node: Node in get_tree().get_nodes_in_group(Clickable.GROUP):
		var clickable: Clickable = node as Clickable
		if not clickable.contains(world_point):
			continue
		if best == null or clickable.size.x * clickable.size.y < best.size.x * best.size.y:
			best = clickable
	return best
