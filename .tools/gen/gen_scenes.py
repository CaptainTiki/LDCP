"""Writes the world, entity and game .tscn files. Run from this folder:

    python gen_scenes.py

Art comes from assets/ (see .tools/art/). gen_ui.py imports this module, so
running gen_ui.py rewrites these scenes too."""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text.lstrip("\n"))


def ext(typ, path, rid):
    return '[ext_resource type="%s" path="%s" id="%s"]' % (typ, path, rid)


def node(name, typ, parent=None, props=(), instance=None):
    head = '[node name="%s"' % name
    if typ:
        head += ' type="%s"' % typ
    if parent is not None:
        head += ' parent="%s"' % parent
    if instance:
        head += ' instance=ExtResource("%s")' % instance
    head += "]"
    return "\n".join([head] + ["%s = %s" % p for p in props]) + "\n"


def rect(name, parent, l, t, r, b, col, extra=()):
    props = [("offset_left", float(l)), ("offset_top", float(t)), ("offset_right", float(r)),
             ("offset_bottom", float(b)), ("mouse_filter", 2), ("color", "Color(%s, %s, %s, %s)" % col)]
    return node(name, "ColorRect", parent, props + list(extra))


def label(name, parent, l, t, r, b, text):
    """World text. The font comes from the project theme; the shadow keeps it
    readable on grass."""
    return node(name, "Label", parent, [
        ("offset_left", float(l)), ("offset_top", float(t)), ("offset_right", float(r)),
        ("offset_bottom", float(b)), ("mouse_filter", 2),
        ("theme_override_colors/font_shadow_color", "Color(0.1, 0.08, 0.07, 1)"),
        ("theme_override_constants/shadow_offset_x", 1), ("theme_override_constants/shadow_offset_y", 1),
        ("text", '"%s"' % text), ("horizontal_alignment", 1)])


def sprite(name, parent, tex_id, x, y, extra=()):
    """An uncentred sprite whose top-left corner sits at (x, y)."""
    return node(name, "Sprite2D", parent, [("position", "Vector2(%s, %s)" % (x, y)), ("centered", "false"),
                                          ("texture", 'ExtResource("%s")' % tex_id)] + list(extra))


def tiled(name, parent, tex_id, l, t, r, b, extra=()):
    """A rectangle filled with a repeating texture."""
    return node(name, "TextureRect", parent, [
        ("offset_left", float(l)), ("offset_top", float(t)), ("offset_right", float(r)),
        ("offset_bottom", float(b)), ("mouse_filter", 2), ("texture", 'ExtResource("%s")' % tex_id),
        ("stretch_mode", 1)] + list(extra))


def nine_patch(name, parent, tex_id, l, t, r, b, margins, extra=()):
    ml, mt, mr, mb = margins
    return node(name, "NinePatchRect", parent, [
        ("offset_left", float(l)), ("offset_top", float(t)), ("offset_right", float(r)),
        ("offset_bottom", float(b)), ("mouse_filter", 2), ("texture", 'ExtResource("%s")' % tex_id),
        ("patch_margin_left", ml), ("patch_margin_top", mt), ("patch_margin_right", mr),
        ("patch_margin_bottom", mb), ("axis_stretch_horizontal", 1), ("axis_stretch_vertical", 1)]
        + list(extra))


def scene(rel, exts, nodes):
    write(rel, "[gd_scene format=3]\n\n" + "\n".join(exts) + "\n\n" + "\n".join(nodes))


RECEIVER = "res://entities/components/work_receiver.gd"
CLICKABLE = "res://entities/components/clickable.gd"
A = "res://assets/"


def clickable(parent, x, y, w, h, rid):
    return node("Clickable", "Node2D", parent, [
        ("position", "Vector2(%s, %s)" % (x, y)), ("script", 'ExtResource("%s")' % rid),
        ("size", "Vector2(%s, %s)" % (w, h))])


