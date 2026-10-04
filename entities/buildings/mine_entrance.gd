class_name MineEntrance
extends Placeable
## The pit-head in town. Its door leads to the top of the mine shaft, the
## same way a building's door leads to its interior. Dropping a dwarf here
## makes him a miner, and clicking it opens the mine view.


func _on_placed() -> void:
	world.nav.link_portal(door_cell(), world.shaft.top_cell())


func _on_moved() -> void:
	world.nav.unlink_portal(world.shaft.top_cell())
	world.nav.link_portal(door_cell(), world.shaft.top_cell())
