class_name LookButton
extends Button
## The magnifying glass, always in the top bar. Picking it up makes the
## cursor the Look tool: hover anything to see what it's up to. Any click in
## the world puts it away again.

var _hand: PlayerHand


func setup(hand: PlayerHand) -> void:
	_hand = hand
	hand.changed.connect(_refresh)
	_refresh()


func _pressed() -> void:
	if _hand.tool == PlayerHand.Tool.LOOK:
		_hand.put_away()
	else:
		_hand.select(PlayerHand.Tool.LOOK)


func _refresh() -> void:
	set_pressed_no_signal(_hand.tool == PlayerHand.Tool.LOOK)
