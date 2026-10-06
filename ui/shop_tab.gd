class_name ShopTab
extends ScrollContainer
## The Shop tab: buy emergency supplies, hire dwarves, and make the one-off
## purchases (unlocks and the lift). Selling is in the Inventory tab.

@export var button_scene: PackedScene

var _game: Game

@onready var _buy_list: VBoxContainer = $List/BuyList
@onready var _unlock_list: VBoxContainer = $List/UnlockList
@onready var _hire_button: Button = $List/HireButton
@onready var _lift_button: Button = $List/LiftButton


func setup(game: Game) -> void:
	_game = game
	for item: ItemDef in game.catalog.items:
		if item.buy_price > 0:
			_add_button(_buy_list, item, "Buy %s" % item.display_name, item.buy_price)
	_hire_button.pressed.connect(game.shop.hire)
	_lift_button.pressed.connect(game.shop.buy_lift)
	game.wallet.changed.connect(_refresh)
	game.world.dwarves.roster_changed.connect(_refresh)
	game.unlocks.changed.connect(_rebuild_unlocks)
	_rebuild_unlocks()


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
		if _game.unlocks.is_unlocked(def):
			continue
		var unlock: UnlockDef = Unlocks.unlock_of(def)
		_add_button(_unlock_list, def, "Unlock %s" % def.display_name, unlock.coins)
		var button: CatalogButton = _unlock_list.get_child(-1) as CatalogButton
		if not unlock.items.is_empty():
			# A trade for goods as well as coins: spell the price out.
			button.text = "Unlock %s: %s" % [def.display_name, unlock.describe_price()]
			button.icon = null
		if not _game.unlocks.milestone_met(def):
			# Not yet on offer: show how far along the milestone is.
			button.text = "%s: %s %d/%d" % [def.display_name, unlock.label,
					_game.unlocks.progress(def), unlock.needed]
			button.icon = null
	_refresh()


func _on_chosen(payload: Resource) -> void:
	if payload is ItemDef:
		_game.shop.buy_item(payload as ItemDef)
	elif payload is BuildingDef:
		_game.shop.unlock_building(payload as BuildingDef)


func _refresh() -> void:
	var shop: Shop = _game.shop
	for button: Node in _buy_list.get_children():
		(button as CatalogButton).refresh(_game.wallet)
	for button: Node in _unlock_list.get_children():
		var unlock_button: CatalogButton = button as CatalogButton
		unlock_button.disabled = not _game.unlocks.can_trade(unlock_button.payload)
	_hire_button.text = "Hire a dwarf  %d" % shop.hire_cost()
	_hire_button.disabled = not shop.can_hire()
	_lift_button.visible = not _game.world.shaft.has_lift
	_lift_button.text = "Build the lift  %d" % shop.lift_cost()
	_lift_button.disabled = not shop.can_buy_lift()
