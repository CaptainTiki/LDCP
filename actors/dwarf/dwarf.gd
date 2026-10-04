class_name Dwarf
extends Node2D
## One dwarf. The behaviour lives in the child components. This script wires
## them together and, each tick, decides which role is in charge: a meal
## break when the food bar is empty, otherwise the assigned job.
##
## Dwarves are pooled: every dwarf already exists in the world scene, hidden,
## and hiring one just activates it.

var world: World
var clock: SimClock
var dwarf_name: String = ""
var color: Color = Color.WHITE
var is_active: bool = false
## Set by the meal break while the dwarf is at a table.
var is_sitting: bool = false
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
@onready var meal_break: MealBreak = $Roles/MealBreak
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
	hunger.sim_tick(delta)
	thirst.sim_tick(delta)
	var role: DwarfRole = _choose_role()
	if role != _active_role:
		if _active_role != null:
			_active_role.release()
		_active_role = role
	role.act(delta)
	mover.sim_tick(delta)


func _process(_delta: float) -> void:
	# Glide between the last two sim positions. A big jump is a door, so snap.
	if mover.previous_position.distance_to(mover.position) > NavGrid.CELL * 4:
		position = mover.position
	else:
		position = mover.previous_position.lerp(mover.position, clock.tick_fraction())


## A short description of what the dwarf is up to, for the roster.
func status_text() -> String:
	if meal_break.is_waiting_for_food:
		return "Waiting for food"
	if meal_break.in_progress:
		return "Meal break"
	return _roles[assignment.kind()].title()


## One-letter job badge for the roster.
func job_badge() -> String:
	if meal_break.is_waiting_for_food:
		return "!"
	return _roles[assignment.kind()].badge()


func _choose_role() -> DwarfRole:
	# A hungry dwarf finishes the job in hand before he downs tools.
	if meal_break.in_progress or (hunger.is_empty() and not worker.is_mid_unit()):
		return meal_break
	return _roles[assignment.kind()]
