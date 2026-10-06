"""Writes the HUD scenes and the UI theme. Run from this folder:

    python gen_ui.py

Importing gen_scenes regenerates the world scenes too.

The UI is laid out on a 150px-tall canvas shown at exactly 3x, so every
size here is in art pixels."""
from gen_scenes import write, ext, node, scene

# --- Theme -------------------------------------------------------------------------
FONT_COLOR = "Color(0.95, 0.91, 0.85, 1)"
DIM_COLOR = "Color(0.54, 0.5, 0.46, 1)"
PRESSED_FONT = "Color(0.16, 0.12, 0.09, 1)"


def stylebox_texture(sid, tex_id, tex_margin, content=(3, 2, 3, 2)):
    l, t, r, b = content
    return """[sub_resource type="StyleBoxTexture" id="%s"]
content_margin_left = %d.0
content_margin_top = %d.0
content_margin_right = %d.0
content_margin_bottom = %d.0
texture = ExtResource("%s")
texture_margin_left = %d.0
texture_margin_top = %d.0
texture_margin_right = %d.0
texture_margin_bottom = %d.0
""" % ((sid, l, t, r, b, tex_id) + (tex_margin,) * 4)


def stylebox_flat(sid, color, margins=(0, 0, 0, 0)):
    l, t, r, b = margins
    return """[sub_resource type="StyleBoxFlat" id="%s"]
content_margin_left = %d.0
content_margin_top = %d.0
content_margin_right = %d.0
content_margin_bottom = %d.0
bg_color = %s
anti_aliasing = false
""" % (sid, l, t, r, b, color)


F = "res://assets/ui/frames/"
theme_exts = [
    '[ext_resource type="FontFile" path="res://assets/fonts/dwarf_5x7.fnt" id="font"]',
    '[ext_resource type="Texture2D" path="%sbutton_normal.png" id="btn_n"]' % F,
    '[ext_resource type="Texture2D" path="%sbutton_hover.png" id="btn_h"]' % F,
    '[ext_resource type="Texture2D" path="%sbutton_pressed.png" id="btn_p"]' % F,
    '[ext_resource type="Texture2D" path="%sbutton_disabled.png" id="btn_d"]' % F,
    '[ext_resource type="Texture2D" path="%spanel.png" id="panel"]' % F,
    '[ext_resource type="Texture2D" path="%sslot.png" id="slot"]' % F,
]
theme_subs = [
    stylebox_texture("normal", "btn_n", 2),
    stylebox_texture("hover", "btn_h", 2),
    stylebox_texture("pressed", "btn_p", 2),
    stylebox_texture("disabled", "btn_d", 2),
    stylebox_texture("panel", "panel", 2, (2, 2, 2, 2)),
    stylebox_texture("slot", "slot", 1, (1, 1, 1, 1)),
    '[sub_resource type="StyleBoxEmpty" id="empty"]\n',
    stylebox_flat("scroll", "Color(0.12, 0.1, 0.09, 1)", (1, 0, 1, 0)),
    stylebox_flat("grabber", "Color(0.55, 0.48, 0.44, 1)", (1, 0, 1, 0)),
    stylebox_flat("grabber_hi", "Color(0.79, 0.64, 0.39, 1)", (1, 0, 1, 0)),
    stylebox_flat("hscroll", "Color(0.12, 0.1, 0.09, 1)", (0, 1, 0, 1)),
    stylebox_flat("hgrabber", "Color(0.55, 0.48, 0.44, 1)", (0, 1, 0, 1)),
]
theme_props = [
    'default_font = ExtResource("font")',
    "default_font_size = 9",
    "Button/colors/font_color = " + FONT_COLOR,
    "Button/colors/font_hover_color = " + FONT_COLOR,
    "Button/colors/font_focus_color = " + FONT_COLOR,
    "Button/colors/font_pressed_color = " + PRESSED_FONT,
    "Button/colors/font_hover_pressed_color = " + PRESSED_FONT,
    "Button/colors/font_disabled_color = " + DIM_COLOR,
    "Button/constants/h_separation = 2",
    'Button/styles/normal = SubResource("normal")',
    'Button/styles/hover = SubResource("hover")',
    'Button/styles/pressed = SubResource("pressed")',
    'Button/styles/hover_pressed = SubResource("pressed")',
    'Button/styles/disabled = SubResource("disabled")',
    'Button/styles/focus = SubResource("empty")',
    "Label/colors/font_color = " + FONT_COLOR,
    'PanelContainer/styles/panel = SubResource("panel")',
    'SlotPanel/base_type = &"PanelContainer"',
    'SlotPanel/styles/panel = SubResource("slot")',
    'TabContainer/styles/panel = SubResource("empty")',
    'VScrollBar/styles/scroll = SubResource("scroll")',
    'VScrollBar/styles/grabber = SubResource("grabber")',
    'VScrollBar/styles/grabber_highlight = SubResource("grabber_hi")',
    'VScrollBar/styles/grabber_pressed = SubResource("grabber_hi")',
    'HScrollBar/styles/scroll = SubResource("hscroll")',
    'HScrollBar/styles/grabber = SubResource("hgrabber")',
    'HScrollBar/styles/grabber_highlight = SubResource("hgrabber")',
    'HScrollBar/styles/grabber_pressed = SubResource("hgrabber")',
    'TooltipPanel/styles/panel = SubResource("panel")',
    "TooltipLabel/colors/font_color = " + FONT_COLOR,
]
write("ui/theme.tres", '[gd_resource type="Theme" format=3]\n\n' + "\n".join(theme_exts) + "\n\n"
      + "\n".join(theme_subs) + "\n[resource]\n" + "\n".join(theme_props) + "\n")

