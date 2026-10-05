"""One-off generator for the hand-authored .tres content files."""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEFS = "res://data/defs/"


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def tres(rel, cls, script, props, exts=(), subs=""):
    """exts: list of (type, path); referenced in props as ExtResource("2"), ("3")..."""
    lines = ['[gd_resource type="Resource" script_class="%s" format=3]' % cls, ""]
    lines.append('[ext_resource type="Script" path="%s%s" id="1"]' % (DEFS, script))
    for i, (typ, path) in enumerate(exts):
        lines.append('[ext_resource type="%s" path="%s" id="%d"]' % (typ, path, i + 2))
    lines.append("")
    if subs:
        lines.append(subs)
    lines.append("[resource]")
    lines.append('script = ExtResource("1")')
    for key, value in props:
        lines.append("%s = %s" % (key, value))
    write(rel, "\n".join(lines) + "\n")


def color(r, g, b):
    return "Color(%s, %s, %s, 1)" % (r, g, b)


# --- Items -----------------------------------------------------------------
def icon_ext(name):
    return ("Texture2D", "res://assets/items/%s.png" % name)


def item(name, display, col, sell=0, buy=0):
    tres("data/items/%s.tres" % name, "ItemDef", "item_def.gd", [
        ("id", '&"%s"' % name), ("display_name", '"%s"' % display), ("icon", 'ExtResource("2")'),
        ("color", col), ("sell_price", sell), ("buy_price", buy)], exts=[icon_ext(name)])


def meal(name, display, col, shift, sell=0, buy=0):
    tres("data/items/%s.tres" % name, "MealDef", "meal_def.gd", [
        ("id", '&"%s"' % name), ("display_name", '"%s"' % display), ("icon", 'ExtResource("2")'),
        ("color", col), ("sell_price", sell), ("buy_price", buy), ("shift_seconds", shift)],
        exts=[icon_ext(name)])


def drink(name, display, col, low, high, duration, sell=0, buy=0):
    tres("data/items/%s.tres" % name, "DrinkDef", "drink_def.gd", [
        ("id", '&"%s"' % name), ("display_name", '"%s"' % display), ("icon", 'ExtResource("3")'),
        ("color", col), ("sell_price", sell), ("buy_price", buy), ("low_multiplier", low),
        ("high_multiplier", high), ("duration_seconds", duration),
        ("taper", 'ExtResource("2")')],
        exts=[("Curve", "res://data/items/default_taper.tres"), icon_ext(name)])


write("data/items/default_taper.tres", """[gd_resource type="Curve" format=3]

[resource]
_data = [Vector2(0, 1), 0.0, 0.0, 0, 0, Vector2(0.65, 0.9), -0.3, -0.3, 0, 0, Vector2(1, 0), -5.0, 0.0, 0, 0]
point_count = 3
""")

item("potato", "Potato", color(0.8, 0.65, 0.4), sell=1)
item("barley", "Barley", color(0.9, 0.8, 0.35), sell=1)
item("copper_ore", "Copper Ore", color(0.85, 0.5, 0.25), sell=5)
# In-between brewing goods: made in a mash pot, poured into a fermenter.
item("barley_mash", "Barley mash", color(0.82, 0.68, 0.32))
item("potato_mash", "Potato mash", color(0.86, 0.8, 0.62))
item("carrot", "Carrot", color(0.93, 0.55, 0.2), sell=1)
item("onion", "Onion", color(0.9, 0.82, 0.6), sell=2)
meal("roast_carrots", "Roast carrots", color(0.85, 0.45, 0.2), 400.0, sell=2)
meal("onion_soup", "Onion soup", color(0.8, 0.65, 0.35), 960.0, sell=4)
item("wheat", "Wheat", color(0.92, 0.8, 0.45), sell=1)
item("radish", "Radish", color(0.85, 0.25, 0.35), sell=1)
item("wheat_mash", "Wheat mash", color(0.9, 0.8, 0.55))
item("radish_mash", "Radish mash", color(0.8, 0.4, 0.45))
item("copper_ingot", "Copper ingot", color(0.9, 0.55, 0.3), sell=20)


def tool(name, display, col, job, multiplier, sell):
    """`job` is a JobAssignment.Kind: 1 farmer, 2 station worker, 3 miner."""
    tres("data/items/%s.tres" % name, "ToolDef", "tool_def.gd", [
        ("id", '&"%s"' % name), ("display_name", '"%s"' % display), ("icon", 'ExtResource("2")'),
        ("color", col), ("sell_price", sell), ("job", job), ("work_multiplier", multiplier)],
        exts=[icon_ext(name)])


