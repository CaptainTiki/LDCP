class_name StatusReadout
extends HBoxContainer
## The town at a glance, along the top: coins, how many plots have a plant
## in them, and how many dwarves are idle. What's in the hall is in the
## Inventory tab.

@export var chip_scene: PackedScene
@export var coin_icon: Texture2D
@export var plant_icon: Texture2D
@export var idle_icon: Texture2D

var _wallet: Wallet
var _world: World
var _coins: ResourceChip
var _plants: ResourceChip
var _idle: ResourceChip

## Plots and dwarves change without telling anyone, so they're polled.
@onready var _refresh_timer: Timer = $RefreshTimer


func setup(wallet: Wallet, world: World) -> void:
	_wallet = wallet
	_world = world
	_coins = _add_chip(coin_icon, "Coins")
	_plants = _add_chip(plant_icon, "Plants growing / farm plots")
	_idle = _add_chip(idle_icon, "Idle dwarves")
	wallet.changed.connect(_refresh)
	_refresh_timer.timeout.connect(_refresh)
	_refresh()


func _add_chip(icon: Texture2D, tip: String) -> ResourceChip:
	var chip: ResourceChip = chip_scene.instantiate() as ResourceChip
	add_child(chip)
	chip.setup(icon, tip)
	return chip


func _refresh() -> void:
	_coins.set_text(str(_wallet.coins))
	var plots: Array[FarmPlot] = _world.surface.farm_plots()
	var planted: int = plots.filter(func(plot: FarmPlot) -> bool: return plot.is_planted()).size()
	_plants.set_text("%d/%d" % [planted, plots.size()])
	var dwarves: Array[Dwarf] = _world.dwarves.active()
	_idle.set_text(str(dwarves.filter(func(dwarf: Dwarf) -> bool: return dwarf.idler.is_idle()).size()))