# --- Terrain ---------------------------------------------------------------------------
# The tile set: one 8x8 atlas, tiles laid out in a single row (see make_world_art.py).
TILE_COUNT = 11
write("world/mine/terrain_tiles.tres", '[gd_resource type="TileSet" format=3]\n\n'
      + ext("Texture2D", A + "mine/terrain_tiles.png", "1") + "\n\n"
      + '[sub_resource type="TileSetAtlasSource" id="atlas"]\ntexture = ExtResource("1")\n'
      + "texture_region_size = Vector2i(8, 8)\n"
      + "".join("%d:0/0 = 0\n" % i for i in range(TILE_COUNT))
      + '\n[resource]\ntile_size = Vector2i(8, 8)\nsources/0 = SubResource("atlas")\n')

scene("world/mine/terrain.tscn",
      [ext("Script", "res://world/mine/terrain.gd", "1"), ext("TileSet", "res://world/mine/terrain_tiles.tres", "2"),
       ext("Texture2D", A + "mine/plank.png", "3")],
      [node("Terrain", "Node2D", None, [("script", 'ExtResource("1")'), ("plank_texture", 'ExtResource("3")')]),
       node("Tiles", "TileMapLayer", ".", [("show_behind_parent", "true"), ("tile_set", 'ExtResource("2")')])])

# --- Ore node --------------------------------------------------------------------------
scene("entities/ore_node/ore_node.tscn",
      [ext("Script", "res://entities/ore_node/ore_node.gd", "1"), ext("Script", RECEIVER, "2"),
       ext("Script", CLICKABLE, "3"), ext("Texture2D", A + "mine/copper_deposit.png", "4")],
      [node("OreNode", "Node2D", None, [("script", 'ExtResource("1")')]),
       sprite("Sprite", ".", "4", 0, 0),
       node("WorkReceiver", "Node", ".", [("script", 'ExtResource("2")')]),
       clickable(".", 0, 0, 16, 16, "3")])


# --- Mine level 1 ----------------------------------------------------------------------
def ore(name, x, y):
    return node(name, None, "OreNodes", [("position", "Vector2(%s, %s)" % (x, y)),
                                         ("ore", 'ExtResource("5")')], instance="4")


scene("world/mine/mine_level_1.tscn",
      [ext("Script", "res://world/mine/mine_level.gd", "1"),
       ext("Resource", "res://data/mine/level_1.tres", "2"),
       ext("Script", "res://world/mine/excavation.gd", "3"),
       ext("PackedScene", "res://entities/ore_node/ore_node.tscn", "4"),
       ext("Resource", "res://data/items/copper_ore.tres", "5")],
      [node("MineLevel1", "Node2D", None, [("script", 'ExtResource("1")'), ("def", 'ExtResource("2")')]),
       node("Excavation", "Node", ".", [("script", 'ExtResource("3")')]),
       node("OreNodes", "Node2D", "."),
       # Positions are level-local, multiples of the 8px cell. The shaft
       # (column 130, x=1040) first lands with dwarves' feet on row 4
       # (y=32..40). The first deposit sits in the dirt right over the
       # landing's east tunnel, so the first miner down can't miss it. The
       # others are out in the stone, for tunnels off the deeper shaft.
       ore("CopperNear", 1088, 8),
       ore("CopperWest", 832, 96),
       ore("CopperDeep", 1280, 200)])

# --- Farm plot -------------------------------------------------------------------------
# One tile of soil with one plant. The plant sprite steps through its crop's
# growth frames.
scene("entities/farm_plot/farm_plot.tscn",
      [ext("Script", "res://entities/farm_plot/farm_plot.gd", "1"), ext("Script", RECEIVER, "2"),
       ext("Script", CLICKABLE, "3"), ext("Texture2D", A + "town/soil_dry.png", "4"),
       ext("Texture2D", A + "town/soil_wet.png", "5")],
      [node("FarmPlot", "Node2D", None, [("z_index", -1), ("script", 'ExtResource("1")'),
                                         ("dry_soil", 'ExtResource("4")'), ("wet_soil", 'ExtResource("5")')]),
       sprite("Soil", ".", "4", 0, -16),
       node("Plant", "Sprite2D", ".", [("visible", "false"), ("position", "Vector2(0, -18)"),
                                        ("centered", "false"), ("hframes", 4)]),
       node("WorkReceiver", "Node", ".", [("script", 'ExtResource("2")')]),
       clickable(".", 0, -16, 16, 16, "3")])


