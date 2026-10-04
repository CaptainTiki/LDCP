class_name Hud
extends CanvasLayer
## The interface drawn over the world. This script only introduces each
## panel to the parts of the game it talks to.

@onready var _world_area: WorldArea = $Root/WorldArea
@onready var _readout: ResourceReadout = $Root/Layout/Middle/TopBar/ResourceReadout
@onready var _hand_status: HandStatus = $Root/Layout/Middle/TopBar/HandStatus
@onready var _view_buttons: ViewButtons = $Root/Layout/Middle/TopBar/ViewButtons
@onready var _roster: RosterPanel = $Root/Layout/Roster
@onready var _farm_tab: FarmTab = $Root/Layout/SidePanel/Row/Pages/Farming
@onready var _ores_tab: OresTab = $Root/Layout/SidePanel/Row/Pages/Ores
@onready var _build_tab: BuildTab = $Root/Layout/SidePanel/Row/Pages/Build
@onready var _shop_tab: ShopTab = $Root/Layout/SidePanel/Row/Pages/Shop
@onready var _debug_tab: DebugTab = $Root/Layout/SidePanel/Row/Pages/Debug
@onready var _options_tab: OptionsTab = $Root/Layout/SidePanel/Row/Pages/Options
@onready var _hall_tab: HallTab = $Root/Layout/SidePanel/Row/Pages/Hall
@onready var _side_panel: SidePanel = $Root/Layout/SidePanel


func setup(game: Game) -> void:
	_world_area.setup(game.world)
	_readout.setup(game.wallet, game.world.hall.storage, game.catalog)
	_hand_status.setup(game.world.hand)
	_view_buttons.setup(game.world.camera)
	_roster.setup(game.world)
	_farm_tab.setup(game)
	_ores_tab.setup(game)
	_build_tab.setup(game)
	_shop_tab.setup(game)
	_debug_tab.setup(game)
	_options_tab.setup(game)
	_hall_tab.setup(game)
	_side_panel.setup(game.world.camera)
