class_name ViewButtons
extends HBoxContainer
## Surface / Mine buttons, Back when looking inside a building, and the
## follow-camera toggle.

var _camera: ViewCamera

@onready var _surface_button: Button = $SurfaceButton
@onready var _mine_button: Button = $MineButton
@onready var _back_button: Button = $BackButton
@onready var _follow_button: Button = $FollowButton


func setup(camera: ViewCamera) -> void:
	_camera = camera
	_surface_button.pressed.connect(camera.show_surface)
	_mine_button.pressed.connect(camera.show_mine)
	_back_button.pressed.connect(camera.show_surface)
	_follow_button.toggled.connect(camera.set_follow)
	camera.view_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var view: ViewCamera.View = _camera.current_view()
	_back_button.visible = view == ViewCamera.View.INTERIOR
	_surface_button.disabled = view == ViewCamera.View.SURFACE
	_mine_button.disabled = view == ViewCamera.View.MINE