# --- Workstations ----------------------------------------------------------------------
def workstation(name, file, jiggle=False):
    scene("entities/workstations/%s.tscn" % file,
          [ext("Script", "res://entities/workstations/workstation.gd", "1"), ext("Script", RECEIVER, "2"),
           ext("Script", CLICKABLE, "3"), ext("Texture2D", A + "interiors/%s.png" % file, "4")],
          [node(name, "Node2D", None, [("script", 'ExtResource("1")'), ("jiggle_while_working", str(jiggle).lower())]),
           # Centred, so it turns about the middle of its 2x2 footprint.
           node("Sprite", "Sprite2D", ".", [("texture", 'ExtResource("4")')]),
           # Progress over the station: loading, then cooking, then done.
           rect("BarBack", ".", 1, -3, 15, -1, (0.12, 0.1, 0.09, 1), [("visible", "false")]),
           rect("BarFill", ".", 1, -3, 2, -1, (0.91, 0.75, 0.31, 1), [("visible", "false")]),
           node("WorkReceiver", "Node", ".", [("script", 'ExtResource("2")')]),
           clickable(".", 0, 0, 16, 16, "3")])


workstation("Stove", "stove")
workstation("MashPot", "mash_pot")
workstation("Fermenter", "fermenter", jiggle=True)
workstation("Smelter", "smelter")
workstation("Anvil", "anvil")

# --- Building interiors ----------------------------------------------------------------
INTERIOR = "res://entities/buildings/building_interior.gd"
ROOM_EXTS = [ext("Texture2D", A + "interiors/wall_frame.png", "10"),
             ext("Texture2D", A + "interiors/floor_planks.png", "11"),
             ext("Texture2D", A + "interiors/door.png", "12"),
             ext("Texture2D", A + "interiors/table.png", "13"),
             ext("Texture2D", A + "interiors/storage_pile.png", "14")]


def room_nodes(name, script_id, w_cells, h_cells):
    w, h = w_cells * 8, h_cells * 8
    return [node(name, "Node2D", None, [("script", 'ExtResource("%s")' % script_id),
                                        ("floor_size_cells", "Vector2i(%d, %d)" % (w_cells, h_cells))]),
            nine_patch("Walls", ".", "10", -6, -18, w + 6, h + 6, (6, 18, 6, 6)),
            tiled("Floor", ".", "11", 0, 0, w, h),
            sprite("DoorVisual", ".", "12", 16, h),
            node("Door", "Marker2D", ".", [("position", "Vector2(20, %d)" % (h - 4))]),
            node("Furniture", "Node2D", ".")]


def work_room(name, stations):
    """An open floor that comes with its starting stations against the back wall."""
    nodes = room_nodes(name, "1", 20, 8)
    exts = [ext("Script", INTERIOR, "1")] + ROOM_EXTS
    for i, station in enumerate(stations):
        scene_id, def_id = str(20 + 2 * i), str(21 + 2 * i)
        exts += [ext("PackedScene", "res://entities/workstations/%s.tscn" % station, scene_id),
                 ext("Resource", "res://data/workstations/%s.tres" % station, def_id)]
        x = 9 if len(stations) == 1 else 5 + 7 * i
        nodes.append(node(name_to_camel(station) + "1", None, "Furniture",
                          [("def", 'ExtResource("%s")' % def_id), ("cell", "Vector2i(%d, 0)" % x)],
                          instance=scene_id))
    scene("entities/buildings/%s.tscn" % name_to_file(name), exts, nodes)


