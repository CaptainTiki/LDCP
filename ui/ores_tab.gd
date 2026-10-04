class_name OresTab
extends ScrollContainer
## The Ores tab: every ore (and later ingot) with how much is in the Great
## Hall and what it sells for. Items not found yet show as locked squares.

@export var slot_scene: PackedScene
## Locked squares shown after the known ores, as a hint of what's to come.
@export var locked_slots: int = 7
@export var lock_icon: Texture2D

var _storage: Storage

@onready var _grid: GridContainer = $Grid


func setup(game: Game) -> void:
	_storage = game.world.hall.storage
	for item: ItemDef in game.catalog.ores:
		_add_slot().setup(item)
	for i: int in locked_slots:
		_add_slot().setup_locked(lock_icon)
	_storage.changed.connect(_refresh)
	_refresh()


func _add_slot() -> ItemSlot:
	var slot: ItemSlot = slot_scene.instantiate() as ItemSlot
	_grid.add_child(slot)
	return slot


func _refresh() -> void:
	for child: Node in _grid.get_children():
		(child as ItemSlot).refresh(_storage)
