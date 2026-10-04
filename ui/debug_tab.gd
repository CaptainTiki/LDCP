class_name DebugTab
extends VBoxContainer
## Developer shortcuts: speed the sim up, hand out coins, show the ore.

@export var coin_gift: int = 100

var _game: Game

@onready var _speed_1: Button = $Speeds/Speed1
@onready var _speed_4: Button = $Speeds/Speed4
@onready var _speed_16: Button = $Speeds/Speed16
@onready var _coins_button: Button = $CoinsButton
@onready var _reveal_button: Button = $RevealButton


func setup(game: Game) -> void:
	_game = game
	_speed_1.pressed.connect(_set_speed.bind(1.0))
	_speed_4.pressed.connect(_set_speed.bind(4.0))
	_speed_16.pressed.connect(_set_speed.bind(16.0))
	_coins_button.text = "Give %d coins" % coin_gift
	_coins_button.pressed.connect(game.wallet.earn.bind(coin_gift))
	_reveal_button.pressed.connect(game.world.mine_level.reveal_all)
	_set_speed(1.0)


func _set_speed(speed: float) -> void:
	_game.clock.speed_scale = speed
	_speed_1.disabled = speed == 1.0
	_speed_4.disabled = speed == 4.0
	_speed_16.disabled = speed == 16.0
