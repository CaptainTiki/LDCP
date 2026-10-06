class_name TraderRole
extends DwarfRole
## Works the market. He fetches whatever the hall holds above the player's
## keep number, one kind and one load at a time, puts it on the stall and
## works the stall until it's all sold. With nothing above a keep number he
## waits in the market: the player sets what to sell.

## The stall he's working, so he can let go of it.
var _stall: MarketStall = null


func title() -> String:
	return "Trader"


func badge() -> String:
	return "T"


func act(delta: float) -> void:
	var market: Market = dwarf.assignment.target as Market
	if market == null:
		return
	var stall: MarketStall = market.stall()
	if not dwarf.carrier.is_empty():
		# Onto the counter, or sell what's already there first.
		if _walk_to(stall.work_cell()) and not stall.deposit(dwarf.carrier):
			_sell(stall, delta)
		return
	if not stall.is_empty():
		if _walk_to(stall.work_cell()):
			_sell(stall, delta)
		return
	var item: ItemDef = market.next_to_sell()
	if item == null:
		dwarf.idler.potter("Nothing to sell", market.interior.door_cell(), delta)
		return
	var hall: GreatHall = dwarf.world.hall
	if _walk_to(hall.storage_cell()):
		var amount: int = mini(market.surplus(item), dwarf.carrier.capacity)
		if amount > 0 and hall.storage.remove(item, amount):
			dwarf.carrier.add(item, amount)


func release() -> void:
	if is_instance_valid(_stall):
		_stall.receiver.release(dwarf)
	_stall = null


func _sell(stall: MarketStall, delta: float) -> void:
	_stall = stall
	stall.receiver.try_claim(dwarf)
	dwarf.worker.work_on(stall.receiver, delta)