tool("copper_pick", "Copper pick", color(0.95, 0.6, 0.35), 3, 1.5, 30)
tool("copper_sickle", "Copper sickle", color(0.95, 0.6, 0.35), 1, 1.5, 30)
meal("stew", "Stew", color(0.6, 0.3, 0.15), 600.0, sell=3)
meal("gruel", "Gruel", color(0.75, 0.72, 0.6), 180.0, buy=4)
drink("grog", "Grog", color(0.45, 0.55, 0.35), 0.5, 0.75, 180.0, buy=3)
drink("ale", "Ale", color(0.9, 0.65, 0.2), 0.5, 1.0, 360.0, sell=4)
# Steady and long, or a short sharp kick.
drink("wheat_beer", "Wheat beer", color(0.95, 0.82, 0.4), 0.5, 0.9, 480.0, sell=4)
drink("radish_spirit", "Radish spirit", color(0.85, 0.3, 0.4), 0.5, 1.15, 120.0, sell=5)
drink("cognac", "Aged Mushroom Cap Cognac", color(0.5, 0.2, 0.45), 0.5, 1.5, 1800.0)

# --- Unlocks ----------------------------------------------------------------------
def unlock_sub(exts, counter, needed, label, coins, items=()):
    """Adds an UnlockDef sub-resource (id "unlock"): a Ledger milestone, then a
    trade of coins and, optionally, goods: a list of (item, count)."""
    text = ""
    price_refs = []
    if items:
        exts.append(("Script", DEFS + "item_stack.gd"))
        stack_script = len(exts) + 1
        for k, (item, count) in enumerate(items):
            exts.append(("Resource", "res://data/items/%s.tres" % item))
            text += ('[sub_resource type="Resource" id="price%d"]\nscript = ExtResource("%d")\n'
                     'item = ExtResource("%d")\ncount = %d\n\n' % (k, stack_script, len(exts) + 1, count))
            price_refs.append('SubResource("price%d")' % k)
    exts.append(("Script", DEFS + "unlock_def.gd"))
    text += ('[sub_resource type="Resource" id="unlock"]\nscript = ExtResource("%d")\ncounter = &"%s"\n'
             'needed = %d\nlabel = "%s"\ncoins = %d\n' % (len(exts) + 1, counter, needed, label, coins))
    if items:
        text += 'items = Array[ExtResource("%d")]([%s])\n' % (stack_script, ", ".join(price_refs))
    return text


# --- Crops -----------------------------------------------------------------
def crop(name, display, produce, col, grow, unlock=None):
    exts = [("Resource", "res://data/items/%s.tres" % produce),
            ("Texture2D", "res://assets/crops/%s_growth.png" % name)]
    props = [("id", '&"%s"' % name), ("display_name", '"%s"' % display),
             ("produce", 'ExtResource("2")'), ("growth_frames", 'ExtResource("3")'), ("yield_count", 2), ("color", col),
             ("seed_cost", 1), ("water_work", 1.0), ("harvest_work", 1.5),
             ("grow_seconds", grow), ("watered_seconds", 30.0)]
    subs = ""
    if unlock:
        subs = unlock_sub(exts, *unlock)
        props.append(("unlock", 'SubResource("unlock")'))
    tres("data/crops/%s.tres" % name, "CropDef", "crop_def.gd", props, exts=exts, subs=subs)


crop("potato", "Potato", "potato", color(0.3, 0.6, 0.25), 90.0)
crop("barley", "Barley", "barley", color(0.75, 0.7, 0.3), 120.0)
# Early unlocks: coins only. Ore and ingots come into trades later.
crop("carrot", "Carrot", "carrot", color(0.4, 0.7, 0.3), 60.0, unlock=("harvested", 20, "Harvest crops", 15))
crop("onion", "Onion", "onion", color(0.45, 0.65, 0.35), 150.0, unlock=("meals_made", 15, "Cook meals", 30))
crop("radish", "Radish", "radish", color(0.4, 0.7, 0.3), 70.0, unlock=("harvested", 40, "Harvest crops", 25))
crop("wheat", "Wheat", "wheat", color(0.85, 0.75, 0.35), 120.0, unlock=("drinks_made", 10, "Make drinks", 40))


