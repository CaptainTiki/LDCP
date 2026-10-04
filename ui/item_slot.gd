class_name ItemSlot
extends PanelContainer
## One square in a storage tab: an item, how many are in the Great Hall, and
## what one sells for. Locked squares stand in for items not found yet.

var item: ItemDef = null

@onready var _icon: TextureRect = $Row/Icon
@onready var _numbers: VBoxContainer = $Row/Numbers
@onready var _count: Label = $Row/Numbers/Count
@onready var _price: Label = $Row/Numbers/PriceRow/Price


func setup(for_item: ItemDef) -> void:
	item = for_item
	_icon.texture = item.icon
	tooltip_text = item.display_name


func setup_locked(lock_icon: Texture2D) -> void:
	item = null
	_icon.texture = lock_icon
	_numbers.visible = false
	tooltip_text = "Locked"
	modulate = Color(1, 1, 1, 0.5)


func refresh(storage: Storage) -> void:
	if item != null:
		_count.text = str(storage.count(item))
		_price.text = str(item.sell_price)
