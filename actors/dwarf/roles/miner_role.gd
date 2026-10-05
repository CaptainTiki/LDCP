class_name MinerRole
extends DwarfRole
## Miners. Assigned to one ore node, the dwarf works that node. Assigned to
## the mine in general, he works any free ore node that has been found, and
## otherwise digs: a tunnel end, a new tunnel off the shaft, or the shaft
## itself, deeper. A full bag of ore is hauled up to the Great Hall. That
## trip is the slog the lift exists to fix.

var _node: OreNode = null
var _head: DigHead = null
## The terrain cell currently being chipped at.
var _dig_cell: Vector2i = NavGrid.NO_CELL

## Digging has no station of its own, so the miner brings his own receiver.
@onready var _dig_work: WorkReceiver = $DigWork


func _ready() -> void:
	_dig_work.completed.connect(_on_dig_completed)


func title() -> String:
	return "Miner"


func badge() -> String:
	return "M"


func act(delta: float) -> void:
	if dwarf.carrier.is_full():
		release()
		_haul_to_hall()
		return
	_node = _choose_node()
	if _node != null:
		_work_node(delta)
	else:
		_excavate(delta)


func release() -> void:
	_drop_node()
	_drop_head()


func _work_node(delta: float) -> void:
	_drop_head()
	if not dwarf.carrier.can_take(_node.ore):
		_haul_to_hall()
		return
	if _walk_to(_node.work_cell()):
		dwarf.worker.work_on(_node.receiver, delta)


func _excavate(delta: float) -> void:
	var excavation: Excavation = dwarf.world.mine_level.excavation
	# The shaft lets its digger go once there's room for a new tunnel.
	if _head == null or _head.is_dead or _head.claimed_by != dwarf:
		_dig_cell = NavGrid.NO_CELL
		_head = excavation.claim_head(dwarf, dwarf.mover.cell)
	if _head == null:
		_nothing_to_dig(delta)
		return
	if not _walk_to(_head.stand_cell):
		return
	var cell: Vector2i = excavation.next_dig_cell(_head)
	if cell == NavGrid.NO_CELL:
		return
	if cell != _dig_cell:
		_dig_cell = cell
		_dig_work.reset(excavation.dig_work(cell))
	dwarf.worker.work_on(_dig_work, delta)


## Every tunnel is taken and the mine has no room for another. Bring up any
## ore, then potter about by the mine entrance.
func _nothing_to_dig(delta: float) -> void:
	if not dwarf.carrier.is_empty():
		_haul_to_hall()
	else:
		dwarf.idler.potter("No tunnel to dig", dwarf.world.mine_entrance.door_cell(), delta)


## The assigned node if we can have it, else the one we already hold, else
## any free one. Null means "go and dig".
func _choose_node() -> OreNode:
	var assigned: OreNode = dwarf.assignment.target as OreNode
	if assigned != null and _can_work(assigned):
		if assigned != _node:
			_drop_node()
		return assigned
	if _node != null and _node != assigned and _can_work(_node):
		return _node
	_drop_node()
	var free_node: OreNode = dwarf.world.mine_level.claim_free_node(dwarf)
	if free_node != null and free_node.work_cell() == NavGrid.NO_CELL:
		free_node.receiver.release(dwarf)
		return null
	return free_node


func _can_work(node: OreNode) -> bool:
	if not node.revealed or node.work_cell() == NavGrid.NO_CELL:
		return false
	return node.receiver.try_claim(dwarf)


func _drop_node() -> void:
	if _node != null:
		_node.receiver.release(dwarf)
	_node = null


func _drop_head() -> void:
	if _head != null:
		dwarf.world.mine_level.excavation.release_head(_head, dwarf)
	_head = null
	_dig_cell = NavGrid.NO_CELL


func _on_dig_completed(_worker: Node) -> void:
	dwarf.world.mine_level.excavation.finish_dig_cell(_head)
	_dig_cell = NavGrid.NO_CELL