# --- Recipes ---------------------------------------------------------------------
def recipe(name, display, inputs, out, n_out, work, seconds):
    """`inputs` is a list of (item, count): one or two kinds of ingredient."""
    exts = [("Script", DEFS + "item_stack.gd"), ("Resource", "res://data/items/%s.tres" % out)]
    subs = []
    for k, (item, count) in enumerate(inputs):
        exts.append(("Resource", "res://data/items/%s.tres" % item))
        subs.append('[sub_resource type="Resource" id="in%d"]\nscript = ExtResource("2")\nitem = ExtResource("%d")\n'
                    "count = %d\n" % (k, len(exts) + 1, count))
    tres("data/recipes/%s.tres" % name, "RecipeDef", "recipe_def.gd", [
        ("id", '&"%s"' % name), ("display_name", '"%s"' % display),
        ("inputs", 'Array[ExtResource("2")]([%s])' % ", ".join('SubResource("in%d")' % k for k in range(len(inputs)))),
        ("output", 'ExtResource("3")'), ("output_count", n_out),
        ("load_work", work), ("process_seconds", seconds)], exts=exts, subs="\n".join(subs))


# Stove. Quick and thin, or slow and filling (see each meal's shift_seconds).
recipe("gruel", "Gruel", [("potato", 1)], "gruel", 1, 5.0, 20.0)
recipe("roast_carrots", "Roast carrots", [("carrot", 2)], "roast_carrots", 1, 5.0, 30.0)
recipe("stew", "Stew", [("potato", 2)], "stew", 1, 5.0, 60.0)
recipe("onion_soup", "Onion soup", [("onion", 1), ("potato", 2)], "onion_soup", 1, 6.0, 90.0)
# Mash pot
recipe("barley_mash", "Barley mash", [("barley", 3)], "barley_mash", 1, 5.0, 30.0)
recipe("potato_mash", "Potato mash", [("potato", 2)], "potato_mash", 1, 5.0, 20.0)
recipe("wheat_mash", "Wheat mash", [("wheat", 3)], "wheat_mash", 1, 5.0, 30.0)
recipe("radish_mash", "Radish mash", [("radish", 3)], "radish_mash", 1, 5.0, 25.0)
# Fermenter: one mash makes several drinks, slowly. Loading is the pour.
recipe("ale", "Ale", [("barley_mash", 1)], "ale", 4, 4.0, 180.0)
recipe("grog", "Grog", [("potato_mash", 1)], "grog", 4, 4.0, 90.0)
recipe("wheat_beer", "Wheat beer", [("wheat_mash", 1)], "wheat_beer", 4, 4.0, 150.0)
recipe("radish_spirit", "Radish spirit", [("radish_mash", 1)], "radish_spirit", 3, 4.0, 120.0)
# Smelter and anvil
recipe("copper_ingot", "Copper ingot", [("copper_ore", 3)], "copper_ingot", 1, 6.0, 60.0)
recipe("copper_pick", "Copper pick", [("copper_ingot", 2)], "copper_pick", 1, 8.0, 90.0)
recipe("copper_sickle", "Copper sickle", [("copper_ingot", 2)], "copper_sickle", 1, 8.0, 90.0)


# --- Workstations ------------------------------------------------------------------
def station(name, display, cost, recipes, fed_by=None):
    exts = [("PackedScene", "res://entities/workstations/%s.tscn" % name),
            ("Texture2D", "res://assets/interiors/%s.png" % name),
            ("Script", DEFS + "recipe_def.gd")]
    refs = []
    for r in recipes:
        exts.append(("Resource", "res://data/recipes/%s.tres" % r))
        refs.append('ExtResource("%d")' % (len(exts) + 1))
    props = [("id", '&"%s"' % name), ("display_name", '"%s"' % display),
             ("scene", 'ExtResource("2")'), ("icon", 'ExtResource("3")'), ("footprint", "Vector2i(2, 2)"),
             ("cost", cost), ("blocks_walking", "true"), ("needs_front_access", "true"),
             ("recipes", 'Array[ExtResource("4")]([%s])' % ", ".join(refs))]
    if fed_by:
        exts.append(("Resource", "res://data/workstations/%s.tres" % fed_by))
        props.append(("fed_by", 'ExtResource("%d")' % (len(exts) + 1)))
    tres("data/workstations/%s.tres" % name, "WorkstationDef", "workstation_def.gd", props, exts=exts)


station("stove", "Stove", 20, ["gruel", "roast_carrots", "stew", "onion_soup"])
station("mash_pot", "Mash pot", 20, ["potato_mash", "barley_mash", "wheat_mash", "radish_mash"])
station("fermenter", "Fermenter", 25, ["grog", "ale", "wheat_beer", "radish_spirit"], fed_by="mash_pot")
station("smelter", "Smelter", 30, ["copper_ingot"])
station("anvil", "Anvil", 30, ["copper_pick", "copper_sickle"])

