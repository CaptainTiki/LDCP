class_name InventoryTab
extends VBoxContainer
## The Inventory tab: everything in the Great Hall, a square per kind of
## item, and a bar along the top for selling whichever one is picked.

@export var slot_scene: PackedScene

var _shop: Shop
var _storage: Storage
## The item in the sell bar, or null.
var _picked: ItemDef = null

@onready var _icon: TextureRect = $SellBar/Icon
@onready var _label: Label = $SellBar/Label
@onready var _one_button: Button = $SellBar/OneButton
@onready var _all_button: Button = $SellBar/AllButton
@onready var _grid: GridContainer = $Scroll/Grid


func setup(game: Game) -> void:
	_shop = game.shop
	_storage = game.world.hall.storage
	for item: ItemDef in game.catalog.items:
		var slot: StockSlot = slot_scene.instantiate() as StockSlot
		_grid.add_child(slot)
		slot.setup(item)
		slot.chosen.connect(_on_chosen)
	_one_button.pressed.connect(sell.bind(false))
	_all_button.pressed.connect(sell.bind(true))
	_storage.changed.connect(_refresh)
	_refresh()


func pick(item: ItemDef) -> void:
	_picked = item
	_refresh()


## Picking the picked one again puts it back.
func _on_chosen(slot: StockSlot) -> void:
	pick(null if slot.item == _picked else slot.item)


## Sells one of the picked item, or all of it.
func sell(all: bool) -> void:
	if _picked != null:
		_shop.sell_item(_picked, _storage.count(_picked) if all else 1)


func _refresh() -> void:
	if _picked != null and _storage.count(_picked) <= 0:
		_picked = null
	for child: Node in _grid.get_children():
		var slot: StockSlot = child as StockSlot
		slot.refresh(_storage, slot.item == _picked)
	var can_sell: bool = _picked != null and _picked.sell_price > 0
	_icon.texture = _picked.icon if _picked != null else null
	_one_button.disabled = not can_sell
	_all_button.disabled = not can_sell
	if _picked == null:
		_label.text = "Pick something to sell"
	elif can_sell:
		_label.text = "%s x%d @%d" % [_picked.display_name, _storage.count(_picked), _picked.sell_price]
	else:
		_label.text = "%s x%d, not for sale" % [_picked.display_name, _storage.count(_picked)]
