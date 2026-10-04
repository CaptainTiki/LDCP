class_name FarmSlot
extends Button
## One square in the Farming tab: a tool, or a crop. A crop square is one of:
##   - a bag of seeds: stored count and seed price; pick it to sow,
##   - locked: a padlock and the milestone's progress ("12 /20"),
##   - on offer: milestone met, showing the trade price; pick it to trade.
## Spare padlocks after the crops hint at what's to come.

signal chosen(slot: FarmSlot)

var tool: PlayerHand.Tool = PlayerHand.Tool.NONE
## Set for a crop square.
var crop: CropDef = null

var _lock_icon: Texture2D

@onready var _icon: TextureRect = $Margin/Row/Icon
@onready var _numbers: VBoxContainer = $Margin/Row/Numbers
@onready var _count: Label = $Margin/Row/Numbers/Count
@onready var _coin: TextureRect = $Margin/Row/Numbers/PriceRow/Coin
@onready var _price: Label = $Margin/Row/Numbers/PriceRow/Price


func setup_tool(for_tool: PlayerHand.Tool, icon: Texture2D, tip: String) -> void:
	tool = for_tool
	_icon.texture = icon
	tooltip_text = tip
	_numbers.visible = false


func setup_crop(for_crop: CropDef, lock_icon: Texture2D) -> void:
	tool = PlayerHand.Tool.SEEDS
	crop = for_crop
	_lock_icon = lock_icon


func setup_locked(lock_icon: Texture2D) -> void:
	_icon.texture = lock_icon
	tooltip_text = "Locked"
	_numbers.visible = false
	disabled = true


func is_in_hand(hand: PlayerHand) -> bool:
	if tool == PlayerHand.Tool.NONE or hand.tool != tool:
		return false
	return crop == null or hand.seed_crop == crop


func refresh(hand: PlayerHand, storage: Storage, wallet: Wallet, unlocks: Unlocks) -> void:
	set_pressed_no_signal(is_in_hand(hand))
	if crop == null:
		return
	var unlock: UnlockDef = Unlocks.unlock_of(crop)
	if unlocks.is_unlocked(crop):
		_show(crop.produce.icon, str(storage.count(crop.produce)), str(crop.seed_cost), true)
		tooltip_text = "%s seeds" % crop.display_name
		disabled = not wallet.can_afford(crop.seed_cost)
	elif unlocks.milestone_met(crop):
		_show(crop.produce.icon, "Buy", str(unlock.coins), true)
		tooltip_text = "%s seeds\nTrade %s to unlock" % [crop.display_name, unlock.describe_price()]
		disabled = not unlocks.can_trade(crop)
	else:
		_show(_lock_icon, str(unlocks.progress(crop)), "/%d" % unlock.needed, false)
		tooltip_text = "%s seeds\n%s: %d / %d\nThen trade %s" % [crop.display_name, unlock.label,
				unlocks.progress(crop), unlock.needed, unlock.describe_price()]
		disabled = true


func _show(icon: Texture2D, count_text: String, price_text: String, show_coin: bool) -> void:
	_icon.texture = icon
	_numbers.visible = true
	_count.text = count_text
	_price.text = price_text
	_coin.visible = show_coin


func _pressed() -> void:
	chosen.emit(self)
