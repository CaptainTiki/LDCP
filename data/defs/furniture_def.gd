class_name FurnitureDef
extends Resource
## Something that stands on a room's floor: a table, a chair, a stove.

@export var id: StringName
@export var display_name: String = ""
## Scene instanced when placed. Its root is a Furniture.
@export var scene: PackedScene
## Shown in the room tab.
@export var icon: Texture2D
## Size in nav cells (8px), seen from above, before any turning.
@export var footprint: Vector2i = Vector2i.ONE
@export var cost: int = 5
## Dwarves walk around this. Chairs turn it off: they are sat on.
@export var blocks_walking: bool = true
## A dwarf can sit here to eat.
@export var is_seat: bool = false
## A dwarf works this from the cell in front of it, which must stay clear.
## "In front" is below the sprite as drawn, and turns with it.
@export var needs_front_access: bool = false
