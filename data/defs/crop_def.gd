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
## What it takes to get these seeds. None: available from the start.
@export var unlock: UnlockDef

@export_group("Farmer work")
@export var water_work: float = 1.0
@export var harvest_work: float = 1.5

@export_group("Growth")
## Seconds of *watered* time a typical plant needs to ripen. Dry time does
## not count.
@export var grow_seconds: float = 45.0
## Each plant ripens up to this fraction faster or slower than grow_seconds
## (0.1 is 10% either way), rolled when it's sown, so a field sown together
## doesn't ripen together.
@export var grow_spread: float = 0.1
## How many times a plant is watered between sowing and ripe. Each watering
## keeps the soil wet for about its share of the growing.
@export var waterings: int = 2
## How far each watering's length strays from an even share (0.2 is 20%
## either way), so plots dry out at different times.
@export var water_spread: float = 0.2
