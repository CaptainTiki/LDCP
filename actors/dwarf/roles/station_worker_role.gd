class_name StationWorkerRole
extends DwarfRole
## Cooks and brewers. Assigned to a building, the dwarf keeps its stations
## going:
##   - empties finished stations, taking mash straight to a station that
##     wants it and everything else to the Great Hall,
##   - fetches ingredients from the hall and loads stations that have a
##     recipe set,
##   - finishes loading a fermenter the player poured mash into,
##   - feeds empty fermenters from any mash waiting in the hall.
## Stations with no recipe are left alone: what to make is the player's call.

## The station being loaded or emptied.
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
	if _station != null and not _still_wanted(_station):
		_drop_station()
	if not dwarf.carrier.is_empty():
		_deliver(building, delta)
		return
	if _station == null:
		_station = _pick_station(building)
	if _station == null:
		_walk_to(building.interior.door_cell())  # Nothing to do: wait inside.
		return
	if _station.has_output():
		if _walk_to(_station.work_cell()):
			_station.take_output(dwarf.carrier)
			_drop_station()
	elif _station.needs_loading() and _station.is_holding_input():
		if _walk_to(_station.work_cell()):
			dwarf.worker.work_on(_station.receiver, delta)
	else:
		_fetch_for(_station)


func release() -> void:
	_drop_station()


## Something on our back: load it into a station that takes it, or take it
## to the hall.
func _deliver(building: Building, delta: float) -> void:
	var item: ItemDef = dwarf.carrier.item
	if _station == null or not _wants(_station, item):
		_drop_station()
		_station = _claim_first(building, func(station: Workstation) -> bool: return _wants(station, item))
	if _station == null:
		_haul_to_hall()
		return
	if _walk_to(_station.work_cell()):
		_station.prepare_for(item)
		dwarf.worker.work_on(_station.receiver, delta)


## Would this station take what we're carrying, right now?
func _wants(station: Workstation, item: ItemDef) -> bool:
	if station.is_holding_input():
		return false
	var wanted: RecipeDef = station.recipe
	if station.accepts(item):
		wanted = station.recipe_for_input(item)
	elif not station.needs_loading() or wanted.input != item:
		return false
	return dwarf.carrier.count >= wanted.input_count


## Finished goods first, then any station we can load.
func _pick_station(building: Building) -> Workstation:
	var finished: Workstation = _claim_first(building, func(station: Workstation) -> bool: return station.has_output())
	if finished != null:
		return finished
	return _claim_first(building, _can_supply)


## Is there a loading job here: mash already poured in, or ingredients in
## the hall?
func _can_supply(station: Workstation) -> bool:
	if station.needs_loading() and station.is_holding_input():
		return true
	return _ingredients_for(station) != null


## The recipe whose ingredients we'd fetch from the hall for this station,
## or null if there's nothing to fetch.
func _ingredients_for(station: Workstation) -> RecipeDef:
	var storage: Storage = dwarf.world.hall.storage
	if station.needs_loading():
		var r: RecipeDef = station.recipe
		return r if storage.count(r.input) >= r.input_count else null
	if station.is_fed_by_station() and station.is_idle():
		for r: RecipeDef in station.station_def().recipes:
			if storage.count(r.input) >= r.input_count:
				return r
	return null


func _fetch_for(station: Workstation) -> void:
	var r: RecipeDef = _ingredients_for(station)
	if r == null:
		_drop_station()  # Someone else got to the pantry first.
		return
	var hall: GreatHall = dwarf.world.hall
	if _walk_to(hall.storage_cell()) and hall.storage.remove(r.input, r.input_count):
		dwarf.carrier.add(r.input, r.input_count)


## A station is worth keeping while there's still something to do at it.
func _still_wanted(station: Workstation) -> bool:
	if not is_instance_valid(station) or not station.is_inside_tree():
		return false
	return station.has_output() or station.needs_loading() or (station.is_fed_by_station() and station.is_idle())


## Reserves the first free station that passes `test`.
func _claim_first(building: Building, test: Callable) -> Workstation:
	for station: Workstation in building.workstations():
		var claimant: Node = station.receiver.claimed_by
		if claimant != null and is_instance_valid(claimant) and claimant != dwarf:
			continue
		if test.call(station):
			station.receiver.try_claim(dwarf)
			return station
	return null


func _drop_station() -> void:
	if is_instance_valid(_station):
		_station.receiver.release(dwarf)
	_station = null
