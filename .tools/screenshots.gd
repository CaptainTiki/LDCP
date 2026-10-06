extends SceneTree
## Dev tool: runs the game for a while at high speed and saves a screenshot
## of each view, so layout changes can be checked without playing.
##
## Usage: godot --path . -s .tools/screenshots.gd -- <output folder>

const GAME_SCENE: String = "res://game/game.tscn"

var _out_dir: String = "user://"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		_out_dir = args[0]
	_run.call_deferred()


func _run() -> void:
	var game: Game = (load(GAME_SCENE) as PackedScene).instantiate() as Game
	root.add_child(game)
	await _frames(5)
	var world: World = game.world
	var crew: Array[Dwarf] = world.dwarves.active()
	crew[0].assignment.assign(world.surface.farm_plots()[0])
	crew[1].assignment.assign(world.mine_entrance)
	crew[2].assignment.assign(world.mine_entrance)
	world.hall.storage.add(load("res://data/items/stew.tres") as ItemDef, 30)
	var plots: Array[FarmPlot] = world.surface.farm_plots()
	plots[0].sow(load("res://data/crops/potato.tres") as CropDef)
	plots[1].sow(load("res://data/crops/potato.tres") as CropDef)
	plots[2].sow(load("res://data/crops/barley.tres") as CropDef)
	plots[3].sow(load("res://data/crops/barley.tres") as CropDef)

	game.clock.advance(450)
	world.ledger.record_harvest(load("res://data/items/potato.tres") as ItemDef, 20)
	await _frames(20)
	var spot: Vector2 = crew[0].global_position + Vector2(0, -8)
	root.warp_mouse(root.get_canvas_transform() * spot)
	world.input.hover(spot)
	await _frames(4)
	await _shot("surface")
	world.input.hover_ended()
	game.clock.advance(6000)
	world.camera.show_mine()
	await _shot("mine")
	world.camera.show_interior(world.hall)
	await _shot("hall")
	world.camera.show_surface()
	game.wallet.earn(500)
	var kitchen: Building = world.surface.build(load("res://data/buildings/kitchen.tres") as BuildingDef, Vector2i(46, 2)) as Building
	await _shot("surface_later")
	world.camera.show_interior(kitchen)
	await _shot("kitchen")
	world.ledger.record_made(load("res://data/items/stew.tres") as ItemDef, 10)
	game.unlocks.trade(load("res://data/buildings/brewery.tres") as BuildingDef)
	var brewery: Building = world.surface.build(load("res://data/buildings/brewery.tres") as BuildingDef, Vector2i(40, 2)) as Building
	world.hall.storage.add(load("res://data/items/barley.tres") as ItemDef, 6)
	world.camera.show_interior(brewery)
	var pot: Workstation = brewery.workstations()[0]
	var fermenter: Workstation = brewery.workstations()[1]
	pot.start_batch(load("res://data/recipes/barley_mash.tres") as RecipeDef)
	pot.receiver.apply_work(100.0)
	game.clock.advance(320)
	fermenter.pour_from(pot)
	fermenter.receiver.apply_work(100.0)
	pot.start_batch(load("res://data/recipes/barley_mash.tres") as RecipeDef)
	pot.receiver.apply_work(2.0)
	game.clock.advance(300)
	world.input.click(pot.global_position + Vector2(8, 8))
	await _frames(10)
	await _shot("brewery")
	# The Look tool's pop-up over the fermenter.
	world.hand.select(PlayerHand.Tool.LOOK)
	var clickable: Clickable = fermenter.get_node("Clickable")
	var middle: Vector2 = clickable.global_position + clickable.size / 2.0
	root.warp_mouse(root.get_canvas_transform() * middle)
	world.input.hover(middle)
	await _frames(4)
	await _shot("brewery_look")
	world.hand.put_away()
	world.camera.show_surface()
	(game.hud.get_node("Root/Layout/SidePanel/Row/TabColumn/Tabs/InventoryButton") as Button).pressed.emit()
	await _shot("inventory")
	# The market: a trader selling potatoes above a keep of 10.
	world.ledger.record_sold(load("res://data/items/potato.tres") as ItemDef, 30)
	var market_def: BuildingDef = load("res://data/buildings/market.tres")
	game.unlocks.trade(market_def)
	var market: Market = world.surface.build(market_def, Vector2i(34, 2)) as Market
	market.set_keep(load("res://data/items/potato.tres") as ItemDef, 10)
	crew[3].assignment.assign(market)
	game.clock.advance(600)
	world.camera.show_interior(market)
	await _shot("market")
	quit()


func _shot(name: String) -> void:
	await _frames(4)
	var image: Image = root.get_texture().get_image()
	image.save_png(_out_dir.path_join(name + ".png"))


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
