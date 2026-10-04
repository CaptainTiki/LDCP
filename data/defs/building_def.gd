class_name BuildingDef
extends Resource
## Something that occupies slots on the surface: a building or a farm plot.

@export var id: StringName
@export var display_name: String = ""
## Scene instanced when placed. Its root is a Placeable.
@export var scene: PackedScene
## Width and height in surface slots. Only the width reserves slots.
@export var footprint: Vector2i = Vector2i.ONE
@export var cost: int = 0
## One-off coin price to unlock this in the build menu. 0 = always available.
@export var unlock_cost: int = 0
## Shown in the build menu. Pre-placed one-offs (hall, mine entrance) are not.
@export var buildable: bool = true
@export var can_move: bool = true
@export var can_destroy: bool = true
## Where the door sits, in nav cells from the building's left edge.
@export var door_offset_cells: int = 1
## Workstations that may be bought for this building's interior slots.
@export var workstations: Array[WorkstationDef] = []
