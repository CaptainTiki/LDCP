class_name World
extends Node2D
## The one continuous world: town on top, shaft down the middle, mine below,
## and building interiors off to the side. This node owns the pieces and
## hands each one the references it needs. It holds no gameplay of its own.

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
	# down through it to the landing.
	var shaft_column: int = mine_entrance.shaft_column()
	mine_level.setup(self, shaft_column)
	shaft.setup(nav, terrain, shaft_column, mine_level.landing_cell().y)
	surface.setup(self)
	dwarves.setup(self, tuning, clock)
	build_tool.setup(self, wallet)
	input.setup(self, tuning)
	camera.setup(self)


func sim_tick(delta: float) -> void:
	# Stations first, so dwarves act on this tick's up-to-date state.
	surface.sim_tick(delta)
	dwarves.sim_tick(delta)


## The rectangle the camera may roam: town, shaft and mine.
func bounds() -> Rect2:
	var bottom: float = terrain.size_cells.y * NavGrid.CELL
	return Rect2(0, -camera.sky_height, surface.width_pixels(), bottom + camera.sky_height)
