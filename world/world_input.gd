class_name WorldInput
extends Node
## Turns "the player clicked / dragged / dropped a dwarf at this world
## position" into the right action. The HUD's WorldArea feeds it positions.

## Any click in the world, for the game log's count of player effort.
signal player_clicked

var _world: World
var _tuning: GameTuning
## What the current drag last acted on, so each thing is only hit once.
var _last_dragged: Variant = null


func setup(world: World, tuning: GameTuning) -> void:
	_world = world
	_tuning = tuning


func click(world_point: Vector2) -> void:
	player_clicked.emit()
	var clickable: Clickable = clickable_at(world_point)
	_last_dragged = _drag_target(world_point, clickable)
	if _world.furniture_tool.is_active():
		_world.furniture_tool.click(world_point)
		return
	if _world.build_tool.is_active():
		_world.build_tool.click(world_point, clickable)
		return
	if _world.hand.tool == PlayerHand.Tool.LOOK:
		var dwarf: Dwarf = _world.dwarves.dwarf_at(world_point)
		if dwarf != null:
			_world.hand.inspect_text = dwarf.summary()
			_world.hand.notify_changed()
			return
	var entity: Node = clickable.entity() if clickable != null else null
	if _world.hand.use_on(entity):
		return
	if entity == null:
		return
	if entity is Workstation:
		_world.hand.use_station(entity as Workstation, _tuning.manual_work_per_click)
	elif entity is Building:
		_world.camera.show_interior(entity as Building)
	elif entity is MineEntrance:
		_world.camera.show_mine()
	else:
		# Stations do their own thing with a click: a little manual work.
		clickable.clicked.emit(_tuning.manual_work_per_click)


## The mouse moved with the button held. Lets the player sweep a tool across
## a row of plots, or till or build a row, without clicking each one.
func drag(world_point: Vector2) -> void:
	var clickable: Clickable = clickable_at(world_point)
	var target: Variant = _drag_target(world_point, clickable)
	if target == _last_dragged:
		return
	_last_dragged = target
	if _world.furniture_tool.mode == FurnitureTool.Mode.PLACE:
		_world.furniture_tool.click(world_point)
	elif _world.build_tool.mode == BuildTool.Mode.PLACE:
		_world.build_tool.click(world_point, clickable)
	elif _world.hand.is_holding_tool():
		_world.hand.use_on(clickable.entity() if clickable != null else null)


func hover(world_point: Vector2) -> void:
	_world.build_tool.hover(world_point)
	_world.furniture_tool.hover(world_point)
	_world.dwarves.set_hovered(_world.dwarves.dwarf_at(world_point))


## The cursor left the world (onto a panel, or out of the window).
func hover_ended() -> void:
	_world.dwarves.set_hovered(null)


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


## Building moves from tile to tile, furniture from cell to cell. Farming
## tools, thing to thing.
func _drag_target(world_point: Vector2, clickable: Clickable) -> Variant:
	if _world.furniture_tool.is_active():
		return NavGrid.world_to_cell(world_point)
	if _world.build_tool.is_active():
		return _world.surface.tile_at(world_point)
	return clickable