def name_to_camel(name):
    return "".join(part.capitalize() for part in name.split("_"))


def name_to_file(name):
    out = ""
    for ch in name:
        if ch.isupper() and out:
            out += "_"
        out += ch.lower()
    return out


work_room("KitchenInterior", ["stove"])
work_room("BreweryInterior", ["mash_pot", "fermenter"])
work_room("SmelteryInterior", ["smelter"])
work_room("ForgeInterior", ["anvil"])

def furniture_scene(name, tex):
    scene("entities/furniture/%s.tscn" % name,
          [ext("Script", "res://entities/furniture/furniture.gd", "1"),
           ext("Texture2D", A + "interiors/%s.png" % tex, "2")],
          [node(name_to_camel(name), "Node2D", None, [("script", 'ExtResource("1")')]),
           # Centred, so it can turn about the middle of its footprint.
           node("Sprite", "Sprite2D", ".", [("texture", 'ExtResource("2")')])])


furniture_scene("chair", "chair")
furniture_scene("table", "table_small")
furniture_scene("long_table", "table_long")


def piece(name, scene_id, def_id, cx, cy, facing=0):
    """Starting furniture, at a cell counted from the floor's corner, turned
    `facing` quarter turns clockwise."""
    return node(name, None, "Furniture", [("def", 'ExtResource("%s")' % def_id),
                                          ("cell", "Vector2i(%d, %d)" % (cx, cy)), ("facing", facing)],
                instance=scene_id)


# The storage pile and the spot in front of it stay clear of furniture.
hall = room_nodes("GreatHallInterior", "1", 30, 10)
hall[0] = node("GreatHallInterior", "Node2D", None, [("script", 'ExtResource("1")'),
                                                     ("floor_size_cells", "Vector2i(30, 10)"),
                                                     ("reserved_rects", "Array[Rect2i]([Rect2i(3, 0, 3, 4)])")])
hall.append(sprite("StoragePile", ".", "14", 26, 4))
hall.append(node("StorageSpot", "Marker2D", ".", [("position", "Vector2(36, 28)")]))
# Enough for the starting four: two tables, a chair either side of each.
# Chairs face their table: backs to the outside.
hall += [piece("Table1", "20", "23", 10, 4), piece("Chair1", "21", "24", 9, 4, 3), piece("Chair2", "21", "24", 12, 4, 1),
         piece("Table2", "20", "23", 18, 4), piece("Chair3", "21", "24", 17, 4, 3), piece("Chair4", "21", "24", 20, 4, 1)]
scene("entities/buildings/great_hall_interior.tscn",
      [ext("Script", "res://entities/buildings/great_hall_interior.gd", "1")] + ROOM_EXTS
      + [ext("PackedScene", "res://entities/furniture/table.tscn", "20"),
         ext("PackedScene", "res://entities/furniture/chair.tscn", "21"),
         ext("Resource", "res://data/furniture/table.tres", "23"),
         ext("Resource", "res://data/furniture/chair.tres", "24")], hall)


# --- Building exteriors ----------------------------------------------------------------
def building(file, name, script, interior, w, h, text, extra_nodes=(), extra_exts=()):
    """Seen from above at a slight tilt. The sprite is the footprint plus 8px of
    roof overhang above it, and its bottom edge sits on the node's origin."""
    exts = [ext("Script", script, "1"), ext("Script", CLICKABLE, "2"),
            ext("Texture2D", A + "buildings/%s.png" % file, "5")]
    props = [("script", 'ExtResource("1")')]
    if interior:
        exts.append(ext("PackedScene", interior, "3"))
        props.append(("interior_scene", 'ExtResource("3")'))
    exts += list(extra_exts)
    nodes = [node(name, "Node2D", None, props),
             sprite("Sprite", ".", "5", 0, -h - 8),
             label("Label", ".", -16, -h - 19, w + 16, -h - 9, text)]
    nodes += list(extra_nodes)
    nodes.append(clickable(".", 0, -h - 8, w, h + 8, "2"))
    scene("entities/buildings/%s.tscn" % file, exts, nodes)


