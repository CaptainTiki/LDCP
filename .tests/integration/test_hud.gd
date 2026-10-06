extends GutTest
## The HUD: it fits the canvas however much the town has, the top bar shows
## the town at a glance, the Inventory tab sells, the Look tool pops up what
## things are up to, and the tabs zigzag down the side panel.

const GAME_SCENE: PackedScene = preload("res://game/game.tscn")
const POTATO: ItemDef = preload("res://data/items/potato.tres")
const GRUEL: MealDef = preload("res://data/items/gruel.tres")
const POTATO_CROP: CropDef = preload("res://data/crops/potato.tres")
const KITCHEN: BuildingDef = preload("res://data/buildings/kitchen.tres")
const GRUEL_RECIPE: RecipeDef = preload("res://data/recipes/gruel.tres")
const ONION_SOUP_RECIPE: RecipeDef = preload("res://data/recipes/onion_soup.tres")
const PAGES: String = "Root/Layout/SidePanel/Row/Pages/"
const TABS: String = "Root/Layout/SidePanel/Row/TabColumn/Tabs/"

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


## The middle of a station's or plot's clickable area.
func _middle_of(thing: Node) -> Vector2:
	var clickable: Clickable = thing.get_node("Clickable")
	return clickable.global_position + clickable.size / 2.0


## The top bar's chips, in order: coins, plants growing, idle dwarves.
func _chip_text(index: int) -> String:
	var chips: Array[Node] = game.hud.get_node("Root/Layout/Middle/TopBar/StatusReadout").get_children().filter(
			func(child: Node) -> bool: return child is ResourceChip)
	return (chips[index].get_node("Row/Value") as Label).text


func test_the_hud_fits_the_screen_however_much_the_town_has() -> void:
	var layout: Control = game.hud.get_node("Root/Layout")
	var width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	for item: ItemDef in game.catalog.items:
		storage.add(item, 9999)
	game.wallet.earn(999999)
	await wait_process_frames(2)
	assert_lte(layout.get_combined_minimum_size().x, width, "in town, with one of everything in the hall")
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	world.camera.show_interior(kitchen)
	var stove: Workstation = kitchen.workstations()[0]
	stove.start_batch(ONION_SOUP_RECIPE)
	world.hand.use_station(stove, 0.0)
	await wait_process_frames(2)
	assert_lte(layout.get_combined_minimum_size().x, width, "in a kitchen, with a stove's recipes showing")


func test_the_top_bar_shows_the_town_at_a_glance() -> void:
	var plots: int = world.surface.farm_plots().size()
	_run_seconds(1)
	game.wallet.earn(1)
	assert_eq(_chip_text(0), str(game.wallet.coins))
	assert_eq(_chip_text(1), "0/%d" % plots, "nothing sown yet")
	assert_eq(_chip_text(2), str(world.dwarves.active_count()), "nobody has a job yet, so everyone is idle")
	world.surface.farm_plots()[0].sow(POTATO_CROP)
	world.dwarves.active()[0].assignment.assign(world.surface.farm_plots()[0])
	_run_seconds(1)
	game.wallet.earn(1)
	assert_eq(_chip_text(1), "1/%d" % plots, "one plant growing")
	assert_eq(_chip_text(2), str(world.dwarves.active_count() - 1), "the farmer has work")


