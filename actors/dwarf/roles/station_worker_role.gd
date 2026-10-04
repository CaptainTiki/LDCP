class_name StationWorkerRole
extends DwarfRole
## Cooks and brewers. Assigned to a building, the dwarf keeps its stations
## going:
##   - empties finished stations, taking mash straight to a station that
##     wants it and everything else to the Great Hall,
##   - fetches ingredients from the hall for stations that have a recipe set,
##     one kind per trip, and drops them in,
##   - works the bar once everything is inside,
##   - feeds empty fermenters from any mash waiting in the hall.
## Stations with no recipe are left alone: what to make is the player's call.

## The station being stocked, loaded or emptied.
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
		_deliver(building)
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
	elif _station.is_stocked():
		if _walk_to(_station.work_cell()):
			dwarf.worker.work_on(_station.receiver, delta)
	else:
		_fetch_for(_station)


func release() -> void:
	_drop_station()


## Something on our back: drop it into a station that wants it, or take it
## to the hall.
func _deliver(building: Building) -> void:
	var item: ItemDef = dwarf.carrier.item
	if _station == null or not _wants(_station, item):
		_drop_station()
		_station = _claim_first(building, func(station: Workstation) -> bool: return _wants(station, item))
	if _station == null:
		_haul_to_hall()
		return
	if _walk_to(_station.work_cell()) and not _station.deposit(dwarf.carrier):
		_drop_station()


func _wants(station: Workstation, item: ItemDef) -> bool:
	return station.accepts(item) or station.still_needs(item) > 0


## Finished goods first, then any station we can stock or load.
func _pick_station(building: Building) -> Workstation:
	var finished: Workstation = _claim_first(building, func(station: Workstation) -> bool: return station.has_output())
	if finished != null:
		return finished
	return _claim_first(building, _has_job)


func _has_job(station: Workstation) -> bool:
	return station.is_stocked() or _next_ingredient(station) != null


## The ingredient we'd fetch from the hall next for this station, or null.
func _next_ingredient(station: Workstation) -> ItemDef:
	var storage: Storage = dwarf.world.hall.storage
	if station.needs_loading():
		for stack: ItemStack in station.recipe.inputs:
			var wanted: int = station.still_needs(stack.item)
			if wanted > 0 and storage.count(stack.item) >= wanted:
				return stack.item
		return null
	if station.is_fed_by_station() and station.is_idle():
		for r: RecipeDef in station.station_def().recipes:
			var stack: ItemStack = r.inputs[0]
			if storage.count(stack.item) >= stack.count:
				return stack.item
	return null


func _fetch_for(station: Workstation) -> void:
	var item: ItemDef = _next_ingredient(station)
	if item == null:
		_drop_station()  # Someone else got to the pantry first.
		return
	var amount: int = station.still_needs(item)
	if amount == 0:
		amount = station.recipe_for_input(item).needs(item)
	amount = mini(amount, dwarf.carrier.capacity)
	var hall: GreatHall = dwarf.world.hall
	if _walk_to(hall.storage_cell()) and hall.storage.remove(item, amount):
		dwarf.carrier.add(item, amount)


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