B = "res://entities/buildings/"
building("great_hall", "GreatHall", B + "great_hall.gd", B + "great_hall_interior.tscn", 64, 48, "Great Hall",
         extra_nodes=[node("Storage", "Node", ".", [("script", 'ExtResource("4")')])],
         extra_exts=[ext("Script", "res://economy/storage.gd", "4")])
building("kitchen", "Kitchen", B + "building.gd", B + "kitchen_interior.tscn", 48, 32, "Kitchen")
building("brewery", "Brewery", B + "building.gd", B + "brewery_interior.tscn", 48, 32, "Brewery")
building("smeltery", "Smeltery", B + "building.gd", B + "smeltery_interior.tscn", 48, 32, "Smeltery")
building("forge", "Forge", B + "building.gd", B + "forge_interior.tscn", 48, 32, "Forge")

scene("entities/buildings/mine_entrance.tscn",
      [ext("Script", B + "mine_entrance.gd", "1"), ext("Script", CLICKABLE, "2"),
       ext("Texture2D", A + "buildings/mine_entrance.png", "3")],
      [node("MineEntrance", "Node2D", None, [("script", 'ExtResource("1")')]),
       sprite("Sprite", ".", "3", 0, -32),
       label("Label", ".", -8, -43, 40, -33, "Mine"),
       clickable(".", 0, -32, 32, 32, "2")])

# --- Dwarf -----------------------------------------------------------------------------
D = "res://actors/dwarf/"
dwarf_exts = [
    ext("Script", D + "dwarf.gd", "1"), ext("Script", D + "dwarf_visual.gd", "2"),
    ext("Script", D + "components/hunger.gd", "3"), ext("Script", D + "components/thirst.gd", "4"),
    ext("Script", D + "components/carrier.gd", "5"), ext("Script", D + "components/grid_mover.gd", "6"),
    ext("Script", D + "components/worker.gd", "7"), ext("Script", D + "components/job_assignment.gd", "8"),
    ext("Script", D + "roles/idle_role.gd", "9"), ext("Script", D + "roles/farmer_role.gd", "10"),
    ext("Script", D + "roles/station_worker_role.gd", "11"), ext("Script", D + "roles/miner_role.gd", "12"),
    ext("Script", D + "roles/meal_break.gd", "13"), ext("Script", RECEIVER, "14"),
    ext("Texture2D", A + "dwarf/body.png", "15"), ext("Texture2D", A + "dwarf/beard.png", "16"),
    ext("Texture2D", A + "dwarf/pick.png", "17"), ext("Texture2D", A + "dwarf/sack.png", "18"),
    ext("Texture2D", A + "mine/lift_car.png", "19"), ext("Script", D + "roles/tool_errand.gd", "20"),
    ext("Texture2D", A + "ui/icons/marker.png", "21"), ext("Script", D + "components/idler.gd", "22"),
    ext("Texture2D", A + "ui/icons/idle.png", "23")]


def comp(name, rid, parent="."):
    return node(name, "Node", parent, [("script", 'ExtResource("%s")' % rid)])