# --- Helpers -------------------------------------------------------------------------
FULL = [("anchors_preset", 15), ("anchor_right", 1.0), ("anchor_bottom", 1.0),
        ("grow_horizontal", 2), ("grow_vertical", 2)]
H_EXPAND = ("size_flags_horizontal", 3)
V_EXPAND = ("size_flags_vertical", 3)
V_CENTER = ("size_flags_vertical", 4)
IGNORE = ("mouse_filter", 2)
NO_HSCROLL = ("horizontal_scroll_mode", 0)
SLOT_STYLE = ("theme_type_variation", '&"SlotPanel"')
RIGHT = ("horizontal_alignment", 2)


def button(name, parent, text, extra=()):
    return node(name, "Button", parent, [("text", '"%s"' % text)] + list(extra))


def icon_rect(name, parent, tex_id, size=16):
    props = [("custom_minimum_size", "Vector2(%d, %d)" % (size, size)), IGNORE, V_CENTER, ("stretch_mode", 3)]
    if tex_id:
        props.append(("texture", 'ExtResource("%s")' % tex_id))
    return node(name, "TextureRect", parent, props)


def s(rid):
    return ("script", 'ExtResource("%s")' % rid)


def with_paths(text, paths):
    """Adds node_paths to a node header, needed for exported Node references."""
    head, rest = text.split("]", 1)
    return head + " node_paths=PackedStringArray(%s)]" % ", ".join('"%s"' % p for p in paths) + rest


def numbers(parent, coin_id):
    """A stored count over a coin price, right-aligned beside an icon."""
    return [
        node("Numbers", "VBoxContainer", parent, [IGNORE, H_EXPAND, ("theme_override_constants/separation", 0)]),
        node("Count", "Label", parent + "/Numbers", [IGNORE, RIGHT, ("text", '"0"')]),
        node("PriceRow", "HBoxContainer", parent + "/Numbers",
             [IGNORE, ("alignment", 2), ("theme_override_constants/separation", 1)]),
        icon_rect("Coin", parent + "/Numbers/PriceRow", coin_id, 8),
        node("Price", "Label", parent + "/Numbers/PriceRow", [IGNORE, ("text", '"0"')]),
    ]


COIN = "res://assets/ui/icons/coin.png"
ICONS = "res://assets/ui/icons/"

# --- Small reusable pieces -------------------------------------------------------------
scene("ui/catalog_button.tscn", [ext("Script", "res://ui/catalog_button.gd", "1"), ext("Texture2D", COIN, "2")],
      [node("CatalogButton", "Button", None, [("alignment", 0), ("icon", 'ExtResource("2")'),
                                              ("icon_alignment", 2), s("1")])])

