"""Draws the placeholder pixel art for the world: town ground, plots and
crops, buildings, interiors, the mine, and the dwarf.

Small sprites are character grids. Bigger ones (buildings, tile textures)
are drawn with a few helpers, seeded so every run gives the same pixels.

    python .tools/art/make_world_art.py
"""
import os
import random

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def rgba(hex_color, alpha=255):
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def save(image, rel_path):
    path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)


def fill(img, x0, y0, x1, y1, color):
    """Fills [x0, x1) x [y0, y1)."""
    for y in range(max(0, y0), min(img.height, y1)):
        for x in range(max(0, x0), min(img.width, x1)):
            img.putpixel((x, y), rgba(color))


def dot(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), rgba(color))


def speckle(img, x0, y0, x1, y1, colors, chance, rng):
    for y in range(y0, y1):
        for x in range(x0, x1):
            if rng.random() < chance:
                dot(img, x, y, rng.choice(colors))


def outline(img, color="1e1918"):
    """Draws a 1px outline around every opaque shape, outside it."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and src.getpixel((nx, ny))[3]:
                    img.putpixel((x, y), rgba(color))
                    break


def from_grid(grid, palette, size=None):
    width = size[0] if size else max(len(r) for r in grid)
    height = size[1] if size else len(grid)
    img = blank(width, height)
    for y, row in enumerate(grid):
        assert len(row) <= width, (row, width)
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), rgba(palette[ch]))
    return img


# --- Town ground -------------------------------------------------------------------
GRASS = "5f8a3e"
GRASS_LIGHT = "6f9a46"
GRASS_DARK = "527a36"


def grass_tile(rng, kind):
    img = blank(16, 16)
    fill(img, 0, 0, 16, 16, GRASS)
    speckle(img, 0, 0, 16, 16, [GRASS_LIGHT, GRASS_DARK], 0.12, rng)
    if kind == "tuft":
        for _ in range(3):
            x, y = rng.randrange(2, 14), rng.randrange(3, 14)
            for dx, h in ((-1, 1), (0, 2), (1, 1)):
                for i in range(h):
                    dot(img, x + dx, y - i, "8fbf55")
                dot(img, x + dx, y + 1, GRASS_DARK)
    elif kind == "flowers":
        for _ in range(3):
            x, y = rng.randrange(2, 14), rng.randrange(2, 14)
            color = rng.choice(["e8d040", "f0ecf4", "d06090"])
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                dot(img, x + dx, y + dy, color)
            dot(img, x, y, "e8a030")
    elif kind == "stone":
        x, y = rng.randrange(3, 11), rng.randrange(4, 11)
        fill(img, x, y, x + 4, y + 3, "a8a29a")
        fill(img, x + 1, y + 2, x + 4, y + 3, "6e6862")
        dot(img, x, y, "c8c2ba")
        fill(img, x, y + 3, x + 4, y + 4, GRASS_DARK)
    return img


def town():
    rng = random.Random(1)
    kinds = ["plain", "plain", "tuft", "tuft", "flowers", "stone"]
    sheet = blank(16 * len(kinds), 16)
    for i, kind in enumerate(kinds):
        sheet.paste(grass_tile(rng, kind), (i * 16, 0))
    save(sheet, "assets/town/grass_tiles.png")

    for name, base, dark, light in (("soil_dry", "8a6436", "6b4a28", "a07a48"),
                                    ("soil_wet", "5a3e22", "3e2a16", "6e5030")):
        img = blank(16, 16)
        fill(img, 1, 1, 15, 15, base)
        for y in (3, 7, 11):  # furrows
            fill(img, 2, y, 14, y + 1, dark)
            fill(img, 2, y + 1, 14, y + 2, light)
        speckle(img, 1, 1, 15, 15, [dark, light], 0.08, random.Random(2))
        # A raised lip of earth, darker along the bottom where it meets the grass.
        fill(img, 1, 0, 15, 1, light)
        fill(img, 0, 1, 1, 15, light)
        fill(img, 15, 1, 16, 15, dark)
        fill(img, 1, 15, 15, 16, dark)
        save(img, "assets/town/%s.png" % name)


# --- Crops (4 frames: three growth stages, then ripe) ---------------------------------
LEAF, LEAF_DARK, LEAF_EDGE = "6cb84a", "3a7a32", "2a5a24"


def bush(img, cx, cy, rx, ry, rng, light=LEAF, dark=LEAF_DARK):
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            d = ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2
            if d <= 1.0:
                lit = (x - cx) + (y - cy) < 0
                color = light if lit else dark
                if rng.random() < 0.2:
                    color = dark if lit else light
                dot(img, x, y, color)


def potato_frames():
    sheet = blank(64, 16)
    for stage in range(4):
        img = blank(16, 16)
        rng = random.Random(10 + stage)
        if stage == 0:
            for x, y in ((6, 12), (7, 13), (9, 12), (8, 13)):
                dot(img, x, y, LEAF)
            dot(img, 7, 14, LEAF_DARK)
            dot(img, 8, 14, LEAF_DARK)
        elif stage == 1:
            bush(img, 8, 11, 3, 2, rng)
        else:
            bush(img, 8, 10, 5, 3, rng)
            if stage == 3:
                speckle(img, 3, 7, 13, 13, ["c8b048", "e8d060"], 0.12, rng)  # tops yellowing
                for x in (4, 10):  # potatoes peeking out of the soil
                    fill(img, x, 13, x + 3, 15, "c89858")
                    dot(img, x + 2, 14, "8a6436")
        outline(img, LEAF_EDGE)
        sheet.paste(img, (stage * 16, 0))
    save(sheet, "assets/crops/potato_growth.png")


def barley_frames():
    sheet = blank(64, 16)
    heights = (3, 6, 9, 10)
    for stage in range(4):
        img = blank(16, 16)
        ripe = stage == 3
        stalk, stalk_dark = ("d8b850", "a08030") if ripe else (LEAF, LEAF_DARK)
        for i, x in enumerate(range(4, 13, 2) if stage else (6, 8, 10)):
            h = heights[stage] - (i % 2)
            lean = 1 if (stage and i % 3 == 0) else 0
            for j in range(h):
                dot(img, x + (lean if j > h // 2 else 0), 14 - j, stalk if j % 3 else stalk_dark)
            if stage >= 2:  # grain heads
                top = 14 - h
                head = ("f0d070", "c8a040") if ripe else ("9ccc6a", "6cb84a")
                for k in range(3):
                    dot(img, x + lean - (k % 2), top - k, head[k % 2])
        outline(img, "6b4a28" if ripe else LEAF_EDGE)
        sheet.paste(img, (stage * 16, 0))
    save(sheet, "assets/crops/barley_growth.png")


def carrot_frames():
    """Feathery tops; when ripe, orange shoulders show above the soil."""
    sheet = blank(64, 16)
    for stage in range(4):
        img = blank(16, 16)
        rng = random.Random(30 + stage)
        height = (2, 5, 8, 8)[stage]
        for x in (6, 8, 10) if stage else (7, 9):
            for j in range(height):
                dot(img, x + (j % 2 if stage > 1 else 0), 13 - j, LEAF if j % 2 else LEAF_DARK)
            if stage >= 2:
                for dx in (-1, 1):
                    dot(img, x + dx, 13 - height + 1, LEAF)
        if stage == 3:
            for x in (6, 9):
                fill(img, x, 13, x + 3, 15, "e8742a")
                dot(img, x + 1, 13, "f0a060")
        outline(img, LEAF_EDGE)
        sheet.paste(img, (stage * 16, 0))
    save(sheet, "assets/crops/carrot_growth.png")


def wheat_frames():
    """Like barley but paler, with long bearded heads when ripe."""
    sheet = blank(64, 16)
    heights = (3, 6, 10, 11)
    for stage in range(4):
        img = blank(16, 16)
        ripe = stage == 3
        stalk, stalk_dark = ("e8d080", "b89848") if ripe else ("8cc860", LEAF_DARK)
        for i, x in enumerate(range(3, 14, 2) if stage else (6, 8, 10)):
            h = heights[stage] - (i % 2)
            for j in range(h):
                dot(img, x, 14 - j, stalk if j % 3 else stalk_dark)
            if stage >= 2:
                top = 14 - h
                head = ("f4e0a0", "d0b060") if ripe else ("b8e080", "8cc860")
                for k in range(4):
                    dot(img, x, top - k, head[k % 2])
                if ripe:
                    dot(img, x + 1, top - 3, "f4e0a0")  # the beard
        outline(img, "6b4a28" if ripe else LEAF_EDGE)
        sheet.paste(img, (stage * 16, 0))
    save(sheet, "assets/crops/wheat_growth.png")


def radish_frames():
    """A rosette of round leaves; when ripe, a red shoulder at the soil."""
    sheet = blank(64, 16)
    for stage in range(4):
        img = blank(16, 16)
        rng = random.Random(50 + stage)
        if stage == 0:
            for x, y in ((7, 13), (8, 12), (9, 13)):
                dot(img, x, y, LEAF)
        else:
            r = (0, 2, 3, 3)[stage]
            for cx in (6, 10):
                bush(img, cx, 12 - r // 2, r - 1 if stage == 1 else r - 1, r - 1, rng)
        if stage == 3:
            fill(img, 6, 12, 11, 15, "c83a4a")
            fill(img, 7, 12, 9, 13, "e86070")
            dot(img, 8, 15, "f0e0e0")
        outline(img, LEAF_EDGE)
        sheet.paste(img, (stage * 16, 0))
    save(sheet, "assets/crops/radish_growth.png")


def onion_frames():
    """Upright hollow leaves; when ripe, a pale bulb sits on the soil."""
    sheet = blank(64, 16)
    for stage in range(4):
        img = blank(16, 16)
        height = (3, 6, 9, 9)[stage]
        for x in (7, 9) if stage < 2 else (6, 8, 10):
            for j in range(height):
                dot(img, x, 13 - j, "7cc05a" if j % 3 else LEAF_DARK)
        if stage == 3:
            fill(img, 5, 11, 12, 15, "e8d8a8")
            fill(img, 6, 10, 11, 11, "e8d8a8")
            fill(img, 6, 12, 8, 14, "f4ecd0")
            dot(img, 10, 13, "c8b080")
        outline(img, LEAF_EDGE)
        sheet.paste(img, (stage * 16, 0))
    save(sheet, "assets/crops/onion_growth.png")


# --- Buildings (top-down with a little tilt: roof, then the front wall) -----------------
def building(w, h, roof, roof_dark, wall, wall_dark, door_x, style, seed):
    """`h` is the full sprite height. The front wall is the bottom 14 rows."""
    rng = random.Random(seed)
    img = blank(w, h)
    wall_top = h - 14
    # Roof: shingle rows, a lit ridge along the top, a shadow line at the eaves.
    fill(img, 0, 0, w, wall_top, roof)
    for row, y in enumerate(range(3, wall_top - 1, 3)):
        fill(img, 0, y, w, y + 1, roof_dark)
        for x in range((row % 2) * 3, w, 6):
            dot(img, x, y + 1, roof_dark)
            dot(img, x, y + 2, roof_dark)
    fill(img, 0, 0, w, 2, roof_dark)
    fill(img, 0, 2, w, 3, "%02x%02x%02x" % tuple(min(255, c + 40) for c in rgba(roof)[:3]))
    fill(img, 0, wall_top - 1, w, wall_top, "1e1918")
    # Front wall.
    fill(img, 1, wall_top, w - 1, h, wall)
    if style == "stone":
        for y in range(wall_top + 3, h, 3):
            fill(img, 1, y, w - 1, y + 1, wall_dark)
            for x in range(2 + (y % 2) * 3, w - 1, 6):
                dot(img, x, y - 1, wall_dark)
                dot(img, x, y - 2, wall_dark)
    else:  # timber
        for x in range(4, w - 1, 6):
            fill(img, x, wall_top, x + 1, h, wall_dark)
        fill(img, 1, wall_top + 1, w - 1, wall_top + 2, wall_dark)
    speckle(img, 1, wall_top, w - 1, h, [wall_dark], 0.04, rng)
    # Door with a frame, and lit windows either side.
    fill(img, door_x - 1, h - 11, door_x + 9, h, "6b4423")
    fill(img, door_x, h - 10, door_x + 8, h, "2a1f18")
    fill(img, door_x + 6, h - 6, door_x + 7, h - 5, "e8c050")
    for wx in (door_x - 12, door_x + 14):
        if 2 <= wx <= w - 8:
            fill(img, wx - 1, wall_top + 3, wx + 6, wall_top + 9, "3e2a16")
            fill(img, wx, wall_top + 4, wx + 5, wall_top + 8, "e8c878")
            fill(img, wx + 2, wall_top + 4, wx + 3, wall_top + 8, "3e2a16")
    # Side outlines.
    fill(img, 0, wall_top, 1, h, "1e1918")
    fill(img, w - 1, wall_top, w, h, "1e1918")
    return img


def chimney(img, x, y):
    fill(img, x, y, x + 6, y + 9, "6e6862")
    fill(img, x, y, x + 6, y + 1, "1e1918")
    fill(img, x + 1, y + 1, x + 5, y + 3, "2a2422")
    for i, (dx, dy) in enumerate(((2, -2), (3, -4), (2, -6))):
        dot(img, x + dx, y + dy, "c8c2ba")
        dot(img, x + dx + 1, y + dy, "a8a29a")


def buildings():
    hall = building(64, 56, "8a3a2a", "6a2a1e", "8c8580", "6e6862", 24, "stone", 20)
    # A banner over the door.
    fill(hall, 26, 20, 30, 28, "c04030")
    fill(hall, 27, 22, 29, 25, "e8c050")
    save(hall, "assets/buildings/great_hall.png")

    kitchen = building(48, 40, "9a6a32", "74501e", "a07a50", "6b4a28", 16, "timber", 21)
    chimney(kitchen, 34, 6)
    save(kitchen, "assets/buildings/kitchen.png")

    brewery = building(48, 40, "4a5a6a", "34404c", "9a8a6a", "6b5d45", 16, "timber", 22)
    # A barrel by the door.
    fill(brewery, 30, 31, 36, 40, "8a5a2a")
    fill(brewery, 30, 33, 36, 34, "4a3a2a")
    fill(brewery, 30, 37, 36, 38, "4a3a2a")
    save(brewery, "assets/buildings/brewery.png")

    smeltery = building(48, 40, "5a5048", "443c36", "8c8580", "6e6862", 16, "stone", 24)
    fill(smeltery, 32, 2, 42, 20, "6e6862")  # a big stone chimney
    fill(smeltery, 32, 2, 42, 3, "1e1918")
    fill(smeltery, 34, 3, 40, 6, "e8742a")  # glowing at the top
    fill(smeltery, 35, 3, 39, 4, "f0c040")
    save(smeltery, "assets/buildings/smeltery.png")

    forge = building(48, 40, "3e3a40", "2c282e", "7a6a5a", "5a4a3a", 16, "timber", 25)
    fill(forge, 6, 10, 18, 16, "45403c")  # an anvil sign on the roof
    fill(forge, 4, 9, 20, 11, "6e6862")
    fill(forge, 10, 16, 14, 20, "45403c")
    save(forge, "assets/buildings/forge.png")

    market = building(48, 40, "b04a3a", "8a3a2a", "a07a50", "6b4a28", 16, "timber", 26)
    # A striped awning along the front wall.
    for x in range(1, 47):
        fill(market, x, 25, x + 1, 29, "f2e8d8" if (x // 4) % 2 else "c04030")
    fill(market, 1, 29, 47, 30, "1e1918")
    save(market, "assets/buildings/market.png")

    # Mine entrance: a rocky mound with a timbered hole in its face.
    rng = random.Random(23)
    pit = blank(32, 32)
    for y in range(4, 32):
        for x in range(32):
            d = ((x - 15.5) / 16) ** 2 + ((y - 30) / 26) ** 2
            if d <= 1.0:
                dot(pit, x, y, rng.choice(["8a7a6a", "7a6a5a", "9a8a78"]))
    fill(pit, 7, 12, 25, 32, "120e0c")
    fill(pit, 9, 14, 23, 32, "1e1715")
    for x in (5, 24):  # posts
        fill(pit, x, 10, x + 3, 32, "8a5a2a")
        fill(pit, x + 2, 10, x + 3, 32, "6b4423")
    fill(pit, 4, 7, 28, 11, "a0703c")  # lintel
    fill(pit, 4, 10, 28, 11, "6b4423")
    fill(pit, 14, 28, 18, 32, "6e6862")  # rails into the dark
    fill(pit, 15, 28, 17, 32, "1e1715")
    outline(pit)
    save(pit, "assets/buildings/mine_entrance.png")


# --- Interiors ------------------------------------------------------------------------
def interiors():
    rng = random.Random(30)
    floor = blank(16, 16)
    for row, y in enumerate(range(0, 16, 4)):
        fill(floor, 0, y, 16, y + 4, "8a6a48" if row % 2 else "7e6040")
        fill(floor, 0, y + 3, 16, y + 4, "5a4028")
        seam = (row * 5) % 16
        fill(floor, seam, y, seam + 1, y + 3, "5a4028")
        dot(floor, (seam + 3) % 16, y + 1, "4a3420")
    speckle(floor, 0, 0, 16, 16, ["94744e"], 0.05, rng)
    save(floor, "assets/interiors/floor_planks.png")

    # Walls: a 9-slice frame. The top band is the wall face seen above the
    # floor, the sides and bottom are the wall tops.
    wall = blank(24, 36)
    fill(wall, 0, 0, 24, 36, "4a403b")
    for y in range(2, 18, 4):
        fill(wall, 0, y, 24, y + 1, "3a322f")
        for x in range((y // 4 % 2) * 4, 24, 8):
            fill(wall, x, y - 3, x + 1, y, "3a322f")
    fill(wall, 0, 0, 24, 2, "5a504a")
    fill(wall, 0, 17, 24, 18, "2a2422")
    save(wall, "assets/interiors/wall_frame.png")

    door = blank(8, 6)
    fill(door, 0, 0, 8, 6, "6b4423")
    fill(door, 1, 0, 7, 6, "2a1f18")
    save(door, "assets/interiors/door.png")

    table = blank(16, 14)
    fill(table, 0, 0, 16, 14, "a0703c")
    for y in (4, 9):
        fill(table, 0, y, 16, y + 1, "8a5e30")
    fill(table, 0, 0, 16, 1, "c08a50")
    fill(table, 0, 12, 16, 14, "6b4423")
    outline_box(table)
    save(table, "assets/interiors/table.png")

    pile = blank(20, 14)
    fill(pile, 0, 4, 9, 14, "8a5a2a")  # crate
    fill(pile, 0, 8, 9, 9, "6b4423")
    fill(pile, 4, 4, 5, 14, "6b4423")
    for x0, color in ((9, "c8b48a"), (14, "b8a47a")):  # sacks
        fill(pile, x0, 5, x0 + 6, 14, color)
        fill(pile, x0 + 2, 3, x0 + 4, 5, color)
        fill(pile, x0 + 1, 12, x0 + 5, 13, "8a7a58")
    outline(pile)
    save(pile, "assets/interiors/storage_pile.png")

    stove = blank(16, 16)
    fill(stove, 1, 4, 15, 16, "45403c")
    fill(stove, 1, 4, 15, 6, "6e6862")
    fill(stove, 4, 9, 12, 14, "2a2422")
    fill(stove, 5, 11, 11, 14, "d9773a")
    fill(stove, 6, 12, 10, 14, "e8c050")
    fill(stove, 11, 0, 14, 4, "6e6862")
    outline_box(stove)
    save(stove, "assets/interiors/stove.png")

    pot = blank(16, 16)
    fill(pot, 4, 12, 6, 16, "45403c")  # legs
    fill(pot, 10, 12, 12, 16, "45403c")
    fill(pot, 1, 3, 15, 13, "b0622c")  # copper pot
    fill(pot, 2, 4, 14, 12, "d9773a")
    fill(pot, 3, 5, 5, 11, "f0a060")
    fill(pot, 0, 2, 16, 4, "8f4a22")  # rim
    fill(pot, 2, 2, 14, 3, "c8a040")  # mash showing
    fill(pot, 6, 13, 10, 16, "e8c050")  # fire underneath
    fill(pot, 7, 14, 9, 16, "d9773a")
    outline_box(pot)
    save(pot, "assets/interiors/mash_pot.png")

    smelter = blank(16, 16)
    fill(smelter, 1, 2, 15, 16, "6e6862")  # stone furnace
    for y in (5, 9, 13):
        fill(smelter, 1, y, 15, y + 1, "45403c")
    fill(smelter, 5, 0, 11, 3, "45403c")  # flue
    fill(smelter, 4, 9, 12, 15, "2a2422")  # mouth
    fill(smelter, 5, 11, 11, 15, "e8742a")
    fill(smelter, 6, 12, 10, 15, "f0c040")
    outline_box(smelter)
    save(smelter, "assets/interiors/smelter.png")

    anvil = blank(16, 16)
    fill(anvil, 3, 10, 13, 16, "8a5a2a")  # wooden block
    fill(anvil, 3, 12, 13, 13, "6b4423")
    fill(anvil, 1, 3, 14, 6, "6e6862")  # anvil face
    fill(anvil, 14, 4, 16, 5, "6e6862")  # horn
    fill(anvil, 1, 3, 14, 4, "a8a29a")
    fill(anvil, 5, 6, 10, 10, "45403c")  # waist
    outline_box(anvil)
    save(anvil, "assets/interiors/anvil.png")

    barrel = blank(16, 16)
    fill(barrel, 2, 1, 14, 16, "8a5a2a")
    fill(barrel, 3, 1, 13, 16, "a0703c")
    for y in (3, 8, 13):
        fill(barrel, 2, y, 14, y + 1, "45403c")
    fill(barrel, 6, 1, 7, 16, "8a5a2a")
    fill(barrel, 13, 9, 16, 11, "d9773a")  # copper tap
    outline_box(barrel)
    save(barrel, "assets/interiors/fermenter.png")

    # The market stall: a counter under a striped awning, seen from above.
    stall = blank(32, 16)
    for x in range(32):
        fill(stall, x, 0, x + 1, 5, "f2e8d8" if (x // 4) % 2 else "c04030")
    fill(stall, 0, 5, 32, 6, "1e1918")
    fill(stall, 0, 6, 32, 14, "a0703c")  # counter top
    fill(stall, 0, 6, 32, 7, "c08a50")
    fill(stall, 0, 13, 32, 14, "6b4423")
    fill(stall, 1, 14, 3, 16, "4a3420")  # legs
    fill(stall, 29, 14, 31, 16, "4a3420")
    outline_box(stall)
    save(stall, "assets/interiors/stall.png")

    # Goods on the counter, light so they take the colour of what's for sale.
    goods = blank(16, 8)
    for i, x in enumerate((1, 6, 11)):
        fill(goods, x, 3 - (i % 2), x + 4, 7, "e8e0d0")
        fill(goods, x, 3 - (i % 2), x + 4, 4 - (i % 2), "ffffff")
    outline_box(goods)
    save(goods, "assets/interiors/stall_goods.png")


def furniture():
    """Hall furniture, seen from above, on the 8px floor grid."""
    small = blank(16, 16)
    fill(small, 0, 0, 16, 14, "a0703c")
    fill(small, 0, 0, 16, 1, "c08a50")
    fill(small, 0, 6, 16, 7, "8a5e30")
    fill(small, 0, 12, 16, 14, "6b4423")
    fill(small, 1, 14, 3, 16, "4a3420")  # legs
    fill(small, 13, 14, 15, 16, "4a3420")
    outline_box(small)
    save(small, "assets/interiors/table_small.png")

    long = blank(32, 16)
    fill(long, 0, 0, 32, 14, "a0703c")
    fill(long, 0, 0, 32, 1, "c08a50")
    fill(long, 0, 6, 32, 7, "8a5e30")
    fill(long, 15, 0, 16, 12, "8a5e30")
    fill(long, 0, 12, 32, 14, "6b4423")
    for x in (1, 15, 29):
        fill(long, x, 14, x + 2, 16, "4a3420")
    outline_box(long)
    save(long, "assets/interiors/table_long.png")

    chair = blank(8, 8)
    fill(chair, 1, 0, 7, 3, "6b4423")  # back rest
    fill(chair, 1, 3, 7, 7, "a0703c")  # seat
    fill(chair, 1, 3, 7, 4, "c08a50")
    fill(chair, 1, 7, 2, 8, "4a3420")
    fill(chair, 6, 7, 7, 8, "4a3420")
    outline_box(chair)
    save(chair, "assets/interiors/chair.png")

    # 16x16 icons for the Hall tab.
    icon = blank(16, 16)
    icon.paste(chair.resize((8, 8)), (4, 4))
    big = chair.resize((16, 16), Image.NEAREST)
    save(big, "assets/ui/icons/chair.png")
    save(small, "assets/ui/icons/table.png")
    long_icon = blank(16, 16)
    long_icon.paste(long.resize((16, 8), Image.NEAREST), (0, 4))
    save(long_icon, "assets/ui/icons/long_table.png")


def outline_box(img, color="1e1918"):
    """Darkens the outermost opaque pixel of each row and column edge."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if not src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < img.width and 0 <= ny < img.height) or not src.getpixel((nx, ny))[3]:
                    img.putpixel((x, y), rgba(color))
                    break