scene("actors/dwarf/dwarf.tscn", dwarf_exts, [
    node("Dwarf", "Node2D", None, [("script", 'ExtResource("1")')]),
    node("Visual", "Node2D", ".", [("script", 'ExtResource("2")')]),
    sprite("LiftCar", "Visual", "19", -6, 0, [("visible", "false")]),
    # The sack hangs on the dwarf's back, tinted the colour of what's in it.
    sprite("CarrySlot", "Visual", "18", -8, -11, [("visible", "false")]),
    sprite("Body", "Visual", "15", -5, -16),
    # White beard, tinted per dwarf.
    sprite("Beard", "Visual", "16", -5, -16),
    node("ToolPivot", "Node2D", "Visual", [("visible", "false"), ("position", "Vector2(3, -7)")]),
    # Shown over his head while he's hovered.
    sprite("Marker", "Visual", "21", -3, -23, [("visible", "false")]),
    # Shown over his head while he has nothing to do.
    sprite("IdleMark", "Visual", "23", -3, -27, [("visible", "false")]),
    sprite("Pick", "Visual/ToolPivot", "17", -4, -10),
    comp("Hunger", "3"), comp("Thirst", "4"), comp("Carrier", "5"), comp("Mover", "6"),
    comp("Worker", "7"), comp("JobAssignment", "8"), comp("Idler", "22"),
    node("Roles", "Node", "."),
    comp("Idle", "9", "Roles"), comp("Farmer", "10", "Roles"), comp("StationWorker", "11", "Roles"),
    comp("Miner", "12", "Roles"), comp("DigWork", "14", "Roles/Miner"), comp("MealBreak", "13", "Roles"),
    comp("ToolErrand", "20", "Roles")])

# --- World -----------------------------------------------------------------------------
W = "res://world/"
world_exts = [
    ext("Script", W + "world.gd", "1"), ext("Script", W + "nav/nav_grid.gd", "2"),
    ext("PackedScene", W + "mine/terrain.tscn", "3"), ext("Script", W + "surface/surface.gd", "4"),
    ext("PackedScene", B + "great_hall.tscn", "5"), ext("Resource", "res://data/buildings/great_hall.tres", "6"),
    ext("PackedScene", B + "mine_entrance.tscn", "7"), ext("Resource", "res://data/buildings/mine_entrance.tres", "8"),
    ext("PackedScene", "res://entities/farm_plot/farm_plot.tscn", "9"),
    ext("Resource", "res://data/buildings/farm_plot.tres", "10"),
    ext("Script", W + "mine/shaft.gd", "13"), ext("PackedScene", W + "mine/mine_level_1.tscn", "14"),
    ext("Script", W + "interiors.gd", "15"), ext("Script", D + "dwarf_pool.gd", "16"),
    ext("Resource", "res://data/tuning/dwarf_names.tres", "17"), ext("PackedScene", D + "dwarf.tscn", "18"),
    ext("Script", W + "build_tool.gd", "19"), ext("Script", W + "view_camera.gd", "20"),
    ext("Script", W + "world_input.gd", "21"), ext("Script", W + "player_hand.gd", "22"),
    ext("Script", D + "components/carrier.gd", "23"), ext("Script", W + "surface/ground.gd", "24"),
    ext("Texture2D", A + "town/grass_tiles.png", "25"), ext("Texture2D", A + "mine/grass_edge.png", "26"),
    ext("Texture2D", A + "mine/ladder.png", "27"), ext("Texture2D", A + "mine/lift_rail.png", "28"),
    ext("Script", W + "furniture_tool.gd", "29"), ext("Script", "res://economy/ledger.gd", "30")]


def plot(name, tx, ty):
    """A starting farm plot: tilled, waiting for the player to sow it."""
    return node(name, None, "Surface/Placeables",
                [("def", 'ExtResource("10")'), ("tile", "Vector2i(%d, %d)" % (tx, ty))], instance="9")


def placed(name, scene_id, def_id, tx, ty):
    return node(name, None, "Surface/Placeables",
                [("def", 'ExtResource("%s")' % def_id), ("tile", "Vector2i(%d, %d)" % (tx, ty))], instance=scene_id)


