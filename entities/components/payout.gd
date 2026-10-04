class_name Payout
extends RefCounted
## Decides where freshly produced items go. A dwarf who did the work carries
## them. A player click has no back to carry things on, so those go straight
## into storage.


static func give(item: ItemDef, amount: int, worker: Node, fallback: Storage) -> void:
	var leftover: int = amount
	var dwarf: Dwarf = worker as Dwarf
	if dwarf != null:
		leftover = dwarf.carrier.add(item, amount)
	# Never lose items: whatever the dwarf could not hold lands in storage.
	if leftover > 0 and fallback != null:
		fallback.add(item, leftover)
