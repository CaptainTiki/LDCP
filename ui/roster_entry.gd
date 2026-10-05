class_name RosterEntry
extends PanelContainer
## One dwarf in the roster: portrait, job badge, and food and drink bars.
## Hover it to point him out in the world and see his card. Drag it onto a
## workplace to assign the dwarf.

var dwarf: Dwarf

@onready var _portrait: ColorRect = $Column/Top/Portrait
@onready var _badge: Label = $Column/Top/Badge
@onready var _name: Label = $Column/Name
@onready var _food: ProgressBar = $Column/Food
@onready var _drink: ProgressBar = $Column/Drink


func setup(for_dwarf: Dwarf) -> void:
	dwarf = for_dwarf
	mouse_entered.connect(func() -> void: dwarf.world.dwarves.set_hovered(dwarf))
	mouse_exited.connect(func() -> void:
		if dwarf.world.dwarves.hovered == dwarf:
			dwarf.world.dwarves.set_hovered(null))
	_name.text = dwarf.dwarf_name
	_portrait.color = dwarf.color
	refresh()


func refresh() -> void:
	_badge.text = dwarf.job_badge()
	_food.value = dwarf.hunger.ratio()
	_drink.value = dwarf.thirst.ratio()
	# The details are on the card that appears while he's hovered.
	var lit: bool = dwarf.world.dwarves.hovered == dwarf
	self_modulate = Color(1.6, 1.4, 0.8) if lit else Color.WHITE
	_badge.modulate = Color(1.0, 0.8, 0.3) if lit else Color.WHITE


func _get_drag_data(_at_position: Vector2) -> Variant:
	# The name is hidden in the entry, but follows the cursor while dragging.
	var preview: Label = _name.duplicate() as Label
	preview.visible = true
	set_drag_preview(preview)
	return dwarf
