class_name HallTab
extends ScrollContainer
## The Great Hall's own tab, shown in place of the usual ones while the hall
## is open: tools and furniture along the top, then the food on the left and
## the drink on the right.

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
@onready var _foods: GridContainer = $Column/Stock/Foods
@onready var _drinks: GridContainer = $Column/Stock/Drinks


func setup(game: Game) -> void:
	_game = game
	_move_slot = _add_tool(move_icon, "Move furniture")
	_turn_slot = _add_tool(turn_icon, "Turn furniture (or right-click while holding it)")
	_destroy_slot = _add_tool(destroy_icon, "Remove furniture")
	for def: FurnitureDef in game.catalog.furniture:
		_add_tool(def.icon, def.display_name, def.cost, def)
	for item: ItemDef in game.catalog.items:
		if item is MealDef:
			_add_item(_foods, item)
		elif item is DrinkDef:
			_add_item(_drinks, item)
	game.world.furniture_tool.mode_changed.connect(_refresh)
	game.wallet.changed.connect(_refresh)
	game.world.hall.storage.changed.connect(_refresh)
	_refresh()


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
		var slot: IconSlot = child as IconSlot
		slot.refresh(_is_selected(slot), _game.wallet)
	for slot: ItemSlot in _item_slots:
		slot.refresh(_game.world.hall.storage)
