class_name Dwarf
extends Node2D
## One dwarf. The behaviour lives in the child components. This script wires
## them together and, each tick, decides which role is in charge: a meal
## break when the food bar is empty, otherwise the assigned job. A job with
## nothing at all for him has him potter about near his workplace (Idler).
##
## Dwarves are pooled: every dwarf already exists in the world scene, hidden,
## and hiring one just activates it.

## Where his sprite is drawn, relative to his feet. For hovering and clicks.
const BODY_RECT: Rect2 = Rect2(-6, -17, 12, 18)

var world: World
var clock: SimClock
var dwarf_name: String = ""
var color: Color = Color.WHITE
var is_active: bool = false
## The one tool he carries, or null for his bare old pick.
var tool: ToolDef = null
## Reserved for the trait and experience systems.
var traits: Array[StringName] = []
var experience: float = 0.0

var _active_role: DwarfRole = null

@onready var hunger: Hunger = $Hunger
@onready var thirst: Thirst = $Thirst
@onready var carrier: Carrier = $Carrier
@onready var mover: GridMover = $Mover
@onready var worker: Worker = $Worker
@onready var assignment: JobAssignment = $JobAssignment
@onready var idler: Idler = $Idler
@onready var meal_break: MealBreak = $Roles/MealBreak
@onready var tool_errand: ToolErrand = $Roles/ToolErrand
@onready var _roles: Dictionary[JobAssignment.Kind, DwarfRole] = {
	JobAssignment.Kind.NONE: $Roles/Idle as DwarfRole,
	JobAssignment.Kind.FARMER: $Roles/Farmer as DwarfRole,
	JobAssignment.Kind.STATION: $Roles/StationWorker as DwarfRole,
	JobAssignment.Kind.MINER: $Roles/Miner as DwarfRole,
}


func _ready() -> void:
	visible = false
	set_process(false)
	worker.setup(thirst)
	for role: Node in $Roles.get_children():
		(role as DwarfRole).dwarf = self


func setup(in_world: World, tuning: GameTuning, sim_clock: SimClock) -> void:
	world = in_world
	clock = sim_clock
	mover.nav = world.nav
	mover.walk_speed = tuning.walk_speed
	mover.ladder_speed = tuning.ladder_speed
	mover.lift_speed = tuning.lift_speed
	worker.base_rate = tuning.base_work_rate
	carrier.capacity = tuning.carry_capacity
	meal_break.eat_seconds = tuning.eat_seconds


## Brings a pooled dwarf into the game at `cell`.
func activate(cell: Vector2i, given_name: String, given_color: Color, food_seconds: float) -> void:
	dwarf_name = given_name
	color = given_color
	hunger.fill(food_seconds)
	mover.place_at(cell)
	position = mover.position
	is_active = true
	visible = true
	set_process(true)


func sim_tick(delta: float) -> void:
	worker.begin_tick()
	idler.begin_tick()
	worker.tool_multiplier = tool.work_multiplier if tool != null and tool.job == assignment.kind() else 1.0
	var role: DwarfRole = _choose_role()
	if role != _active_role:
		if _active_role != null:
			_active_role.release()
		_active_role = role
	role.act(delta)
	idler.end_tick()
	# Food and drink are only used up by work. Walking, climbing, hauling
	# and idling are free, so a long commute costs time but not the shift.
	if worker.did_work_this_tick():
		hunger.sim_tick(delta)
		thirst.sim_tick(delta)
	mover.sim_tick(delta)


func _process(_delta: float) -> void:
	# Glide between the last two sim positions. A big jump is a door, so snap.
	if mover.previous_position.distance_to(mover.position) > NavGrid.CELL * 4:
		position = mover.position
	else:
		position = mover.previous_position.lerp(mover.position, clock.tick_fraction())


## At the hall: make sure he holds the best tool for his current job. A tool
## for some other job (he's been reassigned) goes back on the shelf for
## someone who can use it, even if there's nothing better to take instead.
func equip_best_tool(storage: Storage) -> void:
	var job: JobAssignment.Kind = assignment.kind()
	var best: ToolDef = tool if tool != null and tool.job == job else null
	for item: ItemDef in storage.items():
		var candidate: ToolDef = item as ToolDef
		if candidate == null or candidate.job != job:
			continue
		if best == null or candidate.work_multiplier > best.work_multiplier:
			best = candidate
	if best == tool:
		return
	if tool != null:
		storage.add(tool, 1)
	if best != null:
		storage.remove(best, 1)
	tool = best


## In a chair at the hall, eating or waiting for food.
func is_sitting() -> bool:
	return meal_break.is_seated


## One line for the Look tool.
func summary() -> String:
	return "%s: %s" % [dwarf_name, status_text()]


## A short description of what the dwarf is up to, for the roster.
func status_text() -> String:
	if meal_break.is_waiting_for_food:
		return "Waiting for food"
	if meal_break.is_waiting_for_seat:
		return "Waiting for a seat"
	if meal_break.in_progress:
		return "Meal break"
	if _active_role == tool_errand:
		return tool_errand.title()
	if idler.is_idle():
		return idler.reason
	return _roles[assignment.kind()].title()


## The job he's been given, whatever he's doing right now.
func job_title() -> String:
	return _roles[assignment.kind()].title()


## One-letter job badge for the roster.
func job_badge() -> String:
	if meal_break.is_waiting_for_food or meal_break.is_waiting_for_seat:
		return "!"
	if _active_role == tool_errand:
		return tool_errand.badge()
	if idler.is_idle():
		return "?"
	return _roles[assignment.kind()].badge()


func _choose_role() -> DwarfRole:
	# Already heading in to eat: he'll sort his tools out at the hall anyway.
	if meal_break.in_progress:
		return meal_break
	# The wrong tool for the job goes back before anything else.
	if tool_errand.is_needed():
		return tool_errand
	# A hungry dwarf finishes the job in hand before he downs tools.
	if hunger.is_empty() and not worker.is_mid_unit():
		return meal_break
	return _roles[assignment.kind()]
