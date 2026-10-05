class_name EconomyWatcher
extends LogWatcher
## Logs the economy: the first of everything harvested, made or mined,
## unlock milestones reached and trades made, the pantry running out of
## meals or drinks, and each minute the coins, output and storage.

enum Stage { LOCKED, MILESTONE, AFFORDABLE, UNLOCKED }

var _ledger: Dictionary[StringName, int] = {}
## Ledger counters at the start of this minute.
var _ledger_at_minute: Dictionary[StringName, int] = {}
## Item names by id, for reading the Ledger's "made:stew" keys.
var _item_names: Dictionary[String, String] = {}
var _coins: int = 0
var _earned: Dictionary[String, int] = {"minute": 0, "total": 0}
var _spent: Dictionary[String, int] = {"minute": 0, "total": 0}
## The furthest each lockable thing has got.
var _unlock_stage: Dictionary[Resource, Stage] = {}
var _has_meals: bool = true
var _has_drinks: bool = true


func _start() -> void:
	for item: ItemDef in _game.catalog.items:
		_item_names[str(item.id)] = item.display_name
	_ledger = _game.world.ledger.counters()
	_ledger_at_minute = _ledger.duplicate()
	_coins = _game.wallet.coins
	_game.wallet.changed.connect(_on_coins_changed)
	for thing: Resource in _lockables():
		_unlock_stage[thing] = _stage_of(thing)
	_has_meals = _pantry_count(MealDef) > 0
	_has_drinks = _pantry_count(DrinkDef) > 0
	_game_log.event("Start: %d coins, storage %s" % [_coins, LogFormat.counts(_storage_counts())])


func check() -> void:
	_check_firsts()
	_check_unlocks()
	_check_pantry()


func minute_report() -> void:
	_game_log.line("Coins %d (+%d earned, -%d spent)" % [_coins, _earned.minute, _spent.minute])
	_earned.minute = 0
	_spent.minute = 0
	var now: Dictionary[StringName, int] = _game.world.ledger.counters()
	for kind: StringName in [Ledger.HARVESTED, Ledger.MADE, Ledger.MINED]:
		var amounts: Dictionary = {}
		for key: StringName in now:
			var gained: int = now[key] - _ledger_at_minute.get(key, 0)
			if gained > 0 and str(key).begins_with(str(kind) + ":"):
				amounts[_item_name(key)] = gained
		if not amounts.is_empty():
			_game_log.line("%s: %s" % [str(kind).capitalize(), LogFormat.counts(amounts)])
	_ledger_at_minute = now
	_game_log.line("Storage: %s" % LogFormat.counts(_storage_counts()))


func totals_report() -> void:
	var ledger: Ledger = _game.world.ledger
	_game_log.line("Coins %d: %d earned, %d spent" % [_coins, _earned.total, _spent.total])
	_game_log.line("Harvested %d, meals made %d, drinks made %d, ore mined %d" % [
			ledger.count(Ledger.HARVESTED), ledger.count(Ledger.MEALS_MADE),
			ledger.count(Ledger.DRINKS_MADE), ledger.count(Ledger.MINED)])


func _on_coins_changed() -> void:
	var change: int = _game.wallet.coins - _coins
	_coins = _game.wallet.coins
	var tally: Dictionary[String, int] = _earned if change > 0 else _spent
	tally.minute += absi(change)
	tally.total += absi(change)


## The first time each item is harvested, made or mined.
func _check_firsts() -> void:
	var now: Dictionary[StringName, int] = _game.world.ledger.counters()
	for key: StringName in now:
		if _ledger.get(key, 0) == 0 and now[key] > 0 and str(key).contains(":"):
			var kind: String = str(key).get_slice(":", 0)
			_game_log.event("First %s: %s" % [kind, _item_name(key)])
	_ledger = now


## Each step towards an unlock, logged the first time it's reached. (Coins
## going up and down around a price would otherwise flicker "can afford".)
func _check_unlocks() -> void:
	for thing: Resource in _unlock_stage:
		var stage: Stage = _stage_of(thing)
		if stage <= _unlock_stage[thing]:
			continue
		_unlock_stage[thing] = stage
		var what: String = LogFormat.name_of(thing)
		var unlock: UnlockDef = Unlocks.unlock_of(thing)
		match stage:
			Stage.MILESTONE:
				_game_log.event("Milestone met for %s (%s %d), trade costs %s" % [
						what, unlock.counter, unlock.needed, unlock.describe_price()])
			Stage.AFFORDABLE:
				_game_log.event("Can afford to unlock %s" % what)
			Stage.UNLOCKED:
				_game_log.event("Unlocked %s" % what)


func _stage_of(thing: Resource) -> Stage:
	var unlocks: Unlocks = _game.unlocks
	if unlocks.is_unlocked(thing):
		return Stage.UNLOCKED
	if unlocks.can_trade(thing):
		return Stage.AFFORDABLE
	return Stage.MILESTONE if unlocks.milestone_met(thing) else Stage.LOCKED


func _check_pantry() -> void:
	var has_meals: bool = _pantry_count(MealDef) > 0
	if has_meals != _has_meals:
		_game_log.event("Pantry: meals back in" if has_meals else "Pantry: out of meals")
		_has_meals = has_meals
	var has_drinks: bool = _pantry_count(DrinkDef) > 0
	if has_drinks != _has_drinks:
		_game_log.event("Pantry: drinks back in" if has_drinks else "Pantry: out of drinks")
		_has_drinks = has_drinks


func _pantry_count(kind: Variant) -> int:
	var storage: Storage = _game.world.hall.storage
	var total: int = 0
	for item: ItemDef in storage.items():
		if is_instance_of(item, kind):
			total += storage.count(item)
	return total


func _storage_counts() -> Dictionary:
	var storage: Storage = _game.world.hall.storage
	var amounts: Dictionary = {}
	for item: ItemDef in storage.items():
		if storage.count(item) > 0:
			amounts[item.display_name] = storage.count(item)
	return amounts


## Crops and buildings that start locked.
func _lockables() -> Array[Resource]:
	var things: Array[Resource] = []
	for crop: CropDef in _game.catalog.crops:
		if Unlocks.unlock_of(crop) != null:
			things.append(crop)
	for building: BuildingDef in _game.catalog.buildings:
		if Unlocks.unlock_of(building) != null:
			things.append(building)
	return things


func _item_name(key: StringName) -> String:
	var id: String = str(key).get_slice(":", 1)
	return _item_names.get(id, id)
