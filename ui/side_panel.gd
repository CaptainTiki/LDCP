class_name SidePanel
extends PanelContainer
## The fold-out panel on the right, laid out like Rusty's: a column of tabs
## down its left edge and the chosen tab's page beside it. The X at the top
## folds the page away. Picking any tab opens it again.
##
## Inside any building the usual tabs give way to the room tab, and they
## come back on the way out.

@onready var _pages: TabContainer = $Row/Pages
@onready var _close_button: Button = $Row/TabColumn/CloseButton
@onready var _room_button: Button = $Row/TabColumn/RoomButton
## In the same order as the pages.
@onready var _tab_buttons: Array[Button] = [
	$Row/TabColumn/FarmButton as Button,
	$Row/TabColumn/OresButton as Button,
	$Row/TabColumn/BuildButton as Button,
	$Row/TabColumn/ShopButton as Button,
	$Row/TabColumn/DebugButton as Button,
	$Row/TabColumn/OptionsButton as Button,
	$Row/TabColumn/RoomButton as Button,
]
## Tabs that stay put indoors.
@onready var _always_shown: Array[Button] = [$Row/TabColumn/OptionsButton as Button]

var _camera: ViewCamera
## The tab to go back to on stepping outside.
var _outdoor_tab: int = 0


func _ready() -> void:
	_close_button.pressed.connect(close)
	for i: int in _tab_buttons.size():
		_tab_buttons[i].pressed.connect(open_tab.bind(i))
	_room_button.visible = false
	open_tab(0)


func setup(camera: ViewCamera) -> void:
	_camera = camera
	camera.view_changed.connect(_on_view_changed)


func open_tab(index: int) -> void:
	_pages.current_tab = index
	_pages.visible = true
	_refresh()


func close() -> void:
	_pages.visible = false
	_refresh()


func _on_view_changed() -> void:
	var indoors: bool = _camera.interior_building != null
	if indoors == _room_button.visible:
		return
	for button: Button in _tab_buttons:
		button.visible = (button == _room_button) == indoors or _always_shown.has(button)
	if indoors:
		_outdoor_tab = _pages.current_tab
		open_tab(_tab_buttons.find(_room_button))
	else:
		open_tab(_outdoor_tab)


func _refresh() -> void:
	_close_button.disabled = not _pages.visible
	for i: int in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(_pages.visible and i == _pages.current_tab)