# --- Buildings -------------------------------------------------------------
def building(name, display, footprint, scene=None, cost=0, unlock=None, buildable=True,
             can_move=True, can_destroy=True, stations=(), blocks=True, door=1):
    exts = []
    props = [("id", '&"%s"' % name), ("display_name", '"%s"' % display)]
    if scene:
        exts.append(("PackedScene", scene))
        props.append(("scene", 'ExtResource("%d")' % (len(exts) + 1)))
    props += [("footprint", "Vector2i(%d, %d)" % footprint), ("cost", cost),
              ("buildable", str(buildable).lower()),
              ("can_move", str(can_move).lower()), ("can_destroy", str(can_destroy).lower()),
              ("blocks_walking", str(blocks).lower()), ("door_offset_cells", door)]
    if stations:
        exts.append(("Script", DEFS + "workstation_def.gd"))
        script_id = len(exts) + 1
        refs = []
        for s in stations:
            exts.append(("Resource", "res://data/workstations/%s.tres" % s))
            refs.append('ExtResource("%d")' % (len(exts) + 1))
        props.append(("workstations", 'Array[ExtResource("%d")]([%s])' % (script_id, ", ".join(refs))))
    subs = ""
    if unlock:
        subs = unlock_sub(exts, *unlock)
        props.append(("unlock", 'SubResource("unlock")'))
    tres("data/buildings/%s.tres" % name, "BuildingDef", "building_def.gd", props, exts=exts, subs=subs)


building("great_hall", "Great Hall", (4, 3), buildable=False, can_destroy=False, door=3)
building("mine_entrance", "Mine Entrance", (2, 2), buildable=False, can_destroy=False, door=1)
building("farm_plot", "Farm Plot", (1, 1), "res://entities/farm_plot/farm_plot.tscn", cost=3, blocks=False)
building("kitchen", "Kitchen", (3, 2), "res://entities/buildings/kitchen.tscn", cost=30, stations=["stove"], door=2)
building("brewery", "Brewery", (3, 2), "res://entities/buildings/brewery.tscn", cost=40,
         unlock=("harvested:barley", 20, "Harvest barley", 60),
         stations=["mash_pot", "fermenter"], door=2)
# Metal: the first trades that cost goods as well as coins.
building("smeltery", "Smeltery", (3, 2), "res://entities/buildings/smeltery.tscn", cost=50,
         unlock=("mined", 15, "Mine ore", 80, [("copper_ore", 5)]), stations=["smelter"], door=2)
building("forge", "Forge", (3, 2), "res://entities/buildings/forge.tscn", cost=60,
         unlock=("made:copper_ingot", 5, "Smelt ingots", 50, [("copper_ingot", 3)]), stations=["anvil"], door=2)

# --- Furniture ---------------------------------------------------------------
def furniture(name, display, footprint, cost, blocks=True, seat=False):
    tres("data/furniture/%s.tres" % name, "FurnitureDef", "furniture_def.gd", [
        ("id", '&"%s"' % name), ("display_name", '"%s"' % display),
        ("scene", 'ExtResource("2")'), ("icon", 'ExtResource("3")'),
        ("footprint", "Vector2i(%d, %d)" % footprint), ("cost", cost),
        ("blocks_walking", str(blocks).lower()), ("is_seat", str(seat).lower())],
        exts=[("PackedScene", "res://entities/furniture/%s.tscn" % name),
              ("Texture2D", "res://assets/ui/icons/%s.png" % name)])


furniture("chair", "Chair", (1, 1), 5, blocks=False, seat=True)
furniture("table", "Table", (2, 2), 10)
furniture("long_table", "Long table", (4, 2), 20)

# --- Mine level ------------------------------------------------------------
# Level 1 is the copper layer: it starts right under the grass, with a few
# rows of dirt over stone. The shaft starts short, landing in the dirt.
tres("data/mine/level_1.tres", "MineLevelDef", "mine_level_def.gd", [
    ("size_cells", "Vector2i(256, 36)"), ("landing_row", 4), ("landing_half_width", 2),
    ("noise_seed", 7), ("dirt_rows", 6), ("dirt_edge_rows", 2.5), ("dirt_work", 2.0), ("rock_work", 5.0),
    ("straight_start_columns", 6), ("branch_straight_columns", 2), ("branch_gap_rows", 3),
    ("slope_chance", 0.2), ("fork_chance", 0.06), ("max_heads", 8)])

