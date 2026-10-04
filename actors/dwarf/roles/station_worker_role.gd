class_name StationWorkerRole
extends DwarfRole
## Cooks and brewers. Assigned to a building, the dwarf runs its
## workstations: fetch ingredients from the Great Hall, load a station, and
## carry finished goods back to the hall while the stations run themselves.

var _station: Workstation = null


func title() -> String:
	var building: Building = dwarf.assignment.target as Building
	return "Works at the %s" % building.def.display_name if building != null else "Worker"


func badge() -> String:
	return "C"


func act(delta: float) -> void:
	var building: Building = dwarf.assignment.target as Building
	if building == null:
		return
	if _station != null and not _is_usable(_station):
		_drop_station()
	# Anything on our back that is not ingredients for our station is
	# finished goods (or leftovers from an old job): take it to the hall.
	if not dwarf.carrier.is_empty() and not _has_ingredients_for(_station):
		_drop_station()
		_haul_to_hall()
		return
	if _station == null:
		_station = _pick_station(building)
	if _station == null:
		_walk_to(building.interior.door_cell())  # Nothing to do: wait inside.
		return
	if _station.has_output():
		_collect_output()
	elif _has_ingredients_for(_station):
		if _walk_to(_station.work_cell()):
			dwarf.worker.work_on(_station.receiver, delta)
	else:
		_fetch_ingredients()


func release() -> void:
	_drop_station()


func _collect_output() -> void:
	if _walk_to(_station.work_cell()):
		_station.take_output(dwarf.carrier)
		_drop_station()


func _fetch_ingredients() -> void:
	var hall: GreatHall = dwarf.world.hall
	var def: WorkstationDef = _station.recipe()
	if hall.storage.count(def.input) < def.input_count:
		_drop_station()  # Someone else got to the pantry first.
		return
	if _walk_to(hall.storage_cell()) and hall.storage.remove(def.input, def.input_count):
		dwarf.carrier.add(def.input, def.input_count)


func _has_ingredients_for(station: Workstation) -> bool:
	if station == null or not station.needs_loading():
		return false
	var carrier: Carrier = dwarf.carrier
	return carrier.item == station.recipe().input and carrier.count >= station.recipe().input_count


## A station is worth keeping while it still wants loading or emptying.
func _is_usable(station: Workstation) -> bool:
	if not is_instance_valid(station) or not station.is_inside_tree():
		return false
	return station.needs_loading() or station.has_output()


## Finished goods come first, then any station we can find ingredients for.
func _pick_station(building: Building) -> Workstation:
	var storage: Storage = dwarf.world.hall.storage
	var to_load: Workstation = null
	for station: Workstation in building.workstations():
		var claimant: Node = station.receiver.claimed_by
		if claimant != null and is_instance_valid(claimant) and claimant != dwarf:
			continue
		if station.has_output():
			station.receiver.try_claim(dwarf)
			return station
		var can_load: bool = storage.count(station.recipe().input) >= station.recipe().input_count
		if to_load == null and station.needs_loading() and can_load:
			to_load = station
	if to_load != null:
		to_load.receiver.try_claim(dwarf)
	return to_load


func _drop_station() -> void:
	if is_instance_valid(_station):
		_station.receiver.release(dwarf)
	_station = null