# --- Mine ------------------------------------------------------------------------------
def tile(base, specks, rng, chance=0.25, cracks=None):
    img = blank(8, 8)
    fill(img, 0, 0, 8, 8, base)
    speckle(img, 0, 0, 8, 8, specks, chance, rng)
    if cracks:
        x, y = rng.randrange(1, 6), rng.randrange(1, 6)
        for i in range(3):
            dot(img, x + i, y + (i % 2), cracks)
    return img


def mine():
    rng = random.Random(40)
    tiles = [
        tile("73502f", ["8a6440", "5a3e24"], rng),                        # 0-2 dirt
        tile("73502f", ["8a6440", "5a3e24", "6b6b72"], rng),
        tile("6e4c2c", ["8a6440", "5a3e24"], rng),
        tile("6b6b72", ["85858c", "5a5a62"], rng, cracks="45454c"),        # 3-5 rock
        tile("67676e", ["85858c", "5a5a62"], rng, cracks="45454c"),
        tile("70707a", ["8a8a92", "5a5a62"], rng),
        tile("3e3230", ["2e2422", "4a3c38"], rng),                        # 6-7 bedrock
        tile("3a2e2c", ["2e2422", "4a3c38"], rng),
        tile("221b18", ["2a221e", "1a1412"], rng, 0.15),                  # 8-9 dug-out back wall
        tile("241c19", ["2a221e", "1a1412"], rng, 0.15),
    ]
    shadow = tile("221b18", ["2a221e"], rng, 0.1)  # 10: back wall right under a ceiling
    fill(shadow, 0, 0, 8, 2, "120e0c")
    tiles.append(shadow)
    sheet = blank(8 * len(tiles), 8)
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * 8, 0))
    save(sheet, "assets/mine/terrain_tiles.png")

    plank = blank(8, 3)
    fill(plank, 0, 0, 8, 1, "c08a50")
    fill(plank, 0, 1, 8, 2, "a0703c")
    fill(plank, 0, 2, 8, 3, "6b4423")
    dot(plank, 1, 1, "4a3420")
    dot(plank, 6, 1, "4a3420")
    save(plank, "assets/mine/plank.png")

    ladder = blank(8, 8)
    for x in (1, 6):
        fill(ladder, x, 0, x + 1, 8, "8a6436")
    for y in (2, 6):
        fill(ladder, 1, y, 7, y + 1, "a07a48")
    save(ladder, "assets/mine/ladder.png")

    rail = blank(8, 8)
    for x in (1, 6):
        fill(rail, x, 0, x + 1, 8, "a8acb4")
        dot(rail, x, 3, "6e6862")
    fill(rail, 3, 0, 5, 8, "4a4440")
    dot(rail, 4, 1, "6e6862")
    dot(rail, 3, 5, "6e6862")
    save(rail, "assets/mine/lift_rail.png")

    car = blank(12, 3)
    fill(car, 0, 0, 12, 1, "c8ccd4")
    fill(car, 0, 1, 12, 3, "7a808c")
    fill(car, 0, 2, 12, 3, "1e1918")
    save(car, "assets/mine/lift_car.png")

    grass = blank(16, 6)
    fill(grass, 0, 2, 16, 6, "73502f")
    fill(grass, 0, 0, 16, 3, GRASS)
    for x in range(0, 16, 3):
        dot(grass, x, 0, "8fbf55")
    speckle(grass, 0, 3, 16, 6, ["5a3e24"], 0.2, rng)
    fill(grass, 0, 2, 16, 3, GRASS_DARK)
    save(grass, "assets/mine/grass_edge.png")

    rng = random.Random(41)
    ore = blank(16, 16)
    for y in range(16):
        for x in range(16):
            d = ((x - 7.5) / 8) ** 2 + ((y - 7.5) / 8) ** 2
            if d <= 1.0:
                dot(ore, x, y, rng.choice(["6b6b72", "67676e", "5a5a62"]))
    for x, y in ((3, 4), (9, 3), (6, 8), (11, 9), (4, 11), (9, 12)):
        fill(ore, x, y, x + 2, y + 2, "d9773a")
        dot(ore, x, y, "f0a060")
        dot(ore, x + 1, y + 1, "8f4a22")
    outline(ore)
    save(ore, "assets/mine/copper_deposit.png")


