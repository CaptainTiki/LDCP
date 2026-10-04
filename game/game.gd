class_name Game
extends Node
## The root of the running game. It owns the clock, the economy, the world
## and the HUD, and passes each one the references it needs. Nothing here is
## an autoload: ownership flows down from this scene.

@export var tuning: GameTuning
@export var catalog: ContentCatalog

@onready var clock: SimClock = $SimClock
@onready var wallet: Wallet = $Wallet
@onready var unlocks: Unlocks = $Unlocks
@onready var shop: Shop = $Shop
@onready var world: World = $World
@onready var hud: Hud = $Hud


func _ready() -> void:
	wallet.coins = tuning.starting_coins
	world.setup(tuning, clock, wallet)
	for stack: ItemStack in tuning.starting_stock:
		world.hall.storage.add(stack.item, stack.count)
	shop.setup(wallet, unlocks, world, tuning)
	hud.setup(self)
	clock.ticked.connect(world.sim_tick)
