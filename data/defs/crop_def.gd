class_name CropDef
extends Resource
## A plantable crop: what a seed costs, how long one plant takes to ripen,
## how much farmer work each step takes, and what it yields.

@export var id: StringName
@export var display_name: String = ""
@export var produce: ItemDef
@export var yield_count: int = 2
@export var color: Color = Color.GREEN
## Four frames side by side: three growth stages, then ripe.
@export var growth_frames: Texture2D
## Coins per seed. The player pays this every time they sow.
@export var seed_cost: int = 1

@export_group("Farmer work")
@export var water_work: float = 1.0
@export var harvest_work: float = 1.5

@export_group("Growth")
## Seconds of *watered* time needed to ripen. Dry time does not count.
@export var grow_seconds: float = 45.0
## How long one watering lasts before the soil dries out again.
@export var watered_seconds: float = 30.0
