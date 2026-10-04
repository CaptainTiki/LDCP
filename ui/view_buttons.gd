class_name ViewButtons
extends HBoxContainer
## Surface / Mine buttons, plus Back when looking inside a building.

var _camera: ViewCamera

@onready var _surface_button: Button = $SurfaceButton
@onready var _mine_button: Button = $MineButton
@onready var _back_button: Button = $BackButton


func setup(camera: ViewCamera) -> void:
	_camera = camera
	_surface_button.pressed.connect(camera.show_surface)
	_mine_button.pressed.connect(camera.show_mine)
	_back_button.pressed.connect(camera.show_surface)
	camera.view_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var view: ViewCamera.View = _camera.current_view()
	_back_button.visible = view == ViewCamera.View.INTERIOR
	_surface_button.disabled = view == ViewCamera.View.SURFACE
	_mine_button.disabled = view == ViewCamera.View.MINE
