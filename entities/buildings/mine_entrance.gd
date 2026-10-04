class_name MineEntrance
extends Placeable
## The pit-head over the shaft. Dropping a dwarf here makes him a miner.
## It cannot be moved: the shaft is dug straight down from it.

## Which nav column of the entrance's footprint the shaft drops from.
@export var shaft_offset_cells: int = 2


func shaft_column() -> int:
	return slot * SLOT_CELLS + shaft_offset_cells
