class_name MineWatcher
extends LogWatcher
## Logs the mine: deposits found, the shaft getting deeper, the lift going
## in, and each minute how much ground was dug and how many tunnel ends are
## open.

var _cells_dug: Dictionary[String, int] = {"minute": 0, "total": 0}
var _shaft_bottom: int = 0
var _found: Dictionary[OreNode, bool] = {}
var _has_lift: bool = false


func _start() -> void:
	var level: MineLevel = _game.world.mine_level
	_shaft_bottom = _game.world.shaft.bottom_cell().y
	for node: OreNode in level.ore_nodes():
		if node.revealed:
			_found[node] = true
	_has_lift = _game.world.shaft.has_lift
	_game.world.terrain.cell_opened.connect(_on_cell_opened)
	_game_log.event("Start: shaft to row %d, %d tunnel ends" % [_shaft_bottom, level.excavation.head_count()])


func check() -> void:
	var shaft: Shaft = _game.world.shaft
	if shaft.bottom_cell().y != _shaft_bottom:
		_shaft_bottom = shaft.bottom_cell().y
		_game_log.event("Shaft dug down to row %d" % _shaft_bottom)
	for node: OreNode in _game.world.mine_level.ore_nodes():
		if node.revealed and not _found.has(node):
			_found[node] = true
			var at: Vector2i = node.cell_rect().position
			_game_log.event("Found %s deposit %s (column %d, row %d)" % [node.ore.display_name, node.name, at.x, at.y])
	if shaft.has_lift and not _has_lift:
		_has_lift = true
		_game_log.event("Lift installed")


func minute_report() -> void:
	_game_log.line("Mine: dug %d cells, shaft to row %d, %d tunnel ends, %d of %d deposits found" % [
			_cells_dug.minute, _shaft_bottom, _game.world.mine_level.excavation.head_count(),
			_found.size(), _game.world.mine_level.ore_nodes().size()])
	_cells_dug.minute = 0


func totals_report() -> void:
	_game_log.line("Mine: dug %d cells, shaft to row %d, %d of %d deposits found" % [
			_cells_dug.total, _shaft_bottom, _found.size(), _game.world.mine_level.ore_nodes().size()])


func _on_cell_opened(_cell: Vector2i) -> void:
	_cells_dug.minute += 1
	_cells_dug.total += 1
