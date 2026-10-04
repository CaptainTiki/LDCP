class_name MineLevelDef
extends Resource
## Shape, toughness and digging habits of one mine level.

@export var size_cells: Vector2i = Vector2i(256, 18)
## Row (from the top of the level) the shaft lands on. Dwarves' feet go here.
@export var landing_row: int = 9
## The pre-dug landing reaches this many cells either side of the shaft.
@export var landing_half_width: int = 2
@export var noise_seed: int = 1

@export_group("Ground")
## Noise above this becomes rock. Lower = more rock.
@export_range(-1.0, 1.0) var rock_threshold: float = 0.25
@export var dirt_work: float = 2.0
@export var rock_work: float = 5.0

@export_group("Tunnelling")
## New tunnels run flat for this many columns before they may wander.
@export var straight_start_columns: int = 6
## Chance per column that a flat tunnel starts a short slope.
@export_range(0.0, 1.0) var slope_chance: float = 0.1
## Chance per column that a tunnel forks into an upper and a lower branch.
@export_range(0.0, 1.0) var fork_chance: float = 0.04
## Forking stops once this many tunnel ends are active.
@export var max_heads: int = 5
