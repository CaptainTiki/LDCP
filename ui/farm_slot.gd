class_name FarmSlot
extends Button
## One square in the Farming tab: a tool, a bag of seeds, or a crop that is
## still locked. Seed bags show the crop, how much of it is in the Great Hall,
## and what a seed costs.

signal chosen(slot: FarmSlot)

var tool: PlayerHand.Tool = PlayerHand.Tool.NONE
## Set for a seed bag.
var crop: CropDef = null

@onready var _icon: TextureRect = $Margin/Row/Icon
@onready var _numbers: VBoxContainer = $Margin/Row/Numbers
@onready var _count: Label = $Margin/Row/Numbers/Count
@onready var _price: Label = $Margin/Row/Numbers/PriceRow/Price


func setup_tool(for_tool: PlayerHand.Tool, icon: Texture2D, tip: String) -> void:
	tool = for_tool
	_show(icon, tip, false)


func setup_seeds(for_crop: CropDef) -> void:
	tool = PlayerHand.Tool.SEEDS
	crop = for_crop
	_show(crop.produce.icon, "%s seeds" % crop.display_name, true)


func setup_locked(lock_icon: Texture2D) -> void:
	_show(lock_icon, "Locked", false)
	disabled = true


func is_in_hand(hand: PlayerHand) -> bool:
	if tool == PlayerHand.Tool.NONE or hand.tool != tool:
		return false
	return crop == null or hand.seed_crop == crop


## Greys a seed bag out when the purse can't cover one.
func refresh(hand: PlayerHand, storage: Storage, wallet: Wallet) -> void:
	set_pressed_no_signal(is_in_hand(hand))
	if crop != null:
		_count.text = str(storage.count(crop.produce))
		_price.text = str(crop.seed_cost)
		disabled = not wallet.can_afford(crop.seed_cost)


func _show(icon: Texture2D, tip: String, with_numbers: bool) -> void:
	_icon.texture = icon
	tooltip_text = tip
	_numbers.visible = with_numbers


func _pressed() -> void:
	chosen.emit(self)
