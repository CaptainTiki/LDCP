class_name RosterEntry
extends PanelContainer
## One dwarf in the roster: portrait, job badge, and food and drink bars.
## The name and status are in the tooltip. Drag it onto a workplace to
## assign the dwarf.

var dwarf: Dwarf

@onready var _portrait: ColorRect = $Column/Top/Portrait
@onready var _badge: Label = $Column/Top/Badge
@onready var _name: Label = $Column/Name
@onready var _food: ProgressBar = $Column/Food
@onready var _drink: ProgressBar = $Column/Drink


func setup(for_dwarf: Dwarf) -> void:
	dwarf = for_dwarf
	_name.text = dwarf.dwarf_name
	_portrait.color = dwarf.color
	refresh()


func refresh() -> void:
	_badge.text = dwarf.job_badge()
	_food.value = dwarf.hunger.ratio()
	_drink.value = dwarf.thirst.ratio()
	var work_rate: int = roundi(dwarf.thirst.multiplier() * 100.0)
	tooltip_text = "%s\n%s\nWork rate %d%%" % [dwarf.dwarf_name, dwarf.status_text(), work_rate]


func _get_drag_data(_at_position: Vector2) -> Variant:
	# The name is hidden in the entry, but follows the cursor while dragging.
	var preview: Label = _name.duplicate() as Label
	preview.visible = true
	set_drag_preview(preview)
	return dwarf
