class_name HandStatus
extends Label
## A line at the top of the screen saying what the player is holding and
## what it does, or what the Look tool just saw.

var _hand: PlayerHand


func setup(hand: PlayerHand) -> void:
	_hand = hand
	hand.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var carrier: Carrier = _hand.carrier
	if not carrier.is_empty():
		text = "Holding %d %s: click the Great Hall to drop them off" % [carrier.count, carrier.item.display_name]
	else:
		text = _tool_hint()


func _tool_hint() -> String:
	match _hand.tool:
		PlayerHand.Tool.HOE:
			return "Hoe: click a plant to root it up"
		PlayerHand.Tool.LOOK:
			return _hand.inspect_text if _hand.inspect_text != "" else "Look: click something to inspect it"
		PlayerHand.Tool.BUCKET:
			return "Bucket: click dry plants to water them"
		PlayerHand.Tool.SHEARS:
			return "Shears: click ripe plants to harvest them"
		PlayerHand.Tool.SEEDS:
			return "%s seeds: click an empty plot to sow (%dc)" % [_hand.seed_crop.display_name, _hand.seed_crop.seed_cost]
	return ""
