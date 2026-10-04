class_name OreNode
extends Node2D
## A hand-placed ore deposit. It stays hidden inside the rock until a tunnel
## comes close, then becomes a permanent workstation miners can be assigned to.
## Its position is the top-left corner of the cells it fills.

const SIZE_CELLS: Vector2i = Vector2i(2, 2)
## How far from the deposit a miner may stand and still reach it.
const WORK_REACH: int = 3

@export var ore: ItemDef
## Work needed to chip out one piece of ore.
@export var work_per_ore: float = 8.0

var revealed: bool = false

var _nav: NavGrid
var _hall_storage: Storage
var _ledger: Ledger
var _work_cell: Vector2i = NavGrid.NO_CELL

@onready var receiver: WorkReceiver = $WorkReceiver
@onready var _clickable: Clickable = $Clickable


func _ready() -> void:
	visible = false
	receiver.reset(work_per_ore)
	receiver.completed.connect(_on_ore_chipped)
	_clickable.clicked.connect(_on_clicked)


func setup(nav: NavGrid, hall_storage: Storage, ledger: Ledger) -> void:
	_nav = nav
	_hall_storage = hall_storage
	_ledger = ledger


func cell_rect() -> Rect2i:
	return Rect2i(NavGrid.world_to_cell(global_position), SIZE_CELLS)


func is_near(cell: Vector2i, reach: int) -> bool:
	return cell_rect().grow(reach).has_point(cell)


func reveal() -> void:
	revealed = true
	visible = true


## The closest cell a miner can stand in to work the deposit, or NO_CELL if
## no tunnel reaches it yet.
func work_cell() -> Vector2i:
	if _work_cell != NavGrid.NO_CELL and _nav.is_walkable(_work_cell):
		return _work_cell
	_work_cell = NavGrid.NO_CELL
	var rect: Rect2i = cell_rect()
	var center: Vector2 = Vector2(rect.position) + Vector2(rect.size) * 0.5
	var area: Rect2i = rect.grow(WORK_REACH)
	var best_distance: float = INF
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			var distance: float = center.distance_to(Vector2(cell) + Vector2(0.5, 0.5))
			if _nav.is_walkable(cell) and distance < best_distance:
				best_distance = distance
				_work_cell = cell
	return _work_cell


func _on_ore_chipped(worker: Node) -> void:
	Payout.give(ore, 1, worker, _hall_storage)
	_ledger.record_mined(ore, 1)


func _on_clicked(manual_work: float) -> void:
	receiver.apply_work(manual_work)
