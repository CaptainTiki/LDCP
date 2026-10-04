class_name IconSlot
extends Button
## A square button with an icon and, optionally, a coin price beside it.
## Used for the Hall tab's tools and furniture.

signal chosen(slot: IconSlot)

## What this slot stands for: a FurnitureDef, or null for a plain tool.
var payload: Resource = null
var cost: int = 0

@onready var _icon: TextureRect = $Margin/Row/Icon
@onready var _numbers: VBoxContainer = $Margin/Row/Numbers
@onready var _count: Label = $Margin/Row/Numbers/Count
@onready var _price: Label = $Margin/Row/Numbers/PriceRow/Price


func setup(icon: Texture2D, tip: String, price: int = -1, for_payload: Resource = null) -> void:
	_icon.texture = icon
	tooltip_text = tip
	payload = for_payload
	cost = price
	_numbers.visible = price >= 0
	_count.text = ""
	_price.text = str(price)


## Greys the slot out when the purse can't cover it.
func refresh(selected: bool, wallet: Wallet) -> void:
	set_pressed_no_signal(selected)
	if cost >= 0:
		disabled = not wallet.can_afford(cost)


func _pressed() -> void:
	chosen.emit(self)
