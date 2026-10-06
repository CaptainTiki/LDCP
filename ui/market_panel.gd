class_name MarketPanel
extends VBoxContainer
## The market's page in the room tab, in place of the stock lists: every
## item that sells, by category, with how many the hall holds and how many to
## keep. The market's trader sells the rest.

const CATEGORY_NAMES: Dictionary[ItemDef.Category, String] = {
	ItemDef.Category.CROP: "Crops",
	ItemDef.Category.MEAL: "Meals",
	ItemDef.Category.DRINK: "Drinks",
	ItemDef.Category.BREWING: "Brewing",
	ItemDef.Category.METAL: "Ore and metal",
	ItemDef.Category.TOOL: "Tools",
	ItemDef.Category.OTHER: "Other",
}

@export var row_scene: PackedScene
@export var heading_scene: PackedScene

var _market: Market = null
var _storage: Storage
var _rows: Array[KeepRow] = []

@onready var _list: VBoxContainer = $List


func setup(game: Game) -> void:
	_storage = game.world.hall.storage
	for category: ItemDef.Category in CATEGORY_NAMES:
		var items: Array[ItemDef] = []
		for item: ItemDef in game.catalog.items:
			if item.category == category and item.sell_price > 0:
				items.append(item)
		if items.is_empty():
			continue
		var heading: Label = heading_scene.instantiate() as Label
		_list.add_child(heading)
		heading.text = CATEGORY_NAMES[category]
		for item: ItemDef in items:
			var row: KeepRow = row_scene.instantiate() as KeepRow
			_list.add_child(row)
			row.setup(item)
			row.keep_changed.connect(_refresh)
			_rows.append(row)
	_storage.changed.connect(_refresh)


## Shows the list for `market`, or hides it for any other building.
func show_for(market: Market) -> void:
	_market = market
	visible = market != null
	_refresh()


func rows() -> Array[KeepRow]:
	return _rows


func _refresh() -> void:
	if _market == null or not is_instance_valid(_market):
		return
	for row: KeepRow in _rows:
		row.refresh(_market, _storage)
