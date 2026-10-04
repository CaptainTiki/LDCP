class_name RoomTab
extends ScrollContainer
## The tab shown in place of the usual ones while a building is open. Tools
## along the top (move, turn, remove), then what can be bought for this room:
## furniture in the Great Hall, stations in a kitchen or brewery. Below, the
## stock that matters here: food and drink in the hall, a station's
## ingredients and what it makes elsewhere.

@export var slot_scene: PackedScene
@export var item_slot_scene: PackedScene
@export var recipe_slot_scene: PackedScene
@export var move_icon: Texture2D
@export var destroy_icon: Texture2D
@export var turn_icon: Texture2D

var _game: Game
var _move_slot: IconSlot
var _destroy_slot: IconSlot
var _turn_slot: IconSlot
var _item_slots: Array[ItemSlot] = []
## The station whose recipes are listed.
var _shown_station: Workstation = null

@onready var _tools: GridContainer = $Column/Tools
@onready var _left_stock: GridContainer = $Column/Stock/Foods
@onready var _right_stock: GridContainer = $Column/Stock/Drinks
@onready var _station_panel: VBoxContainer = $Column/Station
@onready var _station_title: Label = $Column/Station/Title
@onready var _recipes: GridContainer = $Column/Station/Recipes


func setup(game: Game) -> void:
	_game = game
	game.world.camera.view_changed.connect(_rebuild)
	game.world.furniture_tool.mode_changed.connect(_refresh)
	game.wallet.changed.connect(_refresh)
	game.world.hall.storage.changed.connect(_refresh)
	game.world.hand.changed.connect(_refresh)
	game.unlocks.changed.connect(_on_unlocks_changed)


## Fills the tab for whichever building is open.
func _rebuild() -> void:
	var building: Building = _game.world.camera.interior_building
	if building == null:
		return
	for list: GridContainer in [_tools, _left_stock, _right_stock]:
		for child: Node in list.get_children():
			list.remove_child(child)
			child.queue_free()
	_item_slots.clear()
	_move_slot = _add_tool(move_icon, "Move")
	_turn_slot = _add_tool(turn_icon, "Turn (or right-click while holding it)")
	_destroy_slot = _add_tool(destroy_icon, "Remove")
	for def: FurnitureDef in _buyable_in(building):
		_add_tool(def.icon, def.display_name, def.cost, def)
	var stock: Array[Array] = _stock_for(building)
	for item: ItemDef in stock[0]:
		_add_item(_left_stock, item)
	for item: ItemDef in stock[1]:
		_add_item(_right_stock, item)
	_refresh()


func _buyable_in(building: Building) -> Array[FurnitureDef]:
	var defs: Array[FurnitureDef] = []
	if building is GreatHall:
		defs.assign(_game.catalog.furniture)
	else:
		defs.assign(building.def.workstations)
	return defs


## [left column, right column]: food and drink in the hall; elsewhere, what
## the room's stations take and what they make.
func _stock_for(building: Building) -> Array[Array]:
	var left: Array[ItemDef] = []
	var right: Array[ItemDef] = []
	if building is GreatHall:
		for item: ItemDef in _game.catalog.items:
			if item is MealDef:
				left.append(item)
			elif item is DrinkDef:
				right.append(item)
	else:
		# Left: what comes in from storage. Right: what the building sends
		# out (not the mash that only passes from pot to fermenter).
		var passed_on: Array[ItemDef] = []
		for def: WorkstationDef in building.def.workstations:
			if def.fed_by != null:
				for r: RecipeDef in def.recipes:
					for stack: ItemStack in r.inputs:
						passed_on.append(stack.item)
		for def: WorkstationDef in building.def.workstations:
			for r: RecipeDef in def.recipes:
				for stack: ItemStack in r.inputs:
					if def.fed_by == null and not left.has(stack.item):
						left.append(stack.item)
				if not passed_on.has(r.output) and not right.has(r.output):
					right.append(r.output)
	return [left, right]


func _add_tool(icon: Texture2D, tip: String, price: int = -1, payload: Resource = null) -> IconSlot:
	var slot: IconSlot = slot_scene.instantiate() as IconSlot
	_tools.add_child(slot)
	slot.setup(icon, tip, price, payload)
	slot.chosen.connect(_on_chosen)
	return slot


func _add_item(column: GridContainer, item: ItemDef) -> void:
	var slot: ItemSlot = item_slot_scene.instantiate() as ItemSlot
	column.add_child(slot)
	slot.setup(item, false)
	_item_slots.append(slot)


## Picking the tool already in hand puts it away again.
func _on_chosen(slot: IconSlot) -> void:
	var tool: FurnitureTool = _game.world.furniture_tool
	if _is_selected(slot):
		tool.cancel()
	elif slot == _move_slot:
		tool.start_move()
	elif slot == _turn_slot:
		tool.start_turn()
	elif slot == _destroy_slot:
		tool.start_destroy()
	else:
		tool.start_place(slot.payload as FurnitureDef)
	_refresh()


func _is_selected(slot: IconSlot) -> bool:
	var tool: FurnitureTool = _game.world.furniture_tool
	match tool.mode:
		FurnitureTool.Mode.MOVE:
			return slot == _move_slot
		FurnitureTool.Mode.TURN:
			return slot == _turn_slot
		FurnitureTool.Mode.DESTROY:
			return slot == _destroy_slot
		FurnitureTool.Mode.PLACE:
			return slot.payload != null and slot.payload == tool.place_def
	return false


## Lists the recipes of the station the player last clicked, if it's in
## this room.
func _refresh_station() -> void:
	var station: Workstation = _game.world.hand.selected_station
	var building: Building = _game.world.camera.interior_building
	if station != null and (not is_instance_valid(station) or building == null
			or not building.workstations().has(station)):
		station = null
	_station_panel.visible = station != null
	if station != _shown_station:
		_shown_station = station
		for child: Node in _recipes.get_children():
			_recipes.remove_child(child)
			child.queue_free()
		if station != null:
			for r: RecipeDef in station.station_def().recipes:
				if not _game.unlocks.recipe_available(r, _game.catalog):
					continue  # Appears once its crops can be grown.
				var slot: RecipeSlot = recipe_slot_scene.instantiate() as RecipeSlot
				_recipes.add_child(slot)
				slot.setup(r)
				slot.chosen.connect(_on_recipe_chosen)
	if station == null:
		return
	_station_title.text = station.def.display_name
	for child: Node in _recipes.get_children():
		(child as RecipeSlot).refresh(station, _game.world.hall.storage)


## A new crop may have put new recipes on the menu.
func _on_unlocks_changed() -> void:
	_shown_station = null
	_refresh()


func _on_recipe_chosen(recipe: RecipeDef) -> void:
	if _shown_station != null:
		_shown_station.select_recipe(recipe)
		_game.world.hand.notify_changed()


func _refresh() -> void:
	_refresh_station()
	for child: Node in _tools.get_children():
		if not child.is_queued_for_deletion():
			var slot: IconSlot = child as IconSlot
			slot.refresh(_is_selected(slot), _game.wallet)
	for slot: ItemSlot in _item_slots:
		slot.refresh(_game.world.hall.storage)
