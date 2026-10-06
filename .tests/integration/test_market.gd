extends GutTest
## The market: unlocked by selling by hand, it sells the hall's surplus over
## the player's keep numbers through a trader, one load at a time.

const GAME_SCENE: PackedScene = preload("res://game/game.tscn")
const MARKET: BuildingDef = preload("res://data/buildings/market.tres")
const KITCHEN: BuildingDef = preload("res://data/buildings/kitchen.tres")
const POTATO: ItemDef = preload("res://data/items/potato.tres")
const MARKET_PANEL: String = "Root/Layout/SidePanel/Row/Pages/Room/Column/Market"

var game: Game
var world: World
var storage: Storage


func before_each() -> void:
	game = add_child_autofree(GAME_SCENE.instantiate())
	game.clock.set_process(false)
	world = game.world
	storage = world.hall.storage


func after_each() -> void:
	await wait_physics_frames(2)


func _run_seconds(seconds: float) -> void:
	game.clock.advance(roundi(seconds / game.clock.tick_seconds))


func _build_market() -> Market:
	world.ledger.record_sold(POTATO, 30)
	game.wallet.earn(500)
	assert_true(game.shop.unlock_building(MARKET))
	return world.surface.build(MARKET, Vector2i(40, 1)) as Market


func test_the_market_unlocks_by_selling_by_hand() -> void:
	assert_false(game.unlocks.is_unlocked(MARKET))
	game.wallet.earn(100)
	assert_false(game.shop.unlock_building(MARKET), "coins alone aren't enough")
	storage.add(POTATO, 30)
	assert_true(game.shop.sell_item(POTATO, 30))
	assert_eq(world.ledger.count(Ledger.SOLD), 30, "selling by hand counts")
	assert_true(game.shop.unlock_building(MARKET), "sell 30, then trade coins")


func test_a_trader_sells_only_what_is_above_the_keep_number() -> void:
	var market: Market = _build_market()
	for dwarf: Dwarf in world.dwarves.active():
		dwarf.hunger.fill(100000.0)
	storage.add(POTATO, 25)
	var trader: Dwarf = world.dwarves.active()[0]
	trader.assignment.assign(market)
	assert_eq(trader.assignment.kind(), JobAssignment.Kind.TRADER, "a dwarf dropped on the market trades")
	_run_seconds(60)
	assert_eq(storage.count(POTATO), 25, "nothing sells until a keep number is set")
	assert_eq(trader.status_text(), "Nothing to sell")

	var coins: int = game.wallet.coins
	var sold: int = world.ledger.count(Ledger.SOLD)
	market.set_keep(POTATO, 10)
	assert_eq(market.surplus(POTATO), 15)
	_run_seconds(400)
	assert_eq(storage.count(POTATO), 10, "the rest went to the stall")
	assert_true(market.stall().is_empty(), "and was sold")
	assert_eq(game.wallet.coins, coins + 15 * POTATO.sell_price)
	assert_eq(world.ledger.count(Ledger.SOLD), sold + 15)
	assert_eq(trader.status_text(), "Nothing to sell", "back to waiting")


func test_a_click_on_the_stall_helps_sell() -> void:
	var market: Market = _build_market()
	var stall: MarketStall = market.stall()
	var carrier: Carrier = world.hand.carrier
	carrier.add(POTATO, 2)
	assert_true(stall.deposit(carrier))
	world.camera.show_interior(market)
	var clickable: Clickable = stall.get_node("Clickable")
	var coins: int = game.wallet.coins
	var clicks: int = 0
	while not stall.is_empty() and clicks < 100:
		world.input.click(clickable.global_position + clickable.size / 2.0)
		clicks += 1
	assert_eq(game.wallet.coins, coins + 2 * POTATO.sell_price, "sold by hand, a click at a time")
	assert_eq(clicks, 2 * ceili(game.tuning.sell_work_per_item / game.tuning.manual_work_per_click))


func test_the_room_tab_lists_what_to_keep_by_category() -> void:
	var market: Market = _build_market()
	var panel: MarketPanel = game.hud.get_node(MARKET_PANEL)
	world.camera.show_interior(market)
	assert_true(panel.visible, "the market's room tab shows the keep list")
	var potato_row: KeepRow = null
	for row: KeepRow in panel.rows():
		assert_gt(row.item.sell_price, 0, "only what sells is listed")
		if row.item == POTATO:
			potato_row = row
	assert_not_null(potato_row)
	assert_eq(market.keep_of(POTATO), Market.KEEP_ALL, "everything is kept until a number is set")
	potato_row.step(-1)
	assert_eq(market.keep_of(POTATO), 100)
	potato_row.step(-1)
	assert_eq(market.keep_of(POTATO), 50)
	potato_row.step(1)
	potato_row.step(1)
	assert_eq(market.keep_of(POTATO), Market.KEEP_ALL, "and back up to keeping it all")

	world.camera.show_surface()
	game.wallet.earn(100)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(48, 1)) as Building
	world.camera.show_interior(kitchen)
	assert_false(panel.visible, "other buildings show their usual room tab")
