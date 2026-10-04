class_name ItemSlot
extends PanelContainer
## One square in a storage tab: an item, how many are in the Great Hall, and
## what one sells for. Locked squares stand in for items not found yet.

var item: ItemDef = null

@onready var _label: Label = $Label


func setup(for_item: ItemDef) -> void:
	item = for_item


func setup_locked() -> void:
	item = null
	_label.text = "Locked"
	modulate = Color(1, 1, 1, 0.45)


func refresh(storage: Storage) -> void:
	if item != null:
		_label.text = "%s\n%d   %dc" % [item.display_name, storage.count(item), item.sell_price]