# --- Names -----------------------------------------------------------------
starts = ["Ur", "Bal", "Dur", "Thor", "Gim", "Bom", "Dwal", "Kil", "Nor", "Bru", "Hild", "Dag", "Tov", "Brun", "Ost"]
ends = ["ist", "in", "ok", "grim", "li", "bur", "da", "ra", "mund", "gar", "dis", "ni", "vi", "rek"]
tres("data/tuning/dwarf_names.tres", "NameList", "name_list.gd", [
    ("starts", "PackedStringArray(%s)" % ", ".join('"%s"' % s for s in starts)),
    ("ends", "PackedStringArray(%s)" % ", ".join('"%s"' % s for s in ends))])

# --- Tuning ----------------------------------------------------------------
subs = """[sub_resource type="Resource" id="stock_gruel"]
script = ExtResource("2")
item = ExtResource("3")
count = 10

[sub_resource type="Resource" id="stock_grog"]
script = ExtResource("2")
item = ExtResource("4")
count = 10
"""
tres("data/tuning/game_tuning.tres", "GameTuning", "game_tuning.gd", [
    ("starting_coins", 50), ("starting_dwarves", 4),
    ("starting_stock", 'Array[ExtResource("2")]([SubResource("stock_gruel"), SubResource("stock_grog")])'),
    ("starting_food_seconds", 180.0),
    ("walk_speed", 24.0), ("ladder_speed", 8.0), ("lift_speed", 64.0),
    ("base_work_rate", 1.0), ("carry_capacity", 5), ("eat_seconds", 4.0),
    ("manual_work_per_click", 0.5), ("hand_capacity", 50),
    ("hire_cost", 40), ("hire_cost_growth", 20), ("lift_cost", 150)],
    exts=[("Script", DEFS + "item_stack.gd"),
          ("Resource", "res://data/items/gruel.tres"),
          ("Resource", "res://data/items/grog.tres")],
    subs=subs)

# --- Catalog ---------------------------------------------------------------
item_names = ["potato", "barley", "carrot", "onion", "radish", "wheat", "gruel", "roast_carrots", "stew", "onion_soup",
              "grog", "ale", "wheat_beer", "radish_spirit", "cognac", "copper_ore", "copper_ingot", "copper_pick",
              "copper_sickle", "potato_mash", "barley_mash", "wheat_mash", "radish_mash"]
building_names = ["farm_plot", "kitchen", "brewery", "smeltery", "forge"]
exts = [("Script", DEFS + "item_def.gd")]
item_refs = []
for n in item_names:
    exts.append(("Resource", "res://data/items/%s.tres" % n))
    item_refs.append('ExtResource("%d")' % (len(exts) + 1))
exts.append(("Script", DEFS + "building_def.gd"))
building_script = len(exts) + 1
building_refs = []
for n in building_names:
    exts.append(("Resource", "res://data/buildings/%s.tres" % n))
    building_refs.append('ExtResource("%d")' % (len(exts) + 1))
exts.append(("Script", DEFS + "crop_def.gd"))
crop_script = len(exts) + 1
crop_refs = []
for n in ["potato", "barley", "carrot", "onion", "radish", "wheat"]:
    exts.append(("Resource", "res://data/crops/%s.tres" % n))
    crop_refs.append('ExtResource("%d")' % (len(exts) + 1))
ore_refs = []
for n in ["copper_ore", "copper_ingot", "copper_pick", "copper_sickle"]:
    exts.append(("Resource", "res://data/items/%s.tres" % n))
    ore_refs.append('ExtResource("%d")' % (len(exts) + 1))
exts.append(("Script", DEFS + "furniture_def.gd"))
furniture_script = len(exts) + 1
furniture_refs = []
for n in ["chair", "table", "long_table"]:
    exts.append(("Resource", "res://data/furniture/%s.tres" % n))
    furniture_refs.append('ExtResource("%d")' % (len(exts) + 1))
tres("data/tuning/catalog.tres", "ContentCatalog", "content_catalog.gd", [
    ("crops", 'Array[ExtResource("%d")]([%s])' % (crop_script, ", ".join(crop_refs))),
    ("furniture", 'Array[ExtResource("%d")]([%s])' % (furniture_script, ", ".join(furniture_refs))),
    ("ores", 'Array[ExtResource("2")]([%s])' % ", ".join(ore_refs)),
    ("items", 'Array[ExtResource("2")]([%s])' % ", ".join(item_refs)),
    ("buildings", 'Array[ExtResource("%d")]([%s])' % (building_script, ", ".join(building_refs)))],
    exts=exts)

print("data written")