world_nodes = [
    node("World", "Node2D", None, [("y_sort_enabled", "true"), ("script", 'ExtResource("1")')]),
    node("NavGrid", "Node", ".", [("script", 'ExtResource("2")')]),
    node("Ledger", "Node", ".", [("script", 'ExtResource("30")')]),
    rect("MineSky", ".", -1024, -200, 3072, 0, (0.45, 0.62, 0.78, 1), [("z_index", -1)]),
    tiled("MineGrass", ".", "26", 0, -4, 2048, 2),
    # The copper level fills the terrain but for a strip of bedrock below it.
    node("Terrain", None, ".", [("size_cells", "Vector2i(256, 38)")], instance="3"),
    # The town sits well above the mine in world space. Only doors join them.
    node("Surface", "Node2D", ".", [("y_sort_enabled", "true"), ("position", "Vector2(0, -1200)"),
                                     ("script", 'ExtResource("4")'), ("size_tiles", "Vector2i(128, 9)")]),
    node("Ground", "Node2D", "Surface", [("z_index", -2), ("script", 'ExtResource("24")'),
                                          ("tiles", 'ExtResource("25")')]),
    node("Placeables", "Node2D", "Surface", [("y_sort_enabled", "true")]),
    plot("FarmPlot1", 53, 5), plot("FarmPlot2", 54, 5),
    plot("FarmPlot3", 56, 5), plot("FarmPlot4", 57, 5),
    placed("GreatHall", "5", "6", 60, 1),
    placed("MineEntrance", "7", "8", 68, 2),
    node("Shaft", "Node2D", ".", [("script", 'ExtResource("13")'), ("ladder_texture", 'ExtResource("27")'),
                                   ("lift_texture", 'ExtResource("28")')]),
    node("MineLevel1", None, ".", [("position", "Vector2(0, 0)")], instance="14"),
    node("Interiors", "Node2D", ".", [("position", "Vector2(0, -2400)"), ("script", 'ExtResource("15")')]),
    node("Dwarves", "Node2D", ".", [("y_sort_enabled", "true"), ("script", 'ExtResource("16")'),
                                     ("names", 'ExtResource("17")')]),
]
for i in range(1, 17):
    world_nodes.append(node("Dwarf%02d" % i, None, "Dwarves", [], instance="18"))
world_nodes += [
    node("BuildTool", "Node2D", ".", [("script", 'ExtResource("19")')]),
    rect("Ghost", "BuildTool", 0, 0, 32, 32, (0.3, 1, 0.3, 0.45), [("visible", "false"), ("z_index", 10)]),
    node("FurnitureTool", "Node2D", ".", [("script", 'ExtResource("29")')]),
    rect("Ghost", "FurnitureTool", 0, 0, 8, 8, (0.3, 1, 0.3, 0.45), [("visible", "false"), ("z_index", 10)]),
    node("Camera", "Camera2D", ".", [("script", 'ExtResource("20")')]),
    node("WorldInput", "Node", ".", [("script", 'ExtResource("21")')]),
    node("Hand", "Node", ".", [("script", 'ExtResource("22")')]),
    node("Carrier", "Node", "Hand", [("script", 'ExtResource("23")')]),
]
scene("world/world.tscn", world_exts, world_nodes)

# --- Game ------------------------------------------------------------------------------
scene("game/game.tscn",
      [ext("Script", "res://game/game.gd", "1"), ext("Resource", "res://data/tuning/game_tuning.tres", "2"),
       ext("Resource", "res://data/tuning/catalog.tres", "3"), ext("Script", "res://game/sim_clock.gd", "4"),
       ext("Script", "res://game/game_window.gd", "5"), ext("Script", "res://economy/wallet.gd", "6"),
       ext("Script", "res://economy/unlocks.gd", "7"), ext("Script", "res://economy/shop.gd", "8"),
       ext("PackedScene", "res://world/world.tscn", "9"), ext("PackedScene", "res://ui/hud.tscn", "10")],
      [node("Game", "Node", None, [("script", 'ExtResource("1")'), ("tuning", 'ExtResource("2")'),
                                   ("catalog", 'ExtResource("3")')]),
       comp("SimClock", "4"),
       node("GameWindow", "Node", ".", [("script", 'ExtResource("5")'), ("strip_height", 450)]),
       comp("Wallet", "6"), comp("Unlocks", "7"), comp("Shop", "8"),
       node("World", None, ".", [], instance="9"),
       node("Hud", None, ".", [], instance="10")])

if __name__ == "__main__":
    print("scenes written")
