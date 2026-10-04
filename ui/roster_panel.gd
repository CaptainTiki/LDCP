class_name RosterPanel
extends PanelContainer
## The fold-out list of dwarves on the left. Entries can be dragged onto the
## world to assign jobs. "Here" shows only the dwarves in the current view,
## "All" shows everyone, so a farmer can be sent to the mine from anywhere.

@export var entry_scene: PackedScene

var _world: World
var _show_all: bool = true

@onready var _entries: VBoxContainer = $Row/Body/Scroll/Entries
@onready var _here_button: Button = $Row/Body/Filters/HereButton
@onready var _all_button: Button = $Row/Body/Filters/AllButton
@onready var _refresh_timer: Timer = $RefreshTimer


func setup(world: World) -> void:
	_world = world
	world.dwarves.roster_changed.connect(_rebuild)
	_here_button.pressed.connect(_set_show_all.bind(false))
	_all_button.pressed.connect(_set_show_all.bind(true))
	_refresh_timer.timeout.connect(_refresh)
	_rebuild()
	_set_show_all(true)


func _rebuild() -> void:
	for old_entry: Node in _entries.get_children():
		_entries.remove_child(old_entry)
		old_entry.queue_free()
	for dwarf: Dwarf in _world.dwarves.active():
		var entry: RosterEntry = entry_scene.instantiate() as RosterEntry
		_entries.add_child(entry)
		entry.setup(dwarf)
	_refresh()


func _set_show_all(show_all: bool) -> void:
	_show_all = show_all
	_all_button.disabled = show_all
	_here_button.disabled = not show_all
	_refresh()


func _refresh() -> void:
	for child: Node in _entries.get_children():
		var entry: RosterEntry = child as RosterEntry
		entry.visible = _show_all or _is_in_view(entry.dwarf)
		entry.refresh()


func _is_in_view(dwarf: Dwarf) -> bool:
	var cell: Vector2i = dwarf.mover.cell
	var room: BuildingInterior = _world.interiors.room_at(cell)
	match _world.camera.current_view():
		ViewCamera.View.INTERIOR:
			return room == _world.camera.interior_building.interior
		ViewCamera.View.MINE:
			return room == null and cell.y >= 0
	return room == null and cell.y < 0
