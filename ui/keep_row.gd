class_name KeepRow
extends HBoxContainer
## One item in the market's list: its icon and name, how many the hall holds,
## and how many to keep. The trader sells anything above the keep number;
## "all" keeps every one. The count turns gold while some is for sale.

signal keep_changed

## The keep numbers - and + step through, ending at "keep all".
const STEPS: Array[int] = [0, 5, 10, 20, 50, 100, Market.KEEP_ALL]
const SELLING_COLOR: Color = Color(0.95, 0.8, 0.45)

var item: ItemDef

var _market: Market

@onready var _icon: TextureRect = $Icon
@onready var _name: Label = $Name
@onready var _count: Label = $Count
@onready var _minus: Button = $Minus
@onready var _keep: Label = $Keep
@onready var _plus: Button = $Plus


func setup(for_item: ItemDef) -> void:
	item = for_item
	_icon.texture = item.icon
	_name.text = item.display_name
	tooltip_text = "%s: sells for %d. Keep this many in the hall; the trader sells the rest" % [
			item.display_name, item.sell_price]
	_minus.pressed.connect(step.bind(-1))
	_plus.pressed.connect(step.bind(1))


func refresh(market: Market, storage: Storage) -> void:
	_market = market
	_count.text = str(storage.count(item))
	_count.modulate = SELLING_COLOR if market.surplus(item) > 0 else Color.WHITE
	var keep: int = market.keep_of(item)
	_keep.text = "all" if keep == Market.KEEP_ALL else str(keep)
	var index: int = STEPS.find(keep)
	_minus.disabled = index <= 0
	_plus.disabled = index >= STEPS.size() - 1


## Moves the keep number one step down (-1, selling more) or up (+1).
func step(direction: int) -> void:
	var index: int = STEPS.find(_market.keep_of(item))
	_market.set_keep(item, STEPS[clampi(index + direction, 0, STEPS.size() - 1)])
	keep_changed.emit()
