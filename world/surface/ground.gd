class_name Ground
extends Node2D
## The town's grass, drawn one tile at a time. Each tile picks a variant from
## a hash of its position, so the field never looks stamped and comes out the
## same every run. Drawn once: Godot keeps the result until it changes.

## A row of 16x16 grass tiles. The first `plain_variants` are plain grass;
## the rest (tufts, flowers, stones) are sprinkled in.
@export var tiles: Texture2D
@export var plain_variants: int = 2
## Share of tiles that get a decorated variant, 0..100.
@export_range(0, 100) var decorated_percent: int = 15

## Set by the Surface. Grass extends one tile past every edge of town.
var size_tiles: Vector2i = Vector2i.ZERO


func _draw() -> void:
	var tile_px: int = Placeable.TILE_PIXELS
	var variants: int = tiles.get_width() / tile_px
	for y: int in range(-1, size_tiles.y + 1):
		for x: int in range(-1, size_tiles.x + 1):
			var variant: int = _variant(Vector2i(x, y), variants)
			draw_texture_rect_region(tiles, Rect2(x * tile_px, y * tile_px, tile_px, tile_px),
					Rect2(variant * tile_px, 0, tile_px, tile_px))


func _variant(tile: Vector2i, variants: int) -> int:
	var roll: int = absi(hash(tile))
	if roll % 100 >= decorated_percent:
		return (roll / 100) % plain_variants
	return plain_variants + (roll / 100) % (variants - plain_variants)
