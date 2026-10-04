class_name BuildingDef
extends Resource
## Something that occupies slots on the surface: a building or a farm plot.

@export var id: StringName
@export var display_name: String = ""
## Scene instanced when placed. Its root is a Placeable.
@export var scene: PackedScene
## Width and height in surface tiles, seen from above.
@export var footprint: Vector2i = Vector2i.ONE
@export var cost: int = 0
## What it takes to be allowed to build this. None: available from the start.
@export var unlock: UnlockDef
## Shown in the build menu. Pre-placed one-offs (hall, mine entrance) are not.
@export var buildable: bool = true
@export var can_move: bool = true
@export var can_destroy: bool = true
## Dwarves walk around this. Farm plots turn it off: they are walked on.
@export var blocks_walking: bool = true
## Where the door sits along the front (bottom) wall, in nav cells from the
## building's left edge.
@export var door_offset_cells: int = 1
## Workstations that may be bought for this building's interior slots.
@export var workstations: Array[WorkstationDef] = []
