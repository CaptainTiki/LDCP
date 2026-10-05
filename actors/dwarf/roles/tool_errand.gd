class_name ToolErrand
extends DwarfRole
## A dwarf holding a tool for some other job (he's been reassigned, or made
## idle) goes to the Great Hall before doing anything else: he puts the tool
## back, drops off whatever he's carrying, and takes the best tool there is
## for his new job.


## True while he holds a tool that's no use for what he's been told to do.
func is_needed() -> bool:
	return dwarf.tool != null and dwarf.tool.job != dwarf.assignment.kind()


func title() -> String:
	return "Swapping tools"


func badge() -> String:
	return "T"


func act(_delta: float) -> void:
	var hall: GreatHall = dwarf.world.hall
	if _walk_to(hall.storage_cell()):
		dwarf.carrier.unload_into(hall.storage)
		dwarf.equip_best_tool(hall.storage)
