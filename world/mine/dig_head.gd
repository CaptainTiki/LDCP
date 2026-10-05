class_name DigHead
extends RefCounted
## The working end of one tunnel. A miner stands at `stand_cell` and digs
## the cells in `pending`, which together open up the next column.

## Where the miner stands: the last cell of the tunnel so far.
var stand_cell: Vector2i
## 1 = tunnelling right, -1 = tunnelling left.
var direction: int = 1
## While `slope_steps_left` > 0 the tunnel keeps stepping this way (-1 up, 1 down).
var slope_dir: int = 0
var slope_steps_left: int = 0
## Columns left that must run flat (new tunnels start straight).
var straight_left: int = 0

## Cells still to dig for the column being opened.
var pending: Array[Vector2i] = []
## Vertical step the planned column takes: -1 up, 0 flat, 1 down.
var step: int = 0
## The planned column is a tall one that splits into two tunnels.
var is_fork: bool = false
## This head digs the shaft down instead of a tunnel sideways.
var is_shaft: bool = false

var claimed_by: Node = null
var is_dead: bool = false

## Cells this head has reserved so other heads plan around them.
var reserved_dig: Array[Vector2i] = []
var reserved_solid: Array[Vector2i] = []