scene("ui/stock_slot.tscn", [ext("Script", "res://ui/stock_slot.gd", "1"), ext("Texture2D", COIN, "2")],
      [node("StockSlot", "Button", None, [("custom_minimum_size", "Vector2(49, 22)"), ("toggle_mode", "true"), s("1")]),
       node("Margin", "MarginContainer", ".", [("layout_mode", 1)] + FULL + [IGNORE,
            ("theme_override_constants/margin_left", 3), ("theme_override_constants/margin_top", 2),
            ("theme_override_constants/margin_right", 3), ("theme_override_constants/margin_bottom", 2)]),
       node("Row", "HBoxContainer", "Margin", [IGNORE, ("alignment", 1), ("theme_override_constants/separation", 2)]),
       icon_rect("Icon", "Margin/Row", None)]
      + numbers("Margin/Row", "2"))

scene("ui/farm_slot.tscn", [ext("Script", "res://ui/farm_slot.gd", "1"), ext("Texture2D", COIN, "2")],
      [node("FarmSlot", "Button", None, [("custom_minimum_size", "Vector2(49, 22)"), ("toggle_mode", "true"), s("1")]),
       node("Margin", "MarginContainer", ".", [("layout_mode", 1)] + FULL + [IGNORE,
            ("theme_override_constants/margin_left", 3), ("theme_override_constants/margin_top", 2),
            ("theme_override_constants/margin_right", 3), ("theme_override_constants/margin_bottom", 2)]),
       node("Row", "HBoxContainer", "Margin", [IGNORE, ("alignment", 1), ("theme_override_constants/separation", 2)]),
       icon_rect("Icon", "Margin/Row", None)]
      + numbers("Margin/Row", "2"))

scene("ui/icon_slot.tscn", [ext("Script", "res://ui/icon_slot.gd", "1"), ext("Texture2D", COIN, "2")],
      [node("IconSlot", "Button", None, [("custom_minimum_size", "Vector2(49, 22)"), ("toggle_mode", "true"), s("1")]),
       node("Margin", "MarginContainer", ".", [("layout_mode", 1)] + FULL + [IGNORE,
            ("theme_override_constants/margin_left", 3), ("theme_override_constants/margin_top", 2),
            ("theme_override_constants/margin_right", 3), ("theme_override_constants/margin_bottom", 2)]),
       node("Row", "HBoxContainer", "Margin", [IGNORE, ("alignment", 1), ("theme_override_constants/separation", 2)]),
       icon_rect("Icon", "Margin/Row", None)]
      + numbers("Margin/Row", "2"))

scene("ui/recipe_slot.tscn", [ext("Script", "res://ui/recipe_slot.gd", "1")],
      [node("RecipeSlot", "Button", None, [("custom_minimum_size", "Vector2(99, 22)"), ("toggle_mode", "true"), s("1")]),
       node("Margin", "MarginContainer", ".", [("layout_mode", 1)] + FULL + [IGNORE,
            ("theme_override_constants/margin_left", 3), ("theme_override_constants/margin_top", 2),
            ("theme_override_constants/margin_right", 3), ("theme_override_constants/margin_bottom", 2)]),
       node("Row", "HBoxContainer", "Margin", [IGNORE, ("alignment", 1), ("theme_override_constants/separation", 2)]),
       icon_rect("In1Icon", "Margin/Row", None),
       node("In1Count", "Label", "Margin/Row", [IGNORE, V_CENTER]),
       icon_rect("In2Icon", "Margin/Row", None),
       node("In2Count", "Label", "Margin/Row", [IGNORE, V_CENTER]),
       node("Arrow", "Label", "Margin/Row", [IGNORE, V_CENTER, ("text", '">"')]),
       icon_rect("OutIcon", "Margin/Row", None),
       node("OutCount", "Label", "Margin/Row", [IGNORE, V_CENTER])])

scene("ui/item_slot.tscn", [ext("Script", "res://ui/item_slot.gd", "1"), ext("Texture2D", COIN, "2")],
      [node("ItemSlot", "PanelContainer", None, [("custom_minimum_size", "Vector2(49, 22)"), SLOT_STYLE, s("1")]),
       node("Row", "HBoxContainer", ".", [IGNORE, ("theme_override_constants/separation", 2)]),
       icon_rect("Icon", "Row", None)]
      + numbers("Row", "2"))

