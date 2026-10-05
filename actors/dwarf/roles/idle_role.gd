class_name IdleRole
extends DwarfRole
## An unassigned dwarf puts away anything he's carrying, then sits in the
## Great Hall with a "?" over his head until he's given a job.


func act(_delta: float) -> void:
	if not dwarf.carrier.is_empty():
		_haul_to_hall()
		return
	dwarf.idler.sit_out("No job")
