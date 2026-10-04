class_name World
extends Node2D
## Everything that exists in the game world. It is laid out as three
## separate regions of one coordinate space:
##   - the town, seen from above (Surface)
##   - the mine, seen from the side (Terrain, Shaft, MineLevel1)
##   - building interiors, seen from above (Interiors)
## Doors (nav portals) join them, so a dwarf walking from his bench to the
## coal face is one ordinary path. This node owns the pieces and hands each
## one the references it needs. It holds no gameplay of its own.

## World pixels of sky shown above the pit-head in the mine view.
@export var mine_sky_height: float = 40.0

@onready var nav: NavGrid = $NavGrid
@onready var terrain: Terrain = $Terrain
@onready var surface: Surface = $Surface
@onready var shaft: Shaft = $Shaft
@onready var mine_level: MineLevel = $MineLevel1
@onready var interiors: Interiors = $Interiors
@onready var dwarves: DwarfPool = $Dwarves
@onready var build_tool: BuildTool = $BuildTool
@onready var camera: ViewCamera = $Camera
@onready var input: WorldInput = $WorldInput
@onready var hall: GreatHall = $Surface/Placeables/GreatHall
@onready var mine_entrance: MineEntrance = $Surface/Placeables/MineEntrance


func setup(tuning: GameTuning, clock: SimClock, wallet: Wallet) -> void:
	terrain.setup(nav)
	# Order matters: the level fills its ground first, then the shaft is cut
	# down through it to the landing, then the town's doors are linked up.
	mine_level.setup(self)
	shaft.setup(nav, terrain, mine_level.landing_cell().y)
	surface.setup(self)
	dwarves.setup(self, tuning, clock)
	build_tool.setup(self, wallet)
	input.setup(self, tuning)
	camera.setup(self)


func sim_tick(delta: float) -> void:
	# Stations first, so dwarves act on this tick's up-to-date state.
	surface.sim_tick(delta)
	dwarves.sim_tick(delta)


## The rectangle the camera may roam in the mine view.
func mine_view_rect() -> Rect2:
	var size: Vector2 = Vector2(terrain.size_cells * NavGrid.CELL)
	return Rect2(0, -mine_sky_height, size.x, size.y + mine_sky_height)
