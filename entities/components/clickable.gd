class_name Clickable
extends Node2D
## Marks a rectangle of the world the player can click or drop a dwarf on.
## The parent node is the thing being clicked.

## `manual_work` is how much work one player click is worth.
signal clicked(manual_work: float)

const GROUP: StringName = &"clickable"

## Size of the clickable area. This node's position is its top-left corner.
@export var size: Vector2 = Vector2(32, 32)


func _ready() -> void:
	add_to_group(GROUP)


func contains(world_point: Vector2) -> bool:
	return is_visible_in_tree() and Rect2(global_position, size).has_point(world_point)


func entity() -> Node:
	return get_parent()
