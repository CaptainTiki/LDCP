class_name SidePanel
extends PanelContainer
## The fold-out panel on the right, laid out like Rusty's: a column of tabs
## down its left edge and the chosen tab's page beside it. The X at the top
## folds the page away. Picking any tab opens it again.

@onready var _pages: TabContainer = $Row/Pages
@onready var _close_button: Button = $Row/TabColumn/CloseButton
## In the same order as the pages.
@onready var _tab_buttons: Array[Button] = [
	$Row/TabColumn/FarmButton as Button,
	$Row/TabColumn/OresButton as Button,
	$Row/TabColumn/BuildButton as Button,
	$Row/TabColumn/ShopButton as Button,
	$Row/TabColumn/DebugButton as Button,
	$Row/TabColumn/OptionsButton as Button,
]


func _ready() -> void:
	_close_button.pressed.connect(close)
	for i: int in _tab_buttons.size():
		_tab_buttons[i].pressed.connect(open_tab.bind(i))
	open_tab(0)


func open_tab(index: int) -> void:
	_pages.current_tab = index
	_pages.visible = true
	_refresh()


func close() -> void:
	_pages.visible = false
	_refresh()


func _refresh() -> void:
	_close_button.disabled = not _pages.visible
	for i: int in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(_pages.visible and i == _pages.current_tab)