scene("ui/resource_chip.tscn", [ext("Script", "res://ui/resource_chip.gd", "1")],
      [node("ResourceChip", "PanelContainer", None, [SLOT_STYLE, s("1")]),
       node("Row", "HBoxContainer", ".", [IGNORE, ("theme_override_constants/separation", 2)]),
       icon_rect("Icon", "Row", None),
       node("Value", "Label", "Row", [IGNORE, V_CENTER, ("text", '"0"')])])

BAR_STYLES = """
[sub_resource type="StyleBoxFlat" id="bar_back"]
bg_color = Color(0.12, 0.1, 0.09, 1)
anti_aliasing = false

[sub_resource type="StyleBoxFlat" id="food_fill"]
bg_color = Color(0.9, 0.6, 0.2, 1)
anti_aliasing = false

[sub_resource type="StyleBoxFlat" id="drink_fill"]
bg_color = Color(0.42, 0.66, 0.88, 1)
anti_aliasing = false"""


def card_bar(parent, fill):
    return node("Bar", "ProgressBar", parent, [
        ("custom_minimum_size", "Vector2(30, 3)"), IGNORE, V_CENTER,
        ("theme_override_styles/background", 'SubResource("bar_back")'),
        ("theme_override_styles/fill", 'SubResource("%s")' % fill),
        ("max_value", 1.0), ("step", 0.01), ("show_percentage", "false")])


def bar(name, fill):
    return node(name, "ProgressBar", "Column", [
        ("custom_minimum_size", "Vector2(0, 2)"), IGNORE,
        ("theme_override_styles/background", 'SubResource("bar_back")'),
        ("theme_override_styles/fill", 'SubResource("%s")' % fill),
        ("max_value", 1.0), ("step", 0.01), ("show_percentage", "false")])


scene("ui/roster_entry.tscn", [ext("Script", "res://ui/roster_entry.gd", "1"), BAR_STYLES],
      [node("RosterEntry", "PanelContainer", None, [("custom_minimum_size", "Vector2(24, 0)"), SLOT_STYLE, s("1")]),
       node("Column", "VBoxContainer", ".", [IGNORE, ("theme_override_constants/separation", 1)]),
       node("Top", "HBoxContainer", "Column", [IGNORE, ("theme_override_constants/separation", 1)]),
       node("Portrait", "ColorRect", "Column/Top", [("custom_minimum_size", "Vector2(10, 10)"), IGNORE]),
       node("Badge", "Label", "Column/Top", [IGNORE, ("text", '"-"')]),
       node("Name", "Label", "Column", [("visible", "false"), IGNORE]),
       bar("Food", "food_fill"), bar("Drink", "drink_fill")])

