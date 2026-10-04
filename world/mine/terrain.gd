class_name Terrain
extends Node2D
## Everything below the ground line, as a grid of small cells. Row 0 is the
## first row under the surface. Mine levels fill their region with diggable
## ground, and everything else stays bedrock.
##
## The terrain keeps the NavGrid in step: whenever a cell changes, it works
## out afresh which nearby cells a dwarf can stand in. It also keeps the
## Tiles layer in step, so what you see is always what's there.

signal cell_opened(cell: Vector2i)

enum Cell { AIR, DIRT, ROCK, BEDROCK, ORE }

## Where each kind of cell's tiles sit in the tile set's single atlas row:
## [first tile, number of variants]. See make_world_art.py.
const TILES: Dictionary[Cell, Vector2i] = {
	Cell.DIRT: Vector2i(0, 3),
	Cell.ROCK: Vector2i(3, 3),
	Cell.BEDROCK: Vector2i(6, 2),
	Cell.AIR: Vector2i(8, 2),
}
## Dug-out back wall in the shadow of the ceiling right above it.
const AIR_SHADOW_TILE: int = 10

@export var size_cells: Vector2i = Vector2i(256, 48)
@export var plank_texture: Texture2D

var _nav: NavGrid
var _cells: PackedByteArray = PackedByteArray()
## Planks are thin floors: a dwarf can stand on one with open air beneath.
var _planks: Dictionary[Vector2i, bool] = {}

@onready var _tiles: TileMapLayer = $Tiles


func setup(nav: NavGrid) -> void:
	_nav = nav
	_cells.resize(size_cells.x * size_cells.y)
	_cells.fill(Cell.BEDROCK)
	for y: int in size_cells.y:
		for x: int in size_cells.x:
			_paint(Vector2i(x, y))


func _draw() -> void:
	for cell: Vector2i in _planks:
		draw_texture(plank_texture, Vector2(cell.x * NavGrid.CELL, (cell.y + 1) * NavGrid.CELL - 3))


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
	# The cell below may have gained or lost its ceiling shadow.
	_paint(cell + Vector2i.DOWN)
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
		# The shaft ladder looks after its own cells.
		if cell.y < 0 or _nav.is_climbable(cell):
			continue
		if is_standable(cell):
			_nav.set_walkable(cell)
		else:
			_nav.clear_walkable(cell)


func _paint(cell: Vector2i) -> void:
	if cell.y < 0 or cell.y >= size_cells.y or cell.x < 0 or cell.x >= size_cells.x:
		return
	var type: Cell = get_cell(cell)
	# Hidden ore looks like rock until it is found. The ore node draws itself.
	if type == Cell.ORE:
		type = Cell.ROCK
	var tile: int
	if type == Cell.AIR and cell.y > 0 and not is_open(cell + Vector2i.UP):
		tile = AIR_SHADOW_TILE
	else:
		var range_of: Vector2i = TILES[type]
		tile = range_of.x + absi(hash(cell)) % range_of.y
	_tiles.set_cell(cell, 0, Vector2i(tile, 0))
