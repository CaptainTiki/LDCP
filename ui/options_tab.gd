class_name OptionsTab
extends VBoxContainer
## Settings. Just the window for now.

var _window: GameWindow

@onready var _strip_check: CheckButton = $StripCheck
@onready var _quit_button: Button = $QuitButton


func setup(game: Game) -> void:
	_window = game.window
	_strip_check.toggled.connect(_on_strip_toggled)
	_quit_button.pressed.connect(get_tree().quit)
	_window.mode_changed.connect(_sync)
	_sync()


func _on_strip_toggled(on: bool) -> void:
	if on:
		_window.apply_strip()
	else:
		_window.apply_windowed()


## F10 changes the window too, so follow it.
func _sync() -> void:
	_strip_check.set_pressed_no_signal(_window.is_strip())
