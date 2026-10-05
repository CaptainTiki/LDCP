class_name MineLevelDef
extends Resource
## Shape, toughness and digging habits of one mine level.

@export var size_cells: Vector2i = Vector2i(256, 36)
## Row (from the top of the level) the shaft first lands on. Dwarves' feet
## go here. Miners dig the shaft deeper from there.
@export var landing_row: int = 4
## The pre-dug landing reaches this many cells either side of the shaft.
@export var landing_half_width: int = 2
@export var noise_seed: int = 1

@export_group("Ground")
## Rows of soft dirt at the top of the level, on average. Stone below.
@export var dirt_rows: int = 6
## How far the dirt line wanders up and down, in rows, so it isn't straight.
@export var dirt_edge_rows: float = 2.5
@export var dirt_work: float = 2.0
@export var rock_work: float = 5.0

@export_group("Tunnelling")
## The landing's tunnels run flat for this many columns before they may wander.
@export var straight_start_columns: int = 6
## Tunnels opened off the side of the shaft run flat for this many columns.
@export var branch_straight_columns: int = 2
## Solid rows kept between two tunnels leaving the same side of the shaft.
@export var branch_gap_rows: int = 3
## Chance per column that a flat tunnel starts a short slope.
@export_range(0.0, 1.0) var slope_chance: float = 0.1
## Chance per column that a tunnel forks into an upper and a lower branch.
@export_range(0.0, 1.0) var fork_chance: float = 0.04
## Forking stops once this many tunnel ends are active.
@export var max_heads: int = 5
