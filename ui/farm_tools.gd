class_name FarmTools
extends HBoxContainer
## The player's farming tools along the top of the screen: a seed bag per
## crop, the watering bucket and the harvest tool, plus a note of what has
## been harvested and is waiting to be dropped at the Great Hall.

@export var seed_button_scene: PackedScene

var _hand: PlayerHand

@onready var _seed_buttons: HBoxContainer = $SeedButtons
@onready var _bucket_button: Button = $BucketButton
@onready var _harvest_button: Button = $HarvestButton
@onready var _holding: Label = $Holding


func setup(hand: PlayerHand, catalog: ContentCatalog) -> void:
	_hand = hand
	for crop: CropDef in catalog.crops:
		var button: SeedButton = seed_button_scene.instantiate() as SeedButton
		_seed_buttons.add_child(button)
		button.setup(crop)
		button.chosen.connect(_on_seeds_chosen)
	_bucket_button.pressed.connect(_toggle.bind(PlayerHand.Tool.BUCKET))
	_harvest_button.pressed.connect(_toggle.bind(PlayerHand.Tool.HARVEST))
	hand.changed.connect(_refresh)
	_refresh()


## Picking the seeds already in hand puts them away again.
func _on_seeds_chosen(crop: CropDef) -> void:
	if _hand.tool == PlayerHand.Tool.SEEDS and _hand.seed_crop == crop:
		_hand.put_away()
	else:
		_hand.select_seeds(crop)


func _toggle(tool: PlayerHand.Tool) -> void:
	if _hand.tool == tool:
		_hand.put_away()
	elif tool == PlayerHand.Tool.BUCKET:
		_hand.select_bucket()
	else:
		_hand.select_harvest()


func _refresh() -> void:
	for child: Node in _seed_buttons.get_children():
		var button: SeedButton = child as SeedButton
		button.button_pressed = _hand.tool == PlayerHand.Tool.SEEDS and _hand.seed_crop == button.crop
	_bucket_button.button_pressed = _hand.tool == PlayerHand.Tool.BUCKET
	_harvest_button.button_pressed = _hand.tool == PlayerHand.Tool.HARVEST
	var carrier: Carrier = _hand.carrier
	_holding.visible = not carrier.is_empty()
	if not carrier.is_empty():
		_holding.text = "Holding %d %s: click the Great Hall" % [carrier.count, carrier.item.display_name]
