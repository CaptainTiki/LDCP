class_name MineLevel
extends Node2D
## One level of the mine. The scene is placed in the world where the level
## should sit, and its ore nodes are placed by hand as children of OreNodes.
## At start-up the level fills its region of the terrain with dirt over
## stone, cuts the shaft down to a small landing, and opens a tunnel either
## side of it.

## An ore node is found when a tunnel opens a cell this close to it.
const ORE_REVEAL_REACH: int = 2

@export var def: MineLevelDef

var _terrain: Terrain
var _shaft_column: int = 0

@onready var excavation: Excavation = $Excavation
@onready var _ore_nodes: Node2D = $OreNodes


func setup(world: World) -> void:
	_terrain = world.terrain
	_shaft_column = world.shaft.column
	_fill_ground()
	for node: OreNode in ore_nodes():
		node.setup(world.nav, world.hall.storage, world.ledger)
		_embed(node)
	_carve_landing()
	world.shaft.setup(world.nav, _terrain, landing_cell().y)
	_terrain.cell_opened.connect(_on_cell_opened)
	excavation.setup(_terrain, def, bounds(), world.shaft)
	_open_landing_tunnels()


## The level's rectangle in terrain cells.
func bounds() -> Rect2i:
	return Rect2i(NavGrid.world_to_cell(position), def.size_cells)


## Where the shaft first touches down.
func landing_cell() -> Vector2i:
	return Vector2i(_shaft_column, bounds().position.y + def.landing_row)


## World-space rectangle, for framing the camera.
func view_rect() -> Rect2:
	return Rect2(position, Vector2(def.size_cells * NavGrid.CELL))


func ore_nodes() -> Array[OreNode]:
	var nodes: Array[OreNode] = []
	for child: Node in _ore_nodes.get_children():
		nodes.append(child as OreNode)
	return nodes


## Reserves a found ore node nobody is working, or returns null.
func claim_free_node(miner: Node) -> OreNode:
	for node: OreNode in ore_nodes():
		if node.revealed and node.receiver.try_claim(miner):
			return node
	return null


## Debug: shows every ore node, found or not.
func reveal_all() -> void:
	for node: OreNode in ore_nodes():
		node.reveal()


## Soft dirt under the grass, stone below. Noise roughs up the line between
## them, so it wanders and leaves the odd pocket either side.
func _fill_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = def.noise_seed
	noise.frequency = 0.15
	var area: Rect2i = bounds()
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var depth: float = y - area.position.y + noise.get_noise_2d(x, y) * def.dirt_edge_rows
			_terrain.set_cell(Vector2i(x, y), Terrain.Cell.DIRT if depth < def.dirt_rows else Terrain.Cell.ROCK)


## Ore cells are solid and never dug through. Tunnels go around them.
func _embed(node: OreNode) -> void:
	var rect: Rect2i = node.cell_rect()
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_terrain.set_cell(Vector2i(x, y), Terrain.Cell.ORE)


func _carve_landing() -> void:
	var landing: Vector2i = landing_cell()
	for dx: int in range(-def.landing_half_width, def.landing_half_width + 1):
		_terrain.set_cell(landing + Vector2i(dx, -1), Terrain.Cell.AIR)
		_terrain.set_cell(landing + Vector2i(dx, 0), Terrain.Cell.AIR)


## One tunnel each way off the landing. The one heading for the nearest
## deposit is offered first, so the first miner down finds ore quickly.
func _open_landing_tunnels() -> void:
	var landing: Vector2i = landing_cell()
	var toward_ore: int = 1 if _nearest_ore_column() >= landing.x else -1
	for side: int in [toward_ore, -toward_ore]:
		excavation.add_head(landing + Vector2i(side * def.landing_half_width, 0), side)


func _nearest_ore_column() -> int:
	var landing := Vector2(landing_cell())
	var best_column: int = landing_cell().x
	var best_distance: float = INF
	for node: OreNode in ore_nodes():
		var cell := Vector2(node.cell_rect().position)
		var distance: float = cell.distance_to(landing)
		if distance < best_distance:
			best_distance = distance
			best_column = int(cell.x)
	return best_column


func _on_cell_opened(cell: Vector2i) -> void:
	for node: OreNode in ore_nodes():
		if not node.revealed and node.is_near(cell, ORE_REVEAL_REACH):
			node.reveal()
