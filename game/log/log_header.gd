class_name LogHeader
extends RefCounted
## The top of a game log: which build, when, and every tuning and content
## number in play, so the log can be read against the numbers it was
## played with.


static func write(game_log: GameLog, game: Game) -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "?")
	game_log.line("LDCP game log")
	game_log.line("Version %s, started %s." % [version, Time.get_datetime_string_from_system(false, true)])
	game_log.line("Times are game time (h:mm:ss). Shares are of game time.")
	var catalog: ContentCatalog = game.catalog

	_section(game_log, "Tuning")
	game_log.line("Game: " + LogFormat.describe(game.tuning))
	game_log.line("Mine level 1: " + LogFormat.describe(game.world.mine_level.def))
	_section(game_log, "Crops")
	for crop: CropDef in catalog.crops:
		_entry(game_log, crop)
	_section(game_log, "Items")
	for item: ItemDef in catalog.items:
		_entry(game_log, item)
	_section(game_log, "Recipes")
	for recipe: RecipeDef in _recipes(catalog):
		_entry(game_log, recipe)
	_section(game_log, "Buildings")
	for building: BuildingDef in catalog.buildings:
		_entry(game_log, building)
	_section(game_log, "Furniture")
	for piece: FurnitureDef in catalog.furniture:
		_entry(game_log, piece)
	_section(game_log, "Play")


static func _section(game_log: GameLog, title: String) -> void:
	game_log.line("")
	game_log.line("== %s ==" % title)


static func _entry(game_log: GameLog, thing: Resource) -> void:
	game_log.line("%s: %s" % [LogFormat.name_of(thing), LogFormat.describe(thing)])


## Every recipe any station can make, once each.
static func _recipes(catalog: ContentCatalog) -> Array[RecipeDef]:
	var stations: Array[WorkstationDef] = []
	for building: BuildingDef in catalog.buildings:
		stations.append_array(building.workstations)
	for piece: FurnitureDef in catalog.furniture:
		if piece is WorkstationDef:
			stations.append(piece as WorkstationDef)
	var recipes: Array[RecipeDef] = []
	for station: WorkstationDef in stations:
		for recipe: RecipeDef in station.recipes:
			if not recipes.has(recipe):
				recipes.append(recipe)
	return recipes
