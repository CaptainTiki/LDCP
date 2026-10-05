extends GutTest
## WorkReceiver, Storage and Carrier basics.

const POTATO: ItemDef = preload("res://data/items/potato.tres")
const BARLEY: ItemDef = preload("res://data/items/barley.tres")
const STEW: MealDef = preload("res://data/items/stew.tres")
const GRUEL: MealDef = preload("res://data/items/gruel.tres")


func test_receiver_completes_when_enough_work_is_applied() -> void:
	var receiver: WorkReceiver = autofree(WorkReceiver.new())
	receiver.reset(3.0)
	watch_signals(receiver)
	receiver.apply_work(2.0)
	assert_signal_not_emitted(receiver, "completed")
	assert_almost_eq(receiver.ratio(), 0.667, 0.01)
	receiver.apply_work(1.0)
	assert_signal_emitted(receiver, "completed")
	assert_eq(receiver.progress, 0.0, "ready for the next job")


func test_receiver_claim_is_exclusive() -> void:
	var receiver: WorkReceiver = autofree(WorkReceiver.new())
	var first: Node = autofree(Node.new())
	var second: Node = autofree(Node.new())
	assert_true(receiver.try_claim(first))
	assert_true(receiver.try_claim(first), "claiming twice is fine")
	assert_false(receiver.try_claim(second))
	receiver.release(first)
	assert_true(receiver.try_claim(second))


func test_storage_add_and_remove() -> void:
	var storage: Storage = autofree(Storage.new())
	storage.add(POTATO, 3)
	assert_eq(storage.count(POTATO), 3)
	assert_false(storage.remove(POTATO, 4), "cannot take more than is there")
	assert_eq(storage.count(POTATO), 3)
	assert_true(storage.remove(POTATO, 2))
	assert_eq(storage.count(POTATO), 1)


func test_storage_serves_the_best_meal_first() -> void:
	var storage: Storage = autofree(Storage.new())
	storage.add(GRUEL, 1)
	storage.add(STEW, 1)
	assert_eq(storage.take_best_meal(), STEW)
	assert_eq(storage.take_best_meal(), GRUEL)
	assert_null(storage.take_best_meal())


func test_carrier_holds_one_item_type_up_to_capacity() -> void:
	var carrier: Carrier = autofree(Carrier.new())
	carrier.capacity = 5
	assert_eq(carrier.add(POTATO, 3), 0)
	assert_eq(carrier.add(BARLEY, 1), 1, "a second item type does not fit")
	assert_eq(carrier.add(POTATO, 4), 2, "only two more fit")
	assert_true(carrier.is_full())
	var storage: Storage = autofree(Storage.new())
	carrier.unload_into(storage)
	assert_true(carrier.is_empty())
	assert_eq(storage.count(POTATO), 5)
