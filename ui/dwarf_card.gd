class_name DwarfCard
extends CursorCard
## A small card that follows the cursor while a dwarf is hovered, in the
## world or in the roster: who he is, what he's doing, his food and drink,
## what he's carrying and his tool.

var _pool: DwarfPool

@onready var _name: Label = $Column/Name
@onready var _status: Label = $Column/Status
@onready var _food: ProgressBar = $Column/FoodRow/Bar
@onready var _drink: ProgressBar = $Column/DrinkRow/Bar
@onready var _drink_label: Label = $Column/DrinkRow/Label
@onready var _carrying: Label = $Column/Carrying
@onready var _tool: Label = $Column/Tool


func setup(pool: DwarfPool) -> void:
	_pool = pool
	pool.hover_changed.connect(_on_hover_changed)
	_on_hover_changed()


func _on_hover_changed() -> void:
	visible = _pool.hovered != null
	set_process(visible)
	if visible:
		_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var dwarf: Dwarf = _pool.hovered
	_name.text = dwarf.dwarf_name
	_status.text = dwarf.status_text()
	_food.value = dwarf.hunger.ratio()
	_drink.value = dwarf.thirst.ratio()
	var drink_name: String = dwarf.thirst.drink.display_name if dwarf.thirst.ratio() > 0.0 else "Thirsty"
	_drink_label.text = "%s %d%%" % [drink_name, roundi(dwarf.thirst.multiplier() * 100.0)]
	var carrier: Carrier = dwarf.carrier
	_carrying.text = "Carrying %d %s" % [carrier.count, carrier.item.display_name] if not carrier.is_empty() else "Carrying nothing"
	_tool.text = "Tool: %s" % (dwarf.tool.display_name if dwarf.tool != null else "old pick")
	follow_cursor()
