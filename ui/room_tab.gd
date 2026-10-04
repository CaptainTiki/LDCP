class_name RoomTab
extends ScrollContainer
## The tab shown in place of the usual ones while a building is open. Tools
## along the top (move, turn, remove), then what can be bought for this room:
## furniture in the Great Hall, stations in a kitchen or brewery. Below, the
## stock that matters here: food and drink in the hall, a station's
## ingredients and what it makes elsewhere.

@export var slot_scene: PackedScene
@export var item_slot_scene: PackedScene
@export var move_icon: Texture2D
@export var destroy_icon: Texture2D
@export var turn_icon: Texture2D

var _game: Game
var _move_slot: IconSlot
var _destroy_slot: IconSlot
var _turn_slot: IconSlot
var _item_slots: Array[ItemSlot] = []

@onready var _tools: GridContainer = $Column/Tools
@onready var _left_stock: GridContainer = $Column/Stock/Foods
@onready var _right_stock: GridContainer = $Column/Stock/Drinks


func setup(game: Game) -> void:
	_game = game
	game.world.camera.view_changed.connect(_rebuild)
	game.world.furniture_tool.mode_changed.connect(_refresh)
	game.wallet.changed.connect(_refresh)
	game.world.hall.storage.changed.connect(_refresh)


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
		for def: WorkstationDef in building.def.workstations:
			if not left.has(def.input):
				left.append(def.input)
			if not right.has(def.output):
				right.append(def.output)
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


func _refresh() -> void:
	for child: Node in _tools.get_children():
		if not child.is_queued_for_deletion():
			var slot: IconSlot = child as IconSlot
			slot.refresh(_is_selected(slot), _game.wallet)
	for slot: ItemSlot in _item_slots:
		slot.refresh(_game.world.hall.storage)
