class_name Market
extends Building
## Sells the town's surplus. For each item the player sets how many to keep
## in the Great Hall; a trader carries anything above that to the stall and
## sells it, a load at a time. Until the player sets a number, all of an item
## is kept, so nothing is ever sold by surprise.

## The keep level of an item the player hasn't set: keep every one.
const KEEP_ALL: int = -1

## How many of each item to keep in the hall. Items not listed are all kept.
var keep_levels: Dictionary[ItemDef, int] = {}


func keep_of(item: ItemDef) -> int:
	return keep_levels.get(item, KEEP_ALL)


func set_keep(item: ItemDef, amount: int) -> void:
	if amount == KEEP_ALL:
		keep_levels.erase(item)
	else:
		keep_levels[item] = maxi(0, amount)


## How many of `item` the hall holds beyond what's kept: what's for sale.
func surplus(item: ItemDef) -> int:
	var keep: int = keep_of(item)
	if keep == KEEP_ALL or item.sell_price <= 0:
		return 0
	return maxi(0, world.hall.storage.count(item) - keep)


## The item with the most for sale, or null if there's nothing.
func next_to_sell() -> ItemDef:
	var best: ItemDef = null
	for item: ItemDef in keep_levels:
		if surplus(item) > 0 and (best == null or surplus(item) > surplus(best)):
			best = item
	return best


func stall() -> MarketStall:
	return (interior as MarketInterior).stall
