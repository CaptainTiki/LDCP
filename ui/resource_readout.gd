class_name ResourceReadout
extends HBoxContainer
## Coins, and the food and drink in the Great Hall, as chips along the top.
## Crops and ores have their own tabs. Food and drink are here because
## running out of them is what stalls the town.

@export var chip_scene: PackedScene
@export var coin_icon: Texture2D

var _wallet: Wallet
var _storage: Storage
var _coin_chip: ResourceChip
var _item_chips: Dictionary[ItemDef, ResourceChip] = {}


func setup(wallet: Wallet, storage: Storage, catalog: ContentCatalog) -> void:
	_wallet = wallet
	_storage = storage
	_coin_chip = _add_chip(coin_icon, "Coins")
	for item: ItemDef in catalog.items:
		if item is MealDef or item is DrinkDef:
			_item_chips[item] = _add_chip(item.icon, item.display_name)
	wallet.changed.connect(_refresh)
	storage.changed.connect(_refresh)
	_refresh()


func _add_chip(icon: Texture2D, tip: String) -> ResourceChip:
	var chip: ResourceChip = chip_scene.instantiate() as ResourceChip
	add_child(chip)
	chip.setup(icon, tip)
	return chip


func _refresh() -> void:
	_coin_chip.set_value(_wallet.coins)
	for item: ItemDef in _item_chips:
		var chip: ResourceChip = _item_chips[item]
		chip.set_value(_storage.count(item))
		chip.visible = _storage.count(item) > 0