# --- HUD -------------------------------------------------------------------------------
U = "res://ui/"
hud_exts = [
    ext("Script", U + "hud.gd", "1"), ext("Theme", U + "theme.tres", "2"),
    ext("Script", U + "world_area.gd", "3"), ext("Script", U + "roster_panel.gd", "4"),
    ext("PackedScene", U + "roster_entry.tscn", "5"), ext("Script", U + "fold_button.gd", "6"),
    ext("Script", U + "status_readout.gd", "7"), ext("Script", U + "view_buttons.gd", "8"),
    ext("Script", U + "build_tab.gd", "9"), ext("PackedScene", U + "catalog_button.tscn", "10"),
    ext("Script", U + "shop_tab.gd", "11"), ext("PackedScene", U + "stock_slot.tscn", "12"),
    ext("Script", U + "debug_tab.gd", "13"), ext("Script", U + "side_panel.gd", "14"),
    ext("Script", U + "farm_tab.gd", "15"), ext("PackedScene", U + "farm_slot.tscn", "16"),
    ext("Script", U + "options_tab.gd", "17"), ext("Script", U + "look_card.gd", "18"),
    ext("Script", U + "ores_tab.gd", "19"), ext("PackedScene", U + "item_slot.tscn", "20"),
    ext("PackedScene", U + "resource_chip.tscn", "21"),
    ext("Texture2D", COIN, "30"), ext("Texture2D", ICONS + "close.png", "31"),
    ext("Texture2D", ICONS + "tab_farm.png", "32"), ext("Texture2D", ICONS + "tab_ores.png", "33"),
    ext("Texture2D", ICONS + "tab_build.png", "34"), ext("Texture2D", ICONS + "tab_shop.png", "35"),
    ext("Texture2D", ICONS + "tab_debug.png", "36"), ext("Texture2D", ICONS + "tab_options.png", "37"),
    ext("Texture2D", ICONS + "hoe.png", "38"), ext("Texture2D", ICONS + "look.png", "39"),
    ext("Texture2D", ICONS + "bucket.png", "40"), ext("Texture2D", ICONS + "shears.png", "41"),
    ext("Texture2D", ICONS + "lock.png", "42"),
    ext("Script", U + "room_tab.gd", "43"), ext("PackedScene", U + "icon_slot.tscn", "44"),
    ext("Texture2D", ICONS + "tab_hall.png", "45"), ext("Texture2D", ICONS + "move.png", "46"),
    ext("Texture2D", ICONS + "destroy.png", "47"), ext("Texture2D", ICONS + "turn.png", "48"),
    ext("PackedScene", U + "recipe_slot.tscn", "49"), ext("Script", U + "dwarf_card.gd", "50"),
    ext("Texture2D", ICONS + "camera.png", "51"),
    ext("Script", U + "zigzag_tabs.gd", "52"), ext("Script", U + "inventory_tab.gd", "53"),
    ext("Script", U + "look_button.gd", "54"), ext("Texture2D", ICONS + "tab_inventory.png", "55"),
    ext("Texture2D", ICONS + "idle.png", "56"),
    BAR_STYLES]
L = "Root/Layout"
R = L + "/Roster"
M = L + "/Middle"
P = L + "/SidePanel"
TC = P + "/Row/TabColumn"
TABS = TC + "/Tabs"
PG = P + "/Row/Pages"


def tab(name, icon_id, tip, parent=TABS, extra=()):
    return button(name, parent, "", list(extra) + [("custom_minimum_size", "Vector2(22, 20)"), ("toggle_mode", "true"),
                                  ("tooltip_text", '"%s"' % tip), ("icon", 'ExtResource("%s")' % icon_id),
                                  ("icon_alignment", 1)])


def grid(parent):
    return node("Grid", "GridContainer", parent, [H_EXPAND, ("columns", 4),
                                                  ("theme_override_constants/h_separation", 1),
                                                  ("theme_override_constants/v_separation", 1)])


