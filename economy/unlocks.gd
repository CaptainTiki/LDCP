class_name Unlocks
extends Node
## Remembers what the town has unlocked, and runs the trades that unlock
## things. Anything with an `unlock: UnlockDef` property (crops, buildings)
## can be locked; with no UnlockDef it's open from the start.
##
## An unlock has two gates: a milestone from the Ledger ("harvest 20
## crops"), then a trade (coins now; ore and ingots later).

## Something was unlocked, or progress towards a milestone moved.
signal changed

var _ledger: Ledger
var _wallet: Wallet
var _storage: Storage
## Unlocked things, by resource path.
var _unlocked: Dictionary[String, bool] = {}


func setup(ledger: Ledger, wallet: Wallet, storage: Storage) -> void:
	_ledger = ledger
	_wallet = wallet
	_storage = storage
	ledger.changed.connect(changed.emit)


static func unlock_of(thing: Resource) -> UnlockDef:
	return thing.get(&"unlock") as UnlockDef


func is_unlocked(thing: Resource) -> bool:
	return unlock_of(thing) == null or _unlocked.has(thing.resource_path)


## How far along the milestone is, capped at what's needed.
func progress(thing: Resource) -> int:
	var unlock: UnlockDef = unlock_of(thing)
	return mini(_ledger.count(unlock.counter), unlock.needed) if unlock != null else 0


func milestone_met(thing: Resource) -> bool:
	var unlock: UnlockDef = unlock_of(thing)
	return unlock == null or _ledger.count(unlock.counter) >= unlock.needed


func can_trade(thing: Resource) -> bool:
	if is_unlocked(thing) or not milestone_met(thing):
		return false
	var unlock: UnlockDef = unlock_of(thing)
	if not _wallet.can_afford(unlock.coins):
		return false
	for stack: ItemStack in unlock.items:
		if _storage.count(stack.item) < stack.count:
			return false
	return true


func trade(thing: Resource) -> bool:
	if not can_trade(thing):
		return false
	var unlock: UnlockDef = unlock_of(thing)
	_wallet.spend(unlock.coins)
	for stack: ItemStack in unlock.items:
		_storage.remove(stack.item, stack.count)
	_unlocked[thing.resource_path] = true
	changed.emit()
	return true


## A recipe is on the menu once every crop it needs can be grown.
func recipe_available(recipe: RecipeDef, catalog: ContentCatalog) -> bool:
	for stack: ItemStack in recipe.inputs:
		if stack.is_any():
			continue  # Whatever is on hand will do.
		for crop: CropDef in catalog.crops:
			if crop.produce == stack.item and not is_unlocked(crop):
				return false
	return true
