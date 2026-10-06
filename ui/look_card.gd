class_name LookCard
extends CursorCard
## The Look tool's pop-up. With the magnifying glass in hand, whatever the
## cursor is over (a station, a plot, a building, a deposit) is described
## beside it. It also carries the hand's reminders: where crops in hand go,
## and what to click to finish a pour. A hovered dwarf has his own card, so
## this one steps aside for it.

var _world: World

@onready var _title: Label = $Column/Title
@onready var _body: Label = $Column/Body


func setup(world: World) -> void:
	_world = world


## Every frame, so countdowns stay fresh.
func _process(_delta: float) -> void:
	var lines: PackedStringArray = current_lines()
	visible = not lines.is_empty()
	if not visible:
		return
	_title.text = lines[0]
	_body.text = "\n".join(lines.slice(1))
	_body.visible = lines.size() > 1
	follow_cursor()


## What the card says right now, title first. Empty when it has nothing to say.
func current_lines() -> PackedStringArray:
	var hand: PlayerHand = _world.hand
	if _world.dwarves.hovered != null:
		return []
	if hand.looked_at != null and is_instance_valid(hand.looked_at):
		return _lines_for(hand.looked_at)
	if hand.pour_target != null:
		var feeder: WorkstationDef = hand.pour_target.station_def().fed_by
		return ["Pouring", "Click a finished %s to pour into the %s" % [feeder.display_name, hand.pour_target.def.display_name]]
	if not hand.carrier.is_empty():
		return ["%d %s in hand" % [hand.carrier.count, hand.carrier.item.display_name], "Click the Great Hall to drop them off"]
	return []


func _lines_for(entity: Node) -> PackedStringArray:
	if entity is FarmPlot:
		return (entity as FarmPlot).look_lines()
	if entity is Workstation:
		return (entity as Workstation).look_lines()
	var lines: PackedStringArray = []
	if entity is OreNode:
		lines.append("%s deposit" % (entity as OreNode).ore.display_name)
	elif entity is Placeable:
		lines.append((entity as Placeable).def.display_name)
	else:
		return lines
	if JobAssignment.kind_for(entity) != JobAssignment.Kind.NONE:
		lines.append(_workers_line(entity))
	if entity is Building:
		lines.append("Click to go inside")
	elif entity is MineEntrance:
		lines.append("Click to go down")
	return lines


func _workers_line(workplace: Node) -> String:
	var names: PackedStringArray = []
	for dwarf: Dwarf in _world.dwarves.active():
		if dwarf.assignment.target == workplace:
			names.append(dwarf.dwarf_name)
	if names.is_empty():
		return "No workers: drop a dwarf on it"
	return "Workers: %s" % ", ".join(names)
