class_name ItemStack
extends Resource
## A count of one item, or of any items of one category ("2 of any crop").
## Recipes use both: gruel takes whatever crop is on hand. Starting stock
## uses the first.

## What a stack of "any" calls its category, e.g. "1 any crop".
const CATEGORY_WORDS: Dictionary[ItemDef.Category, String] = {
	ItemDef.Category.CROP: "crop",
	ItemDef.Category.MEAL: "meal",
	ItemDef.Category.DRINK: "drink",
	ItemDef.Category.BREWING: "mash",
	ItemDef.Category.METAL: "metal",
	ItemDef.Category.TOOL: "tool",
	ItemDef.Category.OTHER: "item",
}

@export var item: ItemDef
@export var count: int = 1
## With no `item`, any item of this category will do.
@export var any_category: ItemDef.Category = ItemDef.Category.OTHER


## True for "any crop" rather than one particular item.
func is_any() -> bool:
	return item == null


## Does `candidate` count towards this stack?
func accepts(candidate: ItemDef) -> bool:
	if candidate == null:
		return false
	return candidate == item if item != null else candidate.category == any_category


## E.g. "2 Potato" or "1 any crop". `amount` overrides the stack's count.
func describe(amount: int = -1) -> String:
	var shown: int = count if amount < 0 else amount
	if item != null:
		return "%d %s" % [shown, item.display_name]
	return "%d any %s" % [shown, CATEGORY_WORDS[any_category]]


## How many of what `storage` holds would count towards this stack.
func available_in(storage: Storage) -> int:
	if item != null:
		return storage.count(item)
	var total: int = 0
	for stored: ItemDef in storage.items():
		if accepts(stored):
			total += storage.count(stored)
	return total


## The stored item to use next: the item itself, or for "any", the cheapest
## to sell, then whichever there's most of. Null if `storage` has none.
func pick_from(storage: Storage) -> ItemDef:
	if item != null:
		return item if storage.count(item) > 0 else null
	var best: ItemDef = null
	for stored: ItemDef in storage.items():
		if not accepts(stored):
			continue
		if best == null or stored.sell_price < best.sell_price or (
				stored.sell_price == best.sell_price and storage.count(stored) > storage.count(best)):
			best = stored
	return best
