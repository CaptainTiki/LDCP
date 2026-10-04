class_name ShopTab
extends ScrollContainer
## The Shop tab: sell goods from the hall, buy emergency supplies, hire
## dwarves, and make the one-off purchases (unlocks and the lift).

@export var button_scene: PackedScene
@export var sell_row_scene: PackedScene

var _game: Game

@onready var _sell_list: VBoxContainer = $List/SellList
@onready var _buy_list: VBoxContainer = $List/BuyList
@onready var _unlock_list: VBoxContainer = $List/UnlockList
@onready var _hire_button: Button = $List/HireButton
@onready var _lift_button: Button = $List/LiftButton


func setup(game: Game) -> void:
	_game = game
	for item: ItemDef in game.catalog.items:
		if item.sell_price > 0:
			_add_sell_row(item)
		if item.buy_price > 0:
			_add_button(_buy_list, item, "Buy %s" % item.display_name, item.buy_price)
	_hire_button.pressed.connect(game.shop.hire)
	_lift_button.pressed.connect(game.shop.buy_lift)
	game.wallet.changed.connect(_refresh)
	game.world.hall.storage.changed.connect(_refresh)
	game.world.dwarves.roster_changed.connect(_refresh)
	game.unlocks.changed.connect(_rebuild_unlocks)
	_rebuild_unlocks()


func _add_sell_row(item: ItemDef) -> void:
	var row: SellRow = sell_row_scene.instantiate() as SellRow
	_sell_list.add_child(row)
	row.setup(item)
	row.sell_requested.connect(_game.shop.sell_item)


func _add_button(list: VBoxContainer, payload: Resource, label: String, cost: int) -> void:
	var button: CatalogButton = button_scene.instantiate() as CatalogButton
	list.add_child(button)
	button.setup(payload, label, cost)
	button.chosen.connect(_on_chosen)


## Lists the buildings that still need unlocking.
func _rebuild_unlocks() -> void:
	for old_button: Node in _unlock_list.get_children():
		_unlock_list.remove_child(old_button)
		old_button.queue_free()
	for def: BuildingDef in _game.catalog.buildings:
		if not _game.unlocks.is_unlocked(def):
			_add_button(_unlock_list, def, "Unlock %s" % def.display_name, def.unlock_cost)
	_refresh()


func _on_chosen(payload: Resource) -> void:
	if payload is ItemDef:
		_game.shop.buy_item(payload as ItemDef)
	elif payload is BuildingDef:
		_game.shop.unlock_building(payload as BuildingDef)


func _refresh() -> void:
	var shop: Shop = _game.shop
	for row: Node in _sell_list.get_children():
		(row as SellRow).refresh(_game.world.hall.storage)
	for list: VBoxContainer in [_buy_list, _unlock_list]:
		for button: Node in list.get_children():
			(button as CatalogButton).refresh(_game.wallet)
	_hire_button.text = "Hire a dwarf  %dc" % shop.hire_cost()
	_hire_button.disabled = not shop.can_hire()
	_lift_button.visible = not _game.world.shaft.has_lift
	_lift_button.text = "Build the lift  %dc" % shop.lift_cost()
	_lift_button.disabled = not shop.can_buy_lift()
