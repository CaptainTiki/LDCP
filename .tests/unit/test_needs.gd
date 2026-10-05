extends GutTest
## Hunger is shift length, thirst is work rate.

const GROG: DrinkDef = preload("res://data/items/grog.tres")
const ALE: DrinkDef = preload("res://data/items/ale.tres")
const COGNAC: DrinkDef = preload("res://data/items/cognac.tres")
const STEW: MealDef = preload("res://data/items/stew.tres")
const GRUEL: MealDef = preload("res://data/items/gruel.tres")


func test_meal_sets_shift_length() -> void:
	var hunger: Hunger = autofree(Hunger.new())
	assert_true(hunger.is_empty(), "a new dwarf has an empty belly")
	hunger.eat(STEW)
	assert_eq(hunger.seconds_left, STEW.shift_seconds)
	hunger.sim_tick(STEW.shift_seconds - 1.0)
	assert_false(hunger.is_empty())
	hunger.sim_tick(2.0)
	assert_true(hunger.is_empty())
	assert_eq(hunger.seconds_left, 0.0, "hunger never goes negative")


func test_stew_outlasts_gruel() -> void:
	assert_gt(STEW.shift_seconds, GRUEL.shift_seconds)


func test_no_drink_means_floor_rate() -> void:
	var thirst: Thirst = autofree(Thirst.new())
	assert_eq(thirst.multiplier(), 0.5)


func test_fresh_drink_starts_at_its_high() -> void:
	var thirst: Thirst = autofree(Thirst.new())
	thirst.drink_up(ALE)
	assert_almost_eq(thirst.multiplier(), ALE.high_multiplier, 0.01)
	thirst.drink_up(GROG)
	assert_almost_eq(thirst.multiplier(), GROG.high_multiplier, 0.01)


func test_drink_holds_then_tapers_to_the_floor() -> void:
	var thirst: Thirst = autofree(Thirst.new())
	thirst.drink_up(ALE)
	thirst.sim_tick(ALE.duration_seconds * 0.5)
	assert_gt(thirst.multiplier(), 0.9, "still strong half way through")
	thirst.sim_tick(ALE.duration_seconds * 0.45)
	var late: float = thirst.multiplier()
	assert_between(late, 0.5, 0.8, "the slump near the end")
	thirst.sim_tick(ALE.duration_seconds)
	assert_eq(thirst.multiplier(), 0.5, "empty means the 50% floor")


func test_cognac_data_fits_the_drink_format() -> void:
	assert_eq(COGNAC.high_multiplier, 1.5)
	assert_eq(COGNAC.duration_seconds, 1800.0)
	assert_almost_eq(COGNAC.multiplier_at(0.0), 1.5, 0.01)
	assert_almost_eq(COGNAC.multiplier_at(1.0), 0.5, 0.01)
