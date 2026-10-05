class_name IdleRole
extends DwarfRole
## An unassigned dwarf puts away anything he's carrying, then potters about
## outside the Great Hall with a "?" over his head until he's given a job.


func act(delta: float) -> void:
	if not dwarf.carrier.is_empty():
		_haul_to_hall()
		return
	dwarf.idler.potter("No job", dwarf.world.hall.door_cell(), delta)
