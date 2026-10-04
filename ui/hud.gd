class_name Hud
extends CanvasLayer
## The interface drawn over the world. This script only introduces each
## panel to the parts of the game it talks to.

@onready var _world_area: WorldArea = $Root/WorldArea
@onready var _readout: ResourceReadout = $Root/Layout/Middle/TopBar/ResourceReadout
@onready var _farm_tools: FarmTools = $Root/Layout/Middle/TopBar/FarmTools
@onready var _view_buttons: ViewButtons = $Root/Layout/Middle/TopBar/ViewButtons
@onready var _roster: RosterPanel = $Root/Layout/Roster
@onready var _build_tab: BuildTab = $Root/Layout/SidePanel/Row/Tabs/Build
@onready var _shop_tab: ShopTab = $Root/Layout/SidePanel/Row/Tabs/Shop
@onready var _debug_tab: DebugTab = $Root/Layout/SidePanel/Row/Tabs/Debug


func setup(game: Game) -> void:
	_world_area.setup(game.world)
	_readout.setup(game.wallet, game.world.hall.storage, game.catalog)
	_farm_tools.setup(game.world.hand, game.catalog)
	_view_buttons.setup(game.world.camera)
	_roster.setup(game.world)
	_build_tab.setup(game)
	_shop_tab.setup(game)
	_debug_tab.setup(game)