func test_the_inventory_tab_lists_the_hall_and_sells_from_it() -> void:
	var inventory: InventoryTab = game.hud.get_node(PAGES + "Inventory")
	var label: Label = inventory.get_node("SellBar/Label")
	var all_button: Button = inventory.get_node("SellBar/AllButton")
	var potato_slot: StockSlot = null
	for slot: Node in inventory.get_node("Scroll/Grid").get_children():
		if (slot as StockSlot).item == POTATO:
			potato_slot = slot
	assert_false(potato_slot.visible, "nothing shown that the hall doesn't hold")
	storage.add(POTATO, 10)
	assert_true(potato_slot.visible)
	inventory.pick(POTATO)
	assert_true(potato_slot.button_pressed, "the picked square stays pressed")
	var coins: int = game.wallet.coins
	inventory.sell(false)
	assert_eq(storage.count(POTATO), 9)
	assert_eq(game.wallet.coins, coins + POTATO.sell_price)
	inventory.sell(true)
	assert_eq(storage.count(POTATO), 0, "sell all")
	assert_eq(game.wallet.coins, coins + 10 * POTATO.sell_price)
	assert_false(potato_slot.visible, "sold out, so the square goes")
	assert_eq(label.text, "Pick something to sell")
	inventory.pick(GRUEL)
	assert_string_contains(label.text, "not for sale")
	assert_true(all_button.disabled)


func test_the_look_tool_pops_up_what_a_station_is_up_to() -> void:
	var card: LookCard = game.hud.get_node("Root/LookCard")
	var look_button: LookButton = game.hud.get_node("Root/Layout/Middle/TopBar/LookButton")
	game.wallet.earn(500)
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	world.camera.show_interior(kitchen)
	var stove: Workstation = kitchen.workstations()[0]
	stove.start_batch(GRUEL_RECIPE)
	storage.add(POTATO, 5)
	world.input.hover(_middle_of(stove))
	assert_true(card.current_lines().is_empty(), "without the glass, hovering shows nothing")
	world.hand.select(PlayerHand.Tool.LOOK)
	assert_true(look_button.button_pressed, "the top bar's glass shows it's in hand")
	world.input.hover(_middle_of(stove))
	var lines: PackedStringArray = card.current_lines()
	assert_eq(lines[0], stove.def.display_name)
	assert_has(lines, "1 Potato > 1 Gruel", "its recipe")
	assert_has(lines, stove.status_text(), "and what it's up to")
	await wait_process_frames(2)
	assert_true(card.visible)
	world.input.click(_middle_of(stove))
	assert_false(world.hand.is_holding_tool(), "a click puts the glass away")
	assert_eq(stove.receiver.ratio(), 0.0, "without loading the stove")
	assert_false(look_button.button_pressed)
	await wait_process_frames(2)
	assert_false(card.visible)


func test_the_pop_up_reminds_where_crops_in_hand_go() -> void:
	var card: LookCard = game.hud.get_node("Root/LookCard")
	world.hand.carrier.add(POTATO, 6)
	assert_eq(card.current_lines()[0], "6 Potato in hand")


func test_tabs_zigzag_down_the_side_panel() -> void:
	await wait_process_frames(2)
	var close: Control = game.hud.get_node(TABS + "CloseButton")
	var farm: Control = game.hud.get_node(TABS + "FarmButton")
	var build: Control = game.hud.get_node(TABS + "BuildButton")
	var ores: Control = game.hud.get_node(TABS + "OresButton")
	var inventory: Control = game.hud.get_node(TABS + "InventoryButton")
	assert_gt(close.position.x, farm.position.x, "the X top right, the first tab to its left")
	assert_eq(build.position.x, close.position.x, "then right")
	assert_eq(ores.position.x, farm.position.x, "then left")
	assert_eq(inventory.position.x, close.position.x, "then right again")
	var buttons: Array[Control] = [close, farm, build, ores, inventory]
	for i: int in buttons.size() - 1:
		assert_lt(buttons[i].position.y, buttons[i + 1].position.y, "each a step lower")
		for other: Control in buttons.slice(i + 1):
			assert_false(buttons[i].get_rect().intersects(other.get_rect()), "and none overlap")
	var first_tab_spot: Vector2 = farm.position
	world.camera.show_interior(world.hall)
	await wait_process_frames(2)
	var room: Control = game.hud.get_node(TABS + "RoomButton")
	assert_eq(room.position, first_tab_spot, "indoors, the room tab closes up under the X")
