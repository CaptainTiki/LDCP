class_name Carrier
extends Node
## What a dwarf has on his back: a few of one item type.

var capacity: int = 5
var item: ItemDef = null
var count: int = 0


func is_empty() -> bool:
	return count <= 0


func is_full() -> bool:
	return count >= capacity


## True if at least one more of `new_item` would fit.
func can_take(new_item: ItemDef) -> bool:
	return is_empty() or (item == new_item and not is_full())


## True if all `amount` of `new_item` would fit.
func has_room_for(new_item: ItemDef, amount: int) -> bool:
	if not is_empty() and item != new_item:
		return false
	return capacity - count >= amount


## Picks up as many as fit. Returns how many did NOT fit.
func add(new_item: ItemDef, amount: int) -> int:
	if not can_take(new_item):
		return amount
	var taken: int = mini(amount, capacity - count)
	item = new_item
	count += taken
	return amount - taken


## Uses up carried items. Returns false (and takes nothing) if short.
func remove(wanted_item: ItemDef, amount: int) -> bool:
	if item != wanted_item or count < amount:
		return false
	count -= amount
	if count == 0:
		item = null
	return true


func unload_into(storage: Storage) -> void:
	if not is_empty():
		storage.add(item, count)
	item = null
	count = 0