hud_nodes = [
    node("Hud", "CanvasLayer", None, [s("1")]),
    node("Root", "Control", ".", [("layout_mode", 3)] + FULL + [IGNORE, ("theme", 'ExtResource("2")')]),
    node("WorldArea", "Control", "Root", [("layout_mode", 1)] + FULL + [s("3")]),
    node("Layout", "HBoxContainer", "Root", [("layout_mode", 1)] + FULL + [IGNORE,
         ("theme_override_constants/separation", 0)]),
    # Follows the cursor while a dwarf is hovered. Never catches the mouse.
    node("DwarfCard", "PanelContainer", "Root", [("visible", "false"), ("z_index", 20), ("layout_mode", 0),
                                                 ("custom_minimum_size", "Vector2(104, 0)"), IGNORE, s("50")]),
    node("Column", "VBoxContainer", "Root/DwarfCard", [IGNORE, ("theme_override_constants/separation", 1)]),
    node("Name", "Label", "Root/DwarfCard/Column", [IGNORE, ("theme_override_colors/font_color", "Color(0.95, 0.8, 0.45, 1)")]),
    node("Status", "Label", "Root/DwarfCard/Column", [IGNORE]),
    node("FoodRow", "HBoxContainer", "Root/DwarfCard/Column", [IGNORE, ("theme_override_constants/separation", 2)]),
    node("Label", "Label", "Root/DwarfCard/Column/FoodRow", [IGNORE, ("text", '"Food"')]),
    card_bar("Root/DwarfCard/Column/FoodRow", "food_fill"),
    node("DrinkRow", "HBoxContainer", "Root/DwarfCard/Column", [IGNORE, ("theme_override_constants/separation", 2)]),
    node("Title", "Label", "Root/DwarfCard/Column/DrinkRow", [IGNORE, ("text", '"Drink"')]),
    card_bar("Root/DwarfCard/Column/DrinkRow", "drink_fill"),
    node("Label", "Label", "Root/DwarfCard/Column/DrinkRow", [IGNORE]),
    node("Carrying", "Label", "Root/DwarfCard/Column", [IGNORE]),
    node("Tool", "Label", "Root/DwarfCard/Column", [IGNORE]),
    # The Look tool's pop-up, and the hand's reminders. Never catches the mouse.
    node("LookCard", "PanelContainer", "Root", [("visible", "false"), ("z_index", 20), ("layout_mode", 0),
                                                ("custom_minimum_size", "Vector2(140, 0)"), IGNORE, s("18")]),
    node("Column", "VBoxContainer", "Root/LookCard", [IGNORE, ("theme_override_constants/separation", 1)]),
    node("Title", "Label", "Root/LookCard/Column", [IGNORE, ("autowrap_mode", 3),
         ("theme_override_colors/font_color", "Color(0.95, 0.8, 0.45, 1)")]),
    node("Body", "Label", "Root/LookCard/Column", [IGNORE, ("autowrap_mode", 3)]),

    # Left: the dwarf roster, two across.
    node("Roster", "PanelContainer", L, [s("4"), ("entry_scene", 'ExtResource("5")')]),
    node("RefreshTimer", "Timer", R, [("wait_time", 0.25), ("autostart", "true")]),
    node("Row", "HBoxContainer", R, [("theme_override_constants/separation", 1)]),
    node("Body", "VBoxContainer", R + "/Row", [("theme_override_constants/separation", 1)]),
    node("Filters", "HBoxContainer", R + "/Row/Body", [("theme_override_constants/separation", 1)]),
    button("HereButton", R + "/Row/Body/Filters", "Here", [H_EXPAND, ("tooltip_text", '"Dwarves in this view"')]),
    button("AllButton", R + "/Row/Body/Filters", "All", [H_EXPAND, ("tooltip_text", '"Every dwarf"')]),
    node("Scroll", "ScrollContainer", R + "/Row/Body", [V_EXPAND, NO_HSCROLL]),
    node("Entries", "GridContainer", R + "/Row/Body/Scroll",
         [H_EXPAND, ("theme_override_constants/h_separation", 1),
          ("theme_override_constants/v_separation", 1), ("columns", 2)]),
    with_paths(button("FoldButton", R + "/Row", "<", [s("6"), ("target", 'NodePath("../Body")')]), ["target"]),

    # Middle: the town at a glance (coins, plants growing, idle dwarves), the
    # Look tool, and the views. Nothing here grows with the town, so it can
    # never push the side panels off the screen.
    node("Middle", "VBoxContainer", L, [H_EXPAND, IGNORE]),
    node("TopBar", "HBoxContainer", M, [IGNORE, ("theme_override_constants/separation", 1)]),
    node("StatusReadout", "HBoxContainer", M + "/TopBar", [IGNORE, ("theme_override_constants/separation", 1),
                                                          s("7"), ("chip_scene", 'ExtResource("21")'),
                                                          ("coin_icon", 'ExtResource("30")'),
                                                          ("plant_icon", 'ExtResource("32")'),
                                                          ("idle_icon", 'ExtResource("56")')]),
    node("RefreshTimer", "Timer", M + "/TopBar/StatusReadout", [("wait_time", 0.5), ("autostart", "true")]),
    node("Spacer", "Control", M + "/TopBar", [H_EXPAND, IGNORE]),
    button("LookButton", M + "/TopBar", "", [("toggle_mode", "true"), ("icon", 'ExtResource("39")'), s("54"),
           ("tooltip_text", '"Look: hover anything to see what it is up to. Click to put it away"')]),
    node("ViewButtons", "HBoxContainer", M + "/TopBar", [s("8"), ("theme_override_constants/separation", 1)]),
    button("FollowButton", M + "/TopBar/ViewButtons", "", [("toggle_mode", "true"), ("icon", 'ExtResource("51")'),
           ("tooltip_text", '"Follow: the camera sticks to the dwarf you click in the roster"')]),
    button("SurfaceButton", M + "/TopBar/ViewButtons", "Town"),
    button("MineButton", M + "/TopBar/ViewButtons", "Mine"),
    button("BackButton", M + "/TopBar/ViewButtons", "Back"),

    # Right: Rusty's-style panel. Tabs down the left edge, pages beside them.
    node("SidePanel", "PanelContainer", L, [s("14")]),
    node("Row", "HBoxContainer", P, [("theme_override_constants/separation", 2)]),
    node("TabColumn", "VBoxContainer", P + "/Row", [("theme_override_constants/separation", 1)]),
    # Zigzag: the X top right, then each tab a half step down on the other side.
    node("Tabs", "Container", TC, [V_EXPAND, s("52")]),
    button("CloseButton", TABS, "", [("custom_minimum_size", "Vector2(22, 14)"), ("tooltip_text", '"Fold away"'),
                                     ("icon", 'ExtResource("31")'), ("icon_alignment", 1)]),
    tab("RoomButton", "45", "This building"),
    tab("FarmButton", "32", "Farming"),
    tab("BuildButton", "34", "Buildings"),
    tab("OresButton", "33", "Ores"),
    tab("InventoryButton", "55", "Inventory"),
    tab("ShopButton", "35", "Shop"),
    tab("DebugButton", "36", "Debug"),
    tab("OptionsButton", "37", "Options", TC, [("size_flags_horizontal", 0)]),
    node("Pages", "TabContainer", P + "/Row", [("custom_minimum_size", "Vector2(199, 0)"),
                                                ("tabs_visible", "false")]),

    node("Farming", "ScrollContainer", PG, [NO_HSCROLL, s("15"), ("slot_scene", 'ExtResource("16")'),
                                            ("hoe_icon", 'ExtResource("38")'), ("look_icon", 'ExtResource("39")'),
                                            ("bucket_icon", 'ExtResource("40")'),
                                            ("shears_icon", 'ExtResource("41")'),
                                            ("lock_icon", 'ExtResource("42")')]),
    grid(PG + "/Farming"),

    node("Ores", "ScrollContainer", PG, [NO_HSCROLL, s("19"), ("slot_scene", 'ExtResource("20")'),
                                         ("lock_icon", 'ExtResource("42")')]),
    grid(PG + "/Ores"),

    node("Build", "VBoxContainer", PG, [s("9"), ("button_scene", 'ExtResource("10")'),
                                        ("theme_override_constants/separation", 1)]),
    node("Tools", "HBoxContainer", PG + "/Build", [("theme_override_constants/separation", 1)]),
    button("MoveButton", PG + "/Build/Tools", "Move", [H_EXPAND]),
    button("DestroyButton", PG + "/Build/Tools", "Destroy", [H_EXPAND]),
    button("CancelButton", PG + "/Build/Tools", "Cancel", [H_EXPAND]),
    node("Hint", "Label", PG + "/Build", [("autowrap_mode", 3)]),
    node("Scroll", "ScrollContainer", PG + "/Build", [V_EXPAND, NO_HSCROLL]),
    node("List", "VBoxContainer", PG + "/Build/Scroll", [H_EXPAND, ("theme_override_constants/separation", 1)]),

    node("Shop", "ScrollContainer", PG, [NO_HSCROLL, s("11"), ("button_scene", 'ExtResource("10")')]),
    node("List", "VBoxContainer", PG + "/Shop", [H_EXPAND, ("theme_override_constants/separation", 1)]),
    node("BuyHeader", "Label", PG + "/Shop/List", [("text", '"Buy"')]),
    node("BuyList", "VBoxContainer", PG + "/Shop/List", [("theme_override_constants/separation", 1)]),
    button("HireButton", PG + "/Shop/List", "Hire a dwarf", [("alignment", 0), ("icon", 'ExtResource("30")'),
                                                            ("icon_alignment", 2)]),
    button("LiftButton", PG + "/Shop/List", "Build the lift", [("alignment", 0), ("icon", 'ExtResource("30")'),
                                                              ("icon_alignment", 2)]),
    node("UnlockList", "VBoxContainer", PG + "/Shop/List", [("theme_override_constants/separation", 1)]),

    node("Debug", "VBoxContainer", PG, [s("13"), ("theme_override_constants/separation", 1)]),
    node("Speeds", "HBoxContainer", PG + "/Debug", [("theme_override_constants/separation", 1)]),
    button("Speed1", PG + "/Debug/Speeds", "x1", [H_EXPAND]),
    button("Speed4", PG + "/Debug/Speeds", "x4", [H_EXPAND]),
    button("Speed16", PG + "/Debug/Speeds", "x16", [H_EXPAND]),
    button("CoinsButton", PG + "/Debug", "Give coins"),
    button("RevealButton", PG + "/Debug", "Reveal ore"),

    node("Options", "VBoxContainer", PG, [s("17"), ("theme_override_constants/separation", 1)]),
    button("StripButton", PG + "/Options", "Desktop strip", [("toggle_mode", "true"),
                                                            ("tooltip_text", '"Also F10"')]),
    button("QuitButton", PG + "/Options", "Quit"),

    node("Room", "ScrollContainer", PG, [NO_HSCROLL, s("43"), ("slot_scene", 'ExtResource("44")'),
                                         ("item_slot_scene", 'ExtResource("20")'),
                                         ("move_icon", 'ExtResource("46")'), ("destroy_icon", 'ExtResource("47")'),
                                         ("turn_icon", 'ExtResource("48")'),
                                         ("recipe_slot_scene", 'ExtResource("49")')]),
    node("Column", "VBoxContainer", PG + "/Room", [H_EXPAND, ("theme_override_constants/separation", 2)]),
    grid(PG + "/Room/Column").replace('name="Grid"', 'name="Tools"'),
    node("Station", "VBoxContainer", PG + "/Room/Column", [("visible", "false"), ("theme_override_constants/separation", 1)]),
    node("Title", "Label", PG + "/Room/Column/Station"),
    # What the station is doing or waiting for, e.g. "Gruel, waiting for 1 Potato".
    node("Status", "Label", PG + "/Room/Column/Station", [("autowrap_mode", 3), ("custom_minimum_size", "Vector2(100, 0)"),
         ("theme_override_colors/font_color", "Color(0.85, 0.8, 0.7, 1)")]),
    # Stops the batch on: what went in goes back to the hall.
    button("CancelButton", PG + "/Room/Column/Station", "Cancel batch", [("visible", "false"),
           ("size_flags_horizontal", 0), ("tooltip_text", '"Stop this batch. What went in goes back to the hall"')]),
    node("Recipes", "GridContainer", PG + "/Room/Column/Station", [H_EXPAND, ("columns", 2),
         ("theme_override_constants/h_separation", 1), ("theme_override_constants/v_separation", 1)]),
    node("Stock", "HBoxContainer", PG + "/Room/Column", [("theme_override_constants/separation", 1)]),
    node("Foods", "GridContainer", PG + "/Room/Column/Stock", [H_EXPAND, ("columns", 2),
         ("theme_override_constants/h_separation", 1), ("theme_override_constants/v_separation", 1)]),
    node("Drinks", "GridContainer", PG + "/Room/Column/Stock", [H_EXPAND, ("columns", 2),
         ("theme_override_constants/h_separation", 1), ("theme_override_constants/v_separation", 1)]),

    # Everything in the Great Hall, and a bar for selling the picked item.
    node("Inventory", "VBoxContainer", PG, [s("53"), ("slot_scene", 'ExtResource("12")'),
                                            ("theme_override_constants/separation", 1)]),
    node("SellBar", "HBoxContainer", PG + "/Inventory", [("theme_override_constants/separation", 2)]),
    icon_rect("Icon", PG + "/Inventory/SellBar", None),
    node("Label", "Label", PG + "/Inventory/SellBar", [H_EXPAND, V_CENTER, ("clip_text", "true")]),
    button("OneButton", PG + "/Inventory/SellBar", "1", [("tooltip_text", '"Sell one"')]),
    button("AllButton", PG + "/Inventory/SellBar", "All", [("tooltip_text", '"Sell them all"')]),
    node("Scroll", "ScrollContainer", PG + "/Inventory", [V_EXPAND, NO_HSCROLL]),
    grid(PG + "/Inventory/Scroll"),
]
scene("ui/hud.tscn", hud_exts, hud_nodes)
print("ui written")
