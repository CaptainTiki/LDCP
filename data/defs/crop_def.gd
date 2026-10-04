class_name CropDef
extends Resource
## A plantable crop: how much work each farming step takes a dwarf, how long
## one plant takes to ripen, and what it yields.

@export var id: StringName
@export var display_name: String = ""
@export var produce: ItemDef
@export var yield_count: int = 3
@export var color: Color = Color.GREEN

@export_group("Work")
@export var plant_work: float = 2.0
@export var water_work: float = 2.0
@export var harvest_work: float = 3.0

@export_group("Growth")
## Seconds of *watered* time needed to ripen. Dry time does not count.
@export var grow_seconds: float = 45.0
## How long one watering lasts before the soil dries out again.
@export var watered_seconds: float = 30.0
