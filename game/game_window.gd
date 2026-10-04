class_name GameWindow
extends Node
## Turns the OS window into a strip along the bottom of the primary screen,
## and keeps the game cheap to leave running all day.

## Height of the strip in screen pixels.
@export var strip_height: int = 300
## Start as the desktop strip. Turn off for a normal window while debugging.
@export var start_as_strip: bool = true
@export var max_fps: int = 30
## Toggles between the strip and a normal window at runtime.
@export var toggle_key: Key = KEY_F10

var _is_strip: bool = false


func _ready() -> void:
	Engine.max_fps = max_fps
	# Only redraw when something on screen changed.
	OS.low_processor_usage_mode = true
	if start_as_strip and DisplayServer.get_name() != "headless":
		apply_strip()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == toggle_key:
		if _is_strip:
			apply_windowed()
		else:
			apply_strip()


func apply_strip() -> void:
	var window: Window = get_window()
	var screen: int = DisplayServer.get_primary_screen()
	# The usable rect excludes the taskbar, so the strip sits just above it.
	var area: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	window.mode = Window.MODE_WINDOWED
	window.borderless = true
	window.always_on_top = true
	window.size = Vector2i(area.size.x, strip_height)
	window.position = Vector2i(area.position.x, area.end.y - strip_height)
	_is_strip = true


func apply_windowed() -> void:
	var window: Window = get_window()
	window.borderless = false
	window.always_on_top = false
	window.size = Vector2i(1280, strip_height * 2)
	window.move_to_center()
	_is_strip = false
