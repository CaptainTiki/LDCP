class_name StockSlot
extends Button
## One kind of item in the Inventory tab: its icon, how many the Great Hall
## holds, and what one sells for. Pressing it picks it for the sell bar.
## Hidden while the hall has none.

signal chosen(slot: StockSlot)

var item: ItemDef = null

@onready var _icon: TextureRect = $Margin/Row/Icon
@onready var _count: Label = $Margin/Row/Numbers/Count
@onready var _price_row: HBoxContainer = $Margin/Row/Numbers/PriceRow
@onready var _price: Label = $Margin/Row/Numbers/PriceRow/Price


func setup(for_item: ItemDef) -> void:
	item = for_item
	_icon.texture = item.icon
	tooltip_text = item.display_name
	_price.text = str(item.sell_price)
	_price_row.visible = item.sell_price > 0


func refresh(storage: Storage, selected: bool) -> void:
	var stock: int = storage.count(item)
	_count.text = str(stock)
	visible = stock > 0
	set_pressed_no_signal(selected)


func _pressed() -> void:
	chosen.emit(self)
