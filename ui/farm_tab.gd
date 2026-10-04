class_name FarmTab
extends ScrollContainer
## The Farming tab: the player's tools along the top row, then a bag of seeds
## for every crop. Crops not unlocked yet show as locked squares.

@export var slot_scene: PackedScene
## Locked squares shown after the known crops, as a hint of what's to come.
@export var locked_slots: int = 6

@export_group("Icons")
@export var hoe_icon: Texture2D
@export var look_icon: Texture2D
@export var bucket_icon: Texture2D
@export var shears_icon: Texture2D
@export var lock_icon: Texture2D

var _game: Game

@onready var _grid: GridContainer = $Grid


func setup(game: Game) -> void:
	_game = game
	_add_slot().setup_tool(PlayerHand.Tool.HOE, hoe_icon, "Hoe: root up a plant")
	_add_slot().setup_tool(PlayerHand.Tool.LOOK, look_icon, "Look: inspect things")
	_add_slot().setup_tool(PlayerHand.Tool.BUCKET, bucket_icon, "Bucket: water plants")
	_add_slot().setup_tool(PlayerHand.Tool.SHEARS, shears_icon, "Shears: harvest ripe plants")
	for crop: CropDef in game.catalog.crops:
		_add_slot().setup_seeds(crop)
	for i: int in locked_slots:
		_add_slot().setup_locked(lock_icon)
	game.world.hand.changed.connect(_refresh)
	game.world.hall.storage.changed.connect(_refresh)
	game.wallet.changed.connect(_refresh)
	_refresh()


func _add_slot() -> FarmSlot:
	var slot: FarmSlot = slot_scene.instantiate() as FarmSlot
	_grid.add_child(slot)
	slot.chosen.connect(_on_chosen)
	return slot


## Picking what is already in hand puts it away again.
func _on_chosen(slot: FarmSlot) -> void:
	var hand: PlayerHand = _game.world.hand
	if slot.is_in_hand(hand):
		hand.put_away()
	elif slot.crop != null:
		hand.select_seeds(slot.crop)
	else:
		hand.select(slot.tool)
	_refresh()


func _refresh() -> void:
	for child: Node in _grid.get_children():
		(child as FarmSlot).refresh(_game.world.hand, _game.world.hall.storage, _game.wallet)
