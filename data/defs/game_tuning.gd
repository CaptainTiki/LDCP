class_name GameTuning
extends Resource
## Global balance numbers. Everything here is a placeholder meant for tuning.

@export_group("Start")
@export var starting_coins: int = 50
@export var starting_dwarves: int = 3
@export var starting_stock: Array[ItemStack] = []
## Food already in a new dwarf's belly, in seconds of work.
@export var starting_food_seconds: float = 90.0

@export_group("Dwarves")
## Movement speeds in world pixels per second.
@export var walk_speed: float = 24.0
@export var ladder_speed: float = 8.0
@export var lift_speed: float = 64.0
## Work units per second at a 100% drink multiplier with basic tools.
@export var base_work_rate: float = 1.0
@export var carry_capacity: int = 5
@export var eat_seconds: float = 4.0

@export_group("Player")
## Work units applied by one click on a station.
@export var manual_work_per_click: float = 0.5

@export_group("Prices")
@export var hire_cost: int = 40
## Each dwarf hired beyond the starting crew costs this much more.
@export var hire_cost_growth: int = 20
@export var lift_cost: int = 150
