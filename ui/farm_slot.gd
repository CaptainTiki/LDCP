class_name FarmSlot
extends Button
## One square in the Farming tab: a tool, a bag of seeds, or a crop that is
## still locked.

signal chosen(slot: FarmSlot)

var tool: PlayerHand.Tool = PlayerHand.Tool.NONE
## Set for a seed bag.
var crop: CropDef = null


func setup_tool(for_tool: PlayerHand.Tool, label: String) -> void:
	tool = for_tool
	text = label


func setup_seeds(for_crop: CropDef) -> void:
	tool = PlayerHand.Tool.SEEDS
	crop = for_crop


func setup_locked() -> void:
	text = "Locked"
	disabled = true


func is_in_hand(hand: PlayerHand) -> bool:
	if tool == PlayerHand.Tool.NONE or hand.tool != tool:
		return false
	return crop == null or hand.seed_crop == crop


## Seed bags show how much of the crop is in the Great Hall and what a seed
## costs, and grey out when the purse can't cover one.
func refresh(hand: PlayerHand, storage: Storage, wallet: Wallet) -> void:
	set_pressed_no_signal(is_in_hand(hand))
	if crop != null:
		text = "%s\n%d   %dc" % [crop.display_name, storage.count(crop.produce), crop.seed_cost]
		disabled = not wallet.can_afford(crop.seed_cost)


func _pressed() -> void:
	chosen.emit(self)
