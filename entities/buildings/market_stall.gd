class_name MarketStall
extends Node2D
## The market's counter. The trader puts a load of surplus on it and works
## the stall to sell it, one item per bit of work, and the coins go straight
## into the purse. Nothing is instant: a player's click puts in a little
## work too.

## What's on the counter waiting to be sold, and how many.
var item: ItemDef = null
var count: int = 0

var _world: World

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _work_spot: Marker2D = $WorkSpot
@onready var _clickable: Clickable = $Clickable
@onready var _goods: Sprite2D = $Goods


func setup(world: World) -> void:
	_world = world
	receiver.reset(world.tuning.sell_work_per_item)
	receiver.completed.connect(_on_sold_one)
	_clickable.clicked.connect(_on_clicked)
	_sync()


## The floor cell the trader stands on to sell.
func work_cell() -> Vector2i:
	return NavGrid.world_to_cell(_work_spot.global_position)


func is_empty() -> bool:
	return count <= 0


## Puts the carrier's whole load on the counter, if the counter is empty or
## holds the same thing. Returns whether it did.
func deposit(carrier: Carrier) -> bool:
	if carrier.is_empty() or (count > 0 and carrier.item != item):
		return false
	item = carrier.item
	count += carrier.count
	carrier.remove(item, carrier.count)
	_sync()
	return true


## What the Look tool shows.
func look_lines() -> PackedStringArray:
	var lines: PackedStringArray = ["Market stall"]
	lines.append("Selling %d %s at %d each" % [count, item.display_name, item.sell_price] if count > 0 else "Nothing on the counter")
	var worker: Node = receiver.claimed_by
	if worker != null and is_instance_valid(worker) and worker is Dwarf:
		lines.append("Worked by %s" % (worker as Dwarf).dwarf_name)
	return lines


func _on_sold_one(_worker: Node) -> void:
	if count <= 0:
		return
	count -= 1
	_world.wallet.earn(item.sell_price)
	_world.ledger.record_sold(item, 1)
	if count == 0:
		item = null
	_sync()


func _on_clicked(manual_work: float) -> void:
	if count > 0:
		receiver.apply_work(manual_work)


## Goods on the counter show in their own colour.
func _sync() -> void:
	_goods.visible = count > 0
	if count > 0:
		_goods.modulate = item.color
