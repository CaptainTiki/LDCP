class_name SellRow
extends HBoxContainer
## One sellable item in the shop: how many are in the hall, and buttons to
## sell one or all of them.

signal sell_requested(item: ItemDef, amount: int)

var item: ItemDef

var _stock: int = 0

@onready var _label: Label = $Label
@onready var _one_button: Button = $OneButton
@onready var _all_button: Button = $AllButton


func setup(for_item: ItemDef) -> void:
	item = for_item
	_one_button.pressed.connect(_request.bind(false))
	_all_button.pressed.connect(_request.bind(true))


func refresh(storage: Storage) -> void:
	_stock = storage.count(item)
	_label.text = "%s x%d  @%d" % [item.display_name, _stock, item.sell_price]
	_one_button.disabled = _stock <= 0
	_all_button.disabled = _stock <= 0


func _request(all: bool) -> void:
	sell_requested.emit(item, _stock if all else 1)
