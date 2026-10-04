class_name ResourceReadout
extends Label
## Coins and what is in the Great Hall, as one line of text.

var _wallet: Wallet
var _storage: Storage
var _catalog: ContentCatalog


func setup(wallet: Wallet, storage: Storage, catalog: ContentCatalog) -> void:
	_wallet = wallet
	_storage = storage
	_catalog = catalog
	wallet.changed.connect(_refresh)
	storage.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var parts: PackedStringArray = ["Coins %d" % _wallet.coins]
	for item: ItemDef in _catalog.items:
		if _storage.count(item) > 0:
			parts.append("%s %d" % [item.display_name, _storage.count(item)])
	text = "   ".join(parts)
