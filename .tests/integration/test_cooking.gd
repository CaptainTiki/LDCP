extends GutTest
## Cooking from whatever is on hand: gruel takes one of any crop and rough
## mash two, so the kitchen only stops when the hall has no crops at all.
## "Any crop" takes the cheapest to sell first, then whatever there's most of.

const GAME_SCENE: PackedScene = preload("res://game/game.tscn")
const KITCHEN: BuildingDef = preload("res://data/buildings/kitchen.tres")
const POTATO: ItemDef = preload("res://data/items/potato.tres")
const CARROT: ItemDef = preload("res://data/items/carrot.tres")
const ONION: ItemDef = preload("res://data/items/onion.tres")
const WHEAT: ItemDef = preload("res://data/items/wheat.tres")
const GRUEL: MealDef = preload("res://data/items/gruel.tres")
const POTATO_SOUP: MealDef = preload("res://data/items/potato_soup.tres")
const GRUEL_RECIPE: RecipeDef = preload("res://data/recipes/gruel.tres")
const POTATO_SOUP_RECIPE: RecipeDef = preload("res://data/recipes/potato_soup.tres")
const ROUGH_MASH_RECIPE: RecipeDef = preload("res://data/recipes/rough_mash.tres")

var game: Game
var world: World
var storage: Storage


func before_each() -> void:
	game = add_child_autofree(GAME_SCENE.instantiate())
	game.clock.set_process(false)
	world = game.world
	storage = world.hall.storage
	# Only what each test adds: no starting gruel to muddle the counts.
	storage.remove(GRUEL, storage.count(GRUEL))
	for dwarf: Dwarf in world.dwarves.active():
		dwarf.hunger.fill(100000.0)


func after_each() -> void:
	await wait_physics_frames(2)


func _run_seconds(seconds: float) -> void:
	game.clock.advance(roundi(seconds / game.clock.tick_seconds))


func _kitchen_with_cook() -> Workstation:
	var kitchen: Building = world.surface.build(KITCHEN, Vector2i(40, 1)) as Building
	world.dwarves.active()[0].assignment.assign(kitchen)
	return kitchen.workstations()[0]


func test_a_cook_makes_gruel_from_any_crop_when_nothing_better_will_do() -> void:
	_kitchen_with_cook()
	storage.add(WHEAT, 3)
	_run_seconds(GRUEL_RECIPE.process_seconds * 3 + 240)
	assert_eq(storage.count(WHEAT), 0, "wheat isn't a meal ingredient, but it makes gruel")
	assert_eq(storage.count(GRUEL), 3, "one gruel a crop")


func test_potato_soup_beats_gruel_once_there_are_two_potatoes() -> void:
	_kitchen_with_cook()
	storage.add(POTATO, POTATO_SOUP_RECIPE.needs(POTATO))
	_run_seconds(200)
	assert_eq(storage.count(POTATO_SOUP), 1, "the best he can make from two potatoes")
	assert_eq(storage.count(GRUEL), 0, "not two gruels")
	assert_gt(POTATO_SOUP.shift_seconds / POTATO_SOUP_RECIPE.needs(POTATO),
			GRUEL.shift_seconds / GRUEL_RECIPE.inputs[0].count, "and more food per potato than gruel")


func test_any_crop_takes_the_cheapest_then_the_most_plentiful() -> void:
	var stack: ItemStack = GRUEL_RECIPE.inputs[0]
	storage.add(ONION, 5)
	storage.add(POTATO, 1)
	assert_eq(stack.pick_from(storage), POTATO, "onions sell for more, so a potato goes in first")
	storage.add(CARROT, 3)
	assert_eq(stack.pick_from(storage), CARROT, "carrots and potatoes sell the same: more carrots")
	assert_eq(stack.available_in(storage), 9, "every crop counts")


func test_rough_mash_takes_a_mix_and_a_cancel_hands_back_exactly_that() -> void:
	game.wallet.earn(500)
	world.ledger.record_made(GRUEL, 10)
	game.shop.unlock_building(load("res://data/buildings/brewery.tres") as BuildingDef)
	var brewery: Building = world.surface.build(load("res://data/buildings/brewery.tres") as BuildingDef,
			Vector2i(40, 1)) as Building
	var pot: Workstation = brewery.workstations()[0]
	storage.add(CARROT, 1)
	storage.add(WHEAT, 1)
	assert_true(RecipeChooser.can_make(ROUGH_MASH_RECIPE, storage), "one carrot and one wheat make a mash")
	world.camera.show_interior(brewery)
	pot.player_recipe = ROUGH_MASH_RECIPE
	var clicks: int = 0
	while pot.state != Workstation.State.PROCESSING and clicks < 100:
		world.input.click(pot.global_position + Vector2(8, 8))
		clicks += 1
	assert_eq(storage.count(CARROT) + storage.count(WHEAT), 0, "both went in")
	assert_true(pot.cancel_batch())
	assert_eq(storage.count(CARROT), 1, "the carrot came back")
	assert_eq(storage.count(WHEAT), 1, "and the wheat")
