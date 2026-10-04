class_name Building
extends Placeable
## A building is a shell in town with a door in its front wall. Its useful
## part is the interior: an authored room that lives in an off-screen part of
## the world and is joined to the door by a nav portal.

@export var interior_scene: PackedScene

var interior: BuildingInterior


func workstations() -> Array[Workstation]:
	return interior.workstations()


func sim_tick(delta: float) -> void:
	interior.sim_tick(delta)


func _on_placed() -> void:
	interior = interior_scene.instantiate() as BuildingInterior
	world.interiors.add_room(interior)
	interior.setup(world, self)
	world.nav.link_portal(door_cell(), interior.door_cell())


func _on_moved() -> void:
	# Unlinking from the room side drops the old street door with it.
	world.nav.unlink_portal(interior.door_cell())
	world.nav.link_portal(door_cell(), interior.door_cell())


func _on_removed() -> void:
	# Nobody gets demolished with the building: put them out on the street.
	for dwarf: Dwarf in world.dwarves.active():
		if interior.contains_cell(dwarf.mover.cell):
			dwarf.mover.place_at(door_cell())
	world.nav.unlink_portal(interior.door_cell())
	interior.teardown()
