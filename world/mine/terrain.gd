class_name Terrain
extends Node2D
## Everything below the ground line, as a grid of small cells. Row 0 is the
## first row under the surface. Mine levels fill their region with diggable
## ground, and everything else stays bedrock.
##
## The terrain keeps the NavGrid in step: whenever a cell changes, it works
## out afresh which nearby cells a dwarf can stand in.

signal cell_opened(cell: Vector2i)

enum Cell { AIR, DIRT, ROCK, BEDROCK, ORE }

@export var size_cells: Vector2i = Vector2i(256, 48)

@export_group("Greybox colours")
@export var air_color: Color = Color(0.13, 0.1, 0.09)
@export var dirt_color: Color = Color(0.45, 0.32, 0.2)
@export var rock_color: Color = Color(0.42, 0.42, 0.46)
@export var bedrock_color: Color = Color(0.27, 0.21, 0.17)
@export var plank_color: Color = Color(0.72, 0.55, 0.3)

var _nav: NavGrid
var _cells: PackedByteArray = PackedByteArray()
## Planks are thin floors: a dwarf can stand on one with open air beneath.
var _planks: Dictionary[Vector2i, bool] = {}
var _image: Image
var _texture: ImageTexture
var _image_dirty: bool = false

@onready var _sprite: Sprite2D = $Sprite


func setup(nav: NavGrid) -> void:
	_nav = nav
	_cells.resize(size_cells.x * size_cells.y)
	_cells.fill(Cell.BEDROCK)
	# One pixel per cell, scaled up by the sprite. Cheap to update per dig.
	_image = Image.create_empty(size_cells.x, size_cells.y, false, Image.FORMAT_RGBA8)
	for y: int in size_cells.y:
		for x: int in size_cells.x:
			_paint(Vector2i(x, y))
	_texture = ImageTexture.create_from_image(_image)
	_sprite.texture = _texture


func _process(_delta: float) -> void:
	if _image_dirty:
		_texture.update(_image)
		_image_dirty = false


func _draw() -> void:
	for cell: Vector2i in _planks:
		var top_left := Vector2(cell.x * NavGrid.CELL, (cell.y + 1) * NavGrid.CELL - 2)
		draw_rect(Rect2(top_left, Vector2(NavGrid.CELL, 2)), plank_color)


func get_cell(cell: Vector2i) -> Cell:
	if cell.y < 0:
		return Cell.AIR  # Above the ground line is open sky.
	if cell.x < 0 or cell.x >= size_cells.x or cell.y >= size_cells.y:
		return Cell.BEDROCK
	return _cells[cell.y * size_cells.x + cell.x] as Cell


func set_cell(cell: Vector2i, type: Cell) -> void:
	if cell.y < 0 or cell.x < 0 or cell.x >= size_cells.x or cell.y >= size_cells.y:
		return
	_cells[cell.y * size_cells.x + cell.x] = type
	_paint(cell)
	_refresh_nav_around(cell)


func is_open(cell: Vector2i) -> bool:
	return get_cell(cell) == Cell.AIR


func is_diggable(cell: Vector2i) -> bool:
	var type: Cell = get_cell(cell)
	return type == Cell.DIRT or type == Cell.ROCK


## Clears a cell and tells listeners (ore nodes waiting to be found).
func dig(cell: Vector2i) -> void:
	set_cell(cell, Cell.AIR)
	cell_opened.emit(cell)


func add_plank(cell: Vector2i) -> void:
	_planks[cell] = true
	_refresh_nav_around(cell)
	queue_redraw()


func has_plank(cell: Vector2i) -> bool:
	return _planks.has(cell)


## A dwarf is two cells tall: he needs his own cell and the one above open,
## and something to stand on.
func is_standable(cell: Vector2i) -> bool:
	if not is_open(cell) or not is_open(cell + Vector2i.UP):
		return false
	return not is_open(cell + Vector2i.DOWN) or has_plank(cell)


func _refresh_nav_around(changed: Vector2i) -> void:
	for dy: int in [-1, 0, 1]:
		var cell: Vector2i = changed + Vector2i(0, dy)
		# The surface row and the shaft ladder look after their own cells.
		if cell.y < 0 or _nav.is_climbable(cell):
			continue
		if is_standable(cell):
			_nav.set_walkable(cell)
		else:
			_nav.clear_walkable(cell)


func _paint(cell: Vector2i) -> void:
	var base: Color
	match get_cell(cell):
		Cell.AIR:
			base = air_color
		Cell.DIRT:
			base = dirt_color
		Cell.BEDROCK:
			base = bedrock_color
		_:
			base = rock_color  # Hidden ore looks like rock until it is found.
	# A little per-cell variation so the ground reads as texture, not a slab.
	var shade: float = float(hash(cell) % 100) / 100.0 * 0.12
	_image.set_pixelv(cell, base.darkened(shade))
	_image_dirty = true
