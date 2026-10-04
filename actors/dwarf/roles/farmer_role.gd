class_name FarmerRole
extends DwarfRole
## Farmers look after every farm plot in town: plant, water whatever is dry,
## harvest whatever is ripe, and carry the crops to the Great Hall.

var _plot: FarmPlot = null


func title() -> String:
	return "Farmer"


func badge() -> String:
	return "F"


func act(delta: float) -> void:
	if _plot != null and not _still_needs_work(_plot):
		_drop_plot()
	if _plot == null:
		_plot = _pick_plot()
	if _plot == null:
		# Everything is growing. A good moment to take the crops in.
		if not dwarf.carrier.is_empty():
			_haul_to_hall()
		return
	if _must_unload_before_working(_plot):
		_haul_to_hall()
		return
	if _walk_to(_plot.work_cell()):
		dwarf.worker.work_on(_plot.receiver, delta)


func release() -> void:
	_drop_plot()


func _still_needs_work(plot: FarmPlot) -> bool:
	if not is_instance_valid(plot) or not plot.is_inside_tree():
		return false
	return plot.current_task() != FarmPlot.Task.NONE


func _must_unload_before_working(plot: FarmPlot) -> bool:
	if dwarf.carrier.is_full():
		return true
	var is_harvest: bool = plot.current_task() == FarmPlot.Task.HARVEST
	return is_harvest and not dwarf.carrier.can_take(plot.crop.produce)


## The nearest plot that needs something done and nobody else is doing it.
func _pick_plot() -> FarmPlot:
	var best: FarmPlot = null
	var best_distance: int = 0
	for plot: FarmPlot in dwarf.world.surface.farm_plots():
		if plot.current_task() == FarmPlot.Task.NONE:
			continue
		var claimant: Node = plot.receiver.claimed_by
		if claimant != null and is_instance_valid(claimant) and claimant != dwarf:
			continue
		var distance: int = absi(plot.work_cell().x - dwarf.mover.cell.x)
		if best == null or distance < best_distance:
			best = plot
			best_distance = distance
	if best != null:
		best.receiver.try_claim(dwarf)
	return best


func _drop_plot() -> void:
	if is_instance_valid(_plot):
		_plot.receiver.release(dwarf)
	_plot = null
