class_name Shop
extends Node
## Every way coins change hands. The trader is abstract for now: selling and
## buying happen instantly at the Great Hall.

var _wallet: Wallet
var _unlocks: Unlocks
var _world: World
var _tuning: GameTuning


func setup(wallet: Wallet, unlocks: Unlocks, world: World, tuning: GameTuning) -> void:
	_wallet = wallet
	_unlocks = unlocks
	_world = world
	_tuning = tuning


func buy_item(item: ItemDef) -> bool:
	if item.buy_price <= 0 or not _wallet.spend(item.buy_price):
		return false
	_world.hall.storage.add(item, 1)
	return true


func sell_item(item: ItemDef, amount: int) -> bool:
	if item.sell_price <= 0 or amount <= 0:
		return false
	if not _world.hall.storage.remove(item, amount):
		return false
	_wallet.earn(item.sell_price * amount)
	return true


func hire_cost() -> int:
	var extra_hires: int = maxi(0, _world.dwarves.active_count() - _tuning.starting_dwarves)
	return _tuning.hire_cost + _tuning.hire_cost_growth * extra_hires


func can_hire() -> bool:
	return _world.dwarves.has_spare() and _wallet.can_afford(hire_cost())


func hire() -> bool:
	if not can_hire():
		return false
	_wallet.spend(hire_cost())
	_world.dwarves.hire()
	return true


func unlock_building(def: BuildingDef) -> bool:
	if _unlocks.is_unlocked(def) or not _wallet.spend(def.unlock_cost):
		return false
	_unlocks.unlock(def)
	return true


func lift_cost() -> int:
	return _tuning.lift_cost


func can_buy_lift() -> bool:
	return not _world.shaft.has_lift and _wallet.can_afford(_tuning.lift_cost)


func buy_lift() -> bool:
	if not can_buy_lift():
		return false
	_wallet.spend(_tuning.lift_cost)
	_world.shaft.install_lift()
	return true
