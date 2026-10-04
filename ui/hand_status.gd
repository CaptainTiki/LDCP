class_name HandStatus
extends PanelContainer
## A line at the top of the screen saying what the player is holding and
## what it does, or what the Look tool just saw. Hidden when there's nothing
## to say.

var _hand: PlayerHand

@onready var _label: Label = $Label


func setup(hand: PlayerHand) -> void:
	_hand = hand
	hand.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var carrier: Carrier = _hand.carrier
	if not carrier.is_empty():
		_label.text = "Holding %d %s: click the Great Hall" % [carrier.count, carrier.item.display_name]
	else:
		_label.text = _tool_hint()
	visible = _label.text != ""


func _tool_hint() -> String:
	match _hand.tool:
		PlayerHand.Tool.HOE:
			return "Hoe: click a plant to root it up"
		PlayerHand.Tool.LOOK:
			return _hand.inspect_text if _hand.inspect_text != "" else "Look: click something"
		PlayerHand.Tool.BUCKET:
			return "Bucket: click dry plants"
		PlayerHand.Tool.SHEARS:
			return "Shears: click ripe plants"
		PlayerHand.Tool.SEEDS:
			return "%s seeds: click an empty plot" % _hand.seed_crop.display_name
	return ""
