class_name BuildTab
extends VBoxContainer
## The Build tab: buildings and plots to place, with the move and destroy
## tools. (Inside a building, the room tab takes over.)

@export var button_scene: PackedScene

var _game: Game

@onready var _list: VBoxContainer = $Scroll/List
@onready var _move_button: Button = $Tools/MoveButton
@onready var _destroy_button: Button = $Tools/DestroyButton
@onready var _cancel_button: Button = $Tools/CancelButton
@onready var _hint: Label = $Hint


func setup(game: Game) -> void:
	_game = game
	var tool: BuildTool = game.world.build_tool
	_move_button.pressed.connect(tool.start_move)
	_destroy_button.pressed.connect(tool.start_destroy)
	_cancel_button.pressed.connect(tool.cancel)
	tool.mode_changed.connect(_update_hint)
	game.world.camera.view_changed.connect(_rebuild)
	game.unlocks.changed.connect(_rebuild)
	game.wallet.changed.connect(_refresh_prices)
	_rebuild()
	_update_hint()


func _rebuild() -> void:
	for old_button: Node in _list.get_children():
		_list.remove_child(old_button)
		old_button.queue_free()
	for def: BuildingDef in _game.catalog.buildings:
		if def.buildable and _game.unlocks.is_unlocked(def):
			_add_button(def, def.display_name, def.cost)
	_refresh_prices()


func _add_button(payload: Resource, label: String, cost: int) -> void:
	var button: CatalogButton = button_scene.instantiate() as CatalogButton
	_list.add_child(button)
	button.setup(payload, label, cost)
	button.chosen.connect(_on_chosen)


func _refresh_prices() -> void:
	for child: Node in _list.get_children():
		(child as CatalogButton).refresh(_game.wallet)


func _on_chosen(payload: Resource) -> void:
	_game.world.build_tool.start_place(payload as BuildingDef)


func _update_hint() -> void:
	match _game.world.build_tool.mode:
		BuildTool.Mode.PLACE:
			_hint.text = "Click to place. Right-click to stop."
		BuildTool.Mode.MOVE:
			_hint.text = "Click a building, then its new spot."
		BuildTool.Mode.DESTROY:
			_hint.text = "Click what to remove."
		_:
			_hint.text = ""
	_cancel_button.disabled = not _game.world.build_tool.is_active()