# --- Dwarf -----------------------------------------------------------------------------
DWARF_PALETTE = {
    "k": "1e1918", "r": "a83a2a", "R": "7a2a1e", "f": "e8b090", "F": "c08a6a",
    "b": "4a6aa8", "B": "34508a", "y": "c8a040", "l": "4a3a2a", "L": "2e241a",
    "w": "ffffff", "g": "c8c8c8", "s": "c8ccd4", "S": "7a808c", "h": "a0703c",
}
DWARF_BODY = [
    "....kk....",
    "...krrk...",
    "..krrrRk..",
    ".kkkkkkkk.",
    ".kffffffk.",
    ".kfkffkfk.",
    ".kffffffk.",
    "kbbbbbbbbk",
    "kbbbbbbbBk",
    "kbbbbbbbBk",
    ".kyyyyyyk.",
    ".kbbbbbBk.",
    ".kllkkllk.",
    ".kllk.kllk",
    ".kLLk.kLLk",
    "..kk...kk.",
]
DWARF_BEARD = [
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    ".gwwwwwwg.",
    ".wwwwwwww.",
    ".gwwwwwwg.",
    "..wwwwww..",
    "...gwwg...",
    "....ww....",
]
PICK = [
    "kkkk....",
    "ksssk...",
    "kSkksk..",
    "kk.khk..",
    "...khk..",
    "...khk..",
    "...khk..",
    "...khk..",
    "...khk..",
    "....k...",
]
SACK = [
    "..kk..",
    ".kwwk.",
    "kwwwwk",
    "kwwwgk",
    "kwwggk",
    ".kkkk.",
]


def dwarf():
    save(from_grid(DWARF_BODY, DWARF_PALETTE), "assets/dwarf/body.png")
    save(from_grid(DWARF_BEARD, DWARF_PALETTE, (10, 16)), "assets/dwarf/beard.png")
    save(from_grid(PICK, DWARF_PALETTE), "assets/dwarf/pick.png")
    save(from_grid(SACK, DWARF_PALETTE), "assets/dwarf/sack.png")


if __name__ == "__main__":
    town()
    potato_frames()
    barley_frames()
    carrot_frames()
    onion_frames()
    wheat_frames()
    radish_frames()
    buildings()
    interiors()
    furniture()
    mine()
    dwarf()
    print("world art written")
