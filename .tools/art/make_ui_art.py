"""Draws the placeholder pixel art for the UI: frames, icons and the font.

Everything is drawn from little character grids below, so tweaking a sprite
is a matter of editing its grid and re-running:

    python .tools/art/make_ui_art.py

Writes into assets/ (ui frames, ui icons, item icons, the bitmap font).
"""
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# One shared palette. '.' is transparent.
PALETTE = {
    "k": "1e1918",  # outline
    "w": "f2e8d8",  # near white
    "g": "a8a29a",  # light grey
    "G": "6e6862",  # mid grey
    "d": "45403c",  # dark grey
    "b": "a0703c",  # wood
    "B": "6b4423",  # dark wood
    "y": "e8c050",  # gold
    "Y": "b08a2c",  # dark gold
    "o": "d9773a",  # copper
    "O": "8f4a22",  # dark copper
    "r": "c04030",  # red
    "R": "8a2a2a",  # dark red
    "e": "6cb84a",  # leaf
    "E": "3a7a32",  # dark leaf
    "u": "6aa8e0",  # water
    "U": "3a68a8",  # deep water
    "t": "c89858",  # potato
    "T": "8a6436",  # potato shade
    "p": "e0d6b0",  # gruel
    "P": "b0a680",  # gruel shade
    "n": "a04aa0",  # cognac
    "N": "5a2060",  # cognac shade
    "s": "c8ccd4",  # steel
    "S": "7a808c",  # steel shade
}


def rgba(hex_color, alpha=255):
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def draw(grid, palette=PALETTE, size=None):
    """Turns a list of strings into an image. Short rows are padded."""
    width = size[0] if size else max(len(row) for row in grid)
    height = size[1] if size else len(grid)
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for y, row in enumerate(grid):
        assert len(row) <= width, (row, width)
        for x, ch in enumerate(row):
            if ch != ".":
                image.putpixel((x, y), rgba(palette[ch]))
    return image


def save(image, rel_path):
    path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)


# --- Frames (9-slice) ----------------------------------------------------------
# k = outline, h = top-left light edge, f = fill, s = bottom-right dark edge.
BUTTON = [
    ".kkkkkk.",
    "khhhhhhk",
    "khffffsk",
    "khffffsk",
    "khffffsk",
    "khffffsk",
    "kssssssk",
    ".kkkkkk.",
]
BUTTON_STATES = {
    "button_normal": {"h": "8c7b70", "f": "6b5d55", "s": "3d332e"},
    "button_hover": {"h": "a89585", "f": "807065", "s": "4a3e38"},
    # Pressed and toggled-on read as a gold, sunken key.
    "button_pressed": {"h": "8a6a36", "f": "c9a464", "s": "e8c98a"},
    "button_disabled": {"h": "554b46", "f": "4a413d", "s": "3a322f"},
}
PANEL = [
    "kkkkkkkk",
    "khhhhhhk",
    "khffffhk",
    "khffffhk",
    "khffffhk",
    "khffffhk",
    "khhhhhhk",
    "kkkkkkkk",
]
SLOT = [
    "kkkkkkkk",
    "ksssssfk",
    "ksffffhk",
    "ksffffhk",
    "ksffffhk",
    "ksffffhk",
    "kfhhhhhk",
    "kkkkkkkk",
]


def frames():
    outline = {"k": "1a1514"}
    for name, colors in BUTTON_STATES.items():
        save(draw(BUTTON, {**outline, **colors}), "assets/ui/frames/%s.png" % name)
    save(draw(PANEL, {**outline, "h": "5a4d48", "f": "3a3230"}), "assets/ui/frames/panel.png")
    save(draw(SLOT, {**outline, "s": "1f1a19", "f": "2c2522", "h": "3e3531"}), "assets/ui/frames/slot.png")


# --- Icons ------------------------------------------------------------------------
ICONS = {
    "ui/icons/hoe": [
        "................",
        ".........kkkk...",
        "........kssssk..",
        "........kSSssk..",
        ".........kkSSk..",
        "..........kbkk..",
        ".........kbk....",
        "........kbk.....",
        ".......kbk......",
        "......kbk.......",
        ".....kbk........",
        "....kbk.........",
        "...kbk..........",
        "..kBk...........",
        "..kk............",
    ],
    "ui/icons/look": [
        "................",
        "....kkkkk.......",
        "...kgggggk......",
        "..kgwuuuugk.....",
        "..kgwuuuugk.....",
        "..kguuuuugk.....",
        "..kguuuuUgk.....",
        "..kguuuUUgk.....",
        "...kgggggk......",
        "....kkkkkbk.....",
        "..........kbk...",
        "...........kbk..",
        "............kBk.",
        ".............kk.",
    ],
    "ui/icons/bucket": [
        "................",
        ".....kkkkkk.....",
        "....k......k....",
        "...k........k...",
        "..kkkkkkkkkkkk..",
        "..kuuuuuuuuuuk..",
        "..kSsssssssssk..",
        "...kSsssssssk...",
        "...kSsswssssk...",
        "...kSsswssssk...",
        "...kSssssssSk...",
        "....kSssssSk....",
        "....kSSSSSSk....",
        ".....kkkkkk.....",
    ],
    "ui/icons/shears": [
        "................",
        "............kk..",
        "...........ksk..",
        "..kk......ksk...",
        "..ksk....ksk....",
        "...ksk..ksk.....",
        "....kskksk......",
        ".....kssk.......",
        ".....kssk.......",
        "....kskksk......",
        "...krrk.krrk....",
        "..krkkrkrkkrk...",
        "..krkkrkrkkrk...",
        "...krrk..krrk...",
        "....kk....kk....",
    ],
    "ui/icons/lock": [
        "................",
        "................",
        ".....kkkkkk.....",
        "....kSkkkkSk....",
        "....kSk..kSk....",
        "....kSk..kSk....",
        "...kkkkkkkkkk...",
        "...kyyyyyyyyk...",
        "...kyYYkkYYyk...",
        "...kyYYkkYYyk...",
        "...kyYYYkYYyk...",
        "...kyyyyyyyyk...",
        "...kYYYYYYYYk...",
        "...kkkkkkkkkk...",
    ],
    "ui/icons/tab_farm": [
        "................",
        "................",
        ".....kk..kk.....",
        "....keEk.keEk...",
        "...keeEkkeeEk...",
        "...kEEEkEEEk....",
        "....kkk.kkk.....",
        ".......kEk......",
        ".......kEk......",
        ".......kEk......",
        "....kkkkEkkkk...",
        "...kbbbbbbbbbk..",
        "...kBbbbbbbbBk..",
        "....kBBBBBBBk...",
        ".....kkkkkkk....",
    ],
    "ui/icons/tab_build": [
        "................",
        "..kkkkkkkk......",
        ".kSssssssSk.....",
        ".kSssssssSk.....",
        ".kSSSSSSSSk.....",
        "..kkkkbkkk......",
        "......kbk.......",
        "......kbk.......",
        "......kbk.......",
        "......kbk.......",
        "......kbk.......",
        "......kbk.......",
        "......kBk.......",
        "......kBk.......",
        ".......k........",
    ],
    "ui/icons/tab_shop": [
        "................",
        "......kkkk......",
        ".....kbBBbk.....",
        "......kbbk......",
        "....kkbbbbkk....",
        "...kbbbbbbbbk...",
        "..kbbbyyyybbbk..",
        "..kbbyYbbbbbbk..",
        "..kbbbyyybbbbk..",
        "..kbbbbbbYybbk..",
        "..kbbyyyyYbbbk..",
        "..kbbbbbbbbbbk..",
        "...kBBBBBBBBk...",
        "....kkkkkkkk....",
    ],
    "ui/icons/tab_inventory": [
        "................",
        "....kkkkkkkk....",
        "...kbbbbbbbbk...",
        "..kbBbbbbbbBbk..",
        "..kbBbbbbbbBbk..",
        ".kkkkkkkkkkkkkk.",
        ".kSbbbbkkbbbbSk.",
        ".kSbbbkyykbbbSk.",
        ".kSbbbkYYkbbbSk.",
        ".kSbbbbkkbbbbSk.",
        ".kSBBBBBBBBBBSk.",
        ".kSBBBBBBBBBBSk.",
        ".kkkkkkkkkkkkkk.",
    ],
    "ui/icons/tab_debug": [
        "................",
        "....k......k....",
        ".....k....k.....",
        "......kkkk......",
        ".....krrrrk.....",
        "..k.krrkkrrk.k..",
        "...kkrrkkrrkk...",
        "....krrkkrrk....",
        "..kkkrrkkrrkkk..",
        "....krrkkrrk....",
        "...kkrrkkrrkk...",
        "..k..krrrrk..k..",
        "......kkkk......",
    ],
    "ui/icons/tab_options": [
        "................",
        ".......kk.......",
        "....k.kggk.k....",
        "...kgkggggkgk...",
        "....kggggggk....",
        "..kkgggkkgggkk..",
        "..kgggk..kgggk..",
        "..kgggk..kgggk..",
        "..kkgggkkgggkk..",
        "....kggggggk....",
        "...kgkggggkgk...",
        "....k.kggk.k....",
        ".......kk.......",
    ],
    "ui/icons/tab_hall": [
        "................",
        "......kkkk......",
        "....kkrrrrkk....",
        "...krrrrrrrrk...",
        "..krrrrrrrrrrk..",
        ".kkkkkkkkkkkkkk.",
        "..kgggggggggggk.",
        "..kgkkgggggkkgk.",
        "..kgkykgggkykgk.",
        "..kgkkggkggkkgk.",
        "..kgggkkkkggggk.",
        "..kggkbbbbkgggk.",
        "..kggkbbbbkgggk.",
        "..kggkbbybkgggk.",
        "..kkkkkkkkkkkkk.",
    ],
    "ui/icons/move": [
        "................",
        ".......kk.......",
        "......kwwk......",
        ".....kwwwwk.....",
        "......kwwk......",
        "...k..kwwk..k...",
        "..kwkkkwwkkkwk..",
        ".kwwwwwwwwwwwwk.",
        ".kwwwwwwwwwwwwk.",
        "..kwkkkwwkkkwk..",
        "...k..kwwk..k...",
        "......kwwk......",
        ".....kwwwwk.....",
        "......kwwk......",
        ".......kk.......",
    ],
    "ui/icons/turn": [
        "................",
        ".....kkkkk......",
        "....kwwwwwk.....",
        "...kwkkkkkwk.k..",
        "..kwk.....kwkwk.",
        "..kwk......kwwk.",
        "..kwk.....kwwwk.",
        "..kwk....kkkkk..",
        "..kwk...........",
        "..kwk.......k...",
        "...kwk.....kwk..",
        "....kwkkkkkwk...",
        ".....kwwwwwk....",
        "......kkkkk.....",
    ],
    "ui/icons/destroy": [
        "................",
        ".kk.........kk..",
        "krrk.......krrk.",
        ".krrk.....krrk..",
        "..krrk...krrk...",
        "...krrk.krrk....",
        "....krrkrrk.....",
        ".....krrrk......",
        "....krrkrrk.....",
        "...krrk.krrk....",
        "..krrk...krrk...",
        ".krrk.....krrk..",
        "krrk.......krrk.",
        ".kk.........kk..",
    ],
    "items/barley_mash": [
        "................",
        "................",
        "................",
        "................",
        "....g.....g.....",
        ".....g...g......",
        "..kkkkkkkkkkkk..",
        ".kYyyYyyyyYyyYk.",
        ".kyyYyyyYyyyyyk.",
        "..koOooooooooOk.",
        "..koooooooooOOk.",
        "...koooooooOOk..",
        "....kOOOOOOOk...",
        ".....kkkkkkk....",
    ],
    "items/potato_mash": [
        "................",
        "................",
        "................",
        "................",
        "....g.....g.....",
        ".....g...g......",
        "..kkkkkkkkkkkk..",
        ".kpppPpppppPppk.",
        ".kPpppptppppppk.",
        "..koOooooooooOk.",
        "..koooooooooOOk.",
        "...koooooooOOk..",
        "....kOOOOOOOk...",
        ".....kkkkkkk....",
    ],
    "items/carrot": [
        "................",
        "..........e.e...",
        ".........eEeE...",
        "..........eEe...",
        ".........kkEk...",
        "........koook...",
        ".......koooOk...",
        "......kooOok....",
        ".....koooOk.....",
        "....kooOok......",
        "...koOook.......",
        "..kooOk.........",
        "..kOok..........",
        "...kk...........",
    ],
    "items/onion": [
        "................",
        ".......E........",
        "......kEk.......",
        "......kek.......",
        ".....kkekk......",
        "....kpppppk.....",
        "...kpwppppPk....",
        "..kpwpppppPPk...",
        "..kppppppppPk...",
        "..kppppppppPk...",
        "...kpppppPPk....",
        "....kPPPPPk.....",
        ".....kkkkk......",
        "......T.T.......",
    ],
    "items/roast_carrots": [
        "................",
        "................",
        "................",
        "................",
        ".....kk..kk.....",
        "....kook.kook...",
        "...koOk.koOk....",
        "..kkkkkkkkkkkk..",
        ".kwwwwwwwwwwwwk.",
        ".kwgooOwwoOgwwk.",
        "..kwwwwwwwwwwk..",
        "...kggggggggk...",
        "....kkkkkkkk....",
    ],
    "items/onion_soup": [
        "................",
        "................",
        ".....g...g......",
        "......g...g.....",
        ".....g...g......",
        "................",
        "..kkkkkkkkkkkk..",
        ".kyyywyyyyywyyk.",
        ".kyYyyyyyYyyyyk.",
        "..kgGggggggggk..",
        "..kgggggggggGk..",
        "...kgggggggGk...",
        "....kGGGGGGk....",
        ".....kkkkkk.....",
    ],
    "items/wheat": [
        "................",
        "...y......y.....",
        "..kyk....kyk....",
        "..kYyk..kyYk....",
        "..kyYk..kYyk....",
        "...kYk..kYk.....",
        "....kyk.kyk..y..",
        ".....kYkYk..kyk.",
        "......kyk..kyYk.",
        "......kYk.kYyk..",
        "......kykkYk....",
        "......kYkyk.....",
        "......kykk......",
        ".....kkkk.......",
    ],
    "items/radish": [
        "................",
        ".....kk..kk.....",
        "....keEkkeEk....",
        "....kEeEEeEk....",
        ".....kkEEkk.....",
        "......kEEk......",
        ".....krrrrk.....",
        "....krwrrrRk....",
        "....krrrrrRk....",
        "....krrrrRRk....",
        ".....krrRRk.....",
        "......kRRk......",
        ".......kk.......",
        ".......w........",
    ],
    "items/wheat_mash": [
        "................",
        "................",
        "................",
        "................",
        "....g.....g.....",
        ".....g...g......",
        "..kkkkkkkkkkkk..",
        ".kwyywyyywyywyk.",
        ".kyywyyywyyyywk.",
        "..koOooooooooOk.",
        "..koooooooooOOk.",
        "...koooooooOOk..",
        "....kOOOOOOOk...",
        ".....kkkkkkk....",
    ],
    "items/radish_mash": [
        "................",
        "................",
        "................",
        "................",
        "....g.....g.....",
        ".....g...g......",
        "..kkkkkkkkkkkk..",
        ".krrnrrrrrnrrrk.",
        ".krnrrrnrrrrnrk.",
        "..koOooooooooOk.",
        "..koooooooooOOk.",
        "...koooooooOOk..",
        "....kOOOOOOOk...",
        ".....kkkkkkk....",
    ],
    "items/wheat_beer": [
        "................",
        "................",
        "....wwwwwww.....",
        "...kwwwwwwwk....",
        "...kwwwwwwwkkk..",
        "...kyywyyyyk.k..",
        "...kyyyyyyyk.k..",
        "...kyyyywyyk.k..",
        "...kyyyyyyyk.k..",
        "...kyywyyyykkk..",
        "...kyyyyyyyk....",
        "...kYYYYYYYk....",
        "...kkkkkkkkk....",
    ],
    "items/radish_spirit": [
        "................",
        "................",
        "......kkkk......",
        "......kBBk......",
        "......kssk......",
        ".....kssssk.....",
        "....kssssssk....",
        "....ksrrrrsk....",
        "....ksrwrrsk....",
        "....ksrrrrsk....",
        "....ksrrrrsk....",
        "....ksssssskk...",
        ".....kkkkkk.....",
    ],
    "items/copper_ingot": [
        "................",
        "................",
        "................",
        "................",
        "......kkkkkkk...",
        ".....kwoooook...",
        "....kwoooooOk...",
        "...kkkkkkkkOk...",
        "...koooooooOk...",
        "...koooooooOk...",
        "...kOOOOOOOk....",
        "...kkkkkkkkk....",
    ],
    "items/copper_pick": [
        "................",
        "...kkkk.........",
        "..kooook........",
        ".kokkkkook......",
        ".kk..kbk.okk....",
        ".....kbk..kok...",
        ".....kbk...kk...",
        ".....kbk........",
        ".....kbk........",
        ".....kbk........",
        ".....kbk........",
        ".....kBk........",
        "......k.........",
    ],
    "items/copper_sickle": [
        "................",
        "......kkkk......",
        ".....koooOk.....",
        "....kokkkkOk....",
        "...kok....kOk...",
        "...kok.....kk...",
        "...kok..........",
        "....kok.........",
        ".....kokk.......",
        "......kkbk......",
        ".......kbk......",
        "........kbk.....",
        ".........kBk....",
        "..........k.....",
    ],
    "items/potato": [
        "................",
        "................",
        "................",
        ".....kkkkkk.....",
        "....kttttttk....",
        "...kttTtttttk...",
        "..kttttttTtttk..",
        "..ktttttttttTk..",
        "..kttTtttttttk..",
        "..kttttttTtttk..",
        "...kttttttttTk..",
        "...kTttTtttTk...",
        "....kTTTTTTk....",
        ".....kkkkkk.....",
    ],
    "items/barley": [
        "................",
        ".......k........",
        "......kyk.......",
        ".....kyYyk......",
        ".....kYyYk......",
        ".....kyYyk......",
        ".....kYyYk......",
        "......kyk.......",
        ".......kEk......",
        "......kEEk......",
        ".....kEkEk......",
        ".......kEk......",
        ".......kEk......",
        ".......kEk......",
        "........k.......",
    ],
    "items/stew": [
        "................",
        "................",
        ".....g...g......",
        "......g...g.....",
        ".....g...g......",
        "................",
        "..kkkkkkkkkkkk..",
        ".kBbbbtbbbobbBk.",
        ".kbbtbbbbbbtbbk.",
        "..kgGggggggggk..",
        "..kgggggggggGk..",
        "...kgggggggGk...",
        "....kGGGGGGk....",
        ".....kkkkkk.....",
    ],
    "items/gruel": [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "..kkkkkkkkkkkk..",
        ".kPppppppppppPk.",
        ".kpppPpppppPppk.",
        "..kgGggggggggk..",
        "..kgggggggggGk..",
        "...kgggggggGk...",
        "....kGGGGGGk....",
        ".....kkkkkk.....",
    ],
    "items/ale": [
        "................",
        "................",
        "....wwwwwww.....",
        "...kwwwwwwwk....",
        "...kyyyyyyykkk..",
        "...kyYyyyyyk.k..",
        "...kyyyyyyyk.k..",
        "...kyyyyYyyk.k..",
        "...kyyyyyyyk.k..",
        "...kyYyyyyykkk..",
        "...kyyyyyyyk....",
        "...kYYYYYYYk....",
        "...kkkkkkkkk....",
    ],
    "items/grog": [
        "................",
        "................",
        "................",
        "...kkkkkkkkk....",
        "...kbeeeeebkkk..",
        "...kbbbbbbbk.k..",
        "...kBbbbbbBk.k..",
        "...kbbbbbbbk.k..",
        "...kBbbbbbBk.k..",
        "...kbbbbbbbkkk..",
        "...kBbbbbbBk....",
        "...kBBBBBBBk....",
        "...kkkkkkkkk....",
    ],
    "items/cognac": [
        "................",
        ".......kk.......",
        "......kBBk......",
        "......kNNk......",
        "......kNNk......",
        ".....kNnnNk.....",
        "....kNnnnnNk....",
        "....kNnwnnNk....",
        "....kNnwnnNk....",
        "....kNnnnnNk....",
        "....kNnnnnNk....",
        "....kNnnnnNk....",
        "....kNNNNNNk....",
        ".....kkkkkk.....",
    ],
    "items/copper_ore": [
        "................",
        "................",
        ".....kkkkk......",
        "....kgGgggkk....",
        "...kgGoogGggk...",
        "..kgGoOGgggGk...",
        "..kgggGgggoGk...",
        "..kGgggggoOGk...",
        "..kgoogGgggGk...",
        "..kgOoGgggGGk...",
        "...kGGgggGGk....",
        "....kkkkkkk.....",
    ],
}
SMALL_ICONS = {
    "ui/icons/coin": [
        "..kkkk..",
        ".kyyyyk.",
        "kyywyyYk",
        "kywyyyYk",
        "kyyyyyYk",
        "kyyyyYYk",
        ".kYYYYk.",
        "..kkkk..",
    ],
    "ui/icons/camera": [
        "..........",
        "...kkk....",
        "kkkdddkkkk",
        "kgggggggwk",
        "kgggkkkggk",
        "kggkuuwkgk",
        "kggkuUukgk",
        "kgggkkkggk",
        "kggggggggk",
        "kkkkkkkkkk",
    ],
    "ui/icons/marker": [
        "kkkkkkk.",
        "kyyyyyk.",
        ".kyyyk..",
        "..kyk...",
        "...k....",
    ],
    "ui/icons/close": [
        "kk....kk",
        "krk..krk",
        ".krkkrk.",
        "..krrk..",
        "..krrk..",
        ".krkkrk.",
        "krk..krk",
        "kk....kk",
    ],
}


def outlined(glyph, fill, edge):
    """A font glyph's '#' cells in `fill`, with a one-pixel `edge` round it."""
    filled = {(x + 1, y + 1) for y, row in enumerate(glyph) for x, ch in enumerate(row) if ch == "#"}
    grid = []
    for y in range(len(glyph) + 2):
        row = ""
        for x in range(len(glyph[0]) + 2):
            if (x, y) in filled:
                row += fill
            elif any((x + dx, y + dy) in filled for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                row += edge
            else:
                row += "."
        grid.append(row)
    return grid


def icons():
    for name, grid in ICONS.items():
        save(draw(grid, size=(16, 16)), "assets/%s.png" % name)
    for name, grid in SMALL_ICONS.items():
        save(draw(grid), "assets/%s.png" % name)
    # The "?" over a dwarf with nothing to do is the font's own, outlined so
    # it reads on grass, dirt and floorboards alike.
    save(draw(outlined(GLYPHS["?"], "w", "k")), "assets/ui/icons/idle.png")
    # The Ores tab shows the ore itself.
    save(draw(ICONS["items/copper_ore"], size=(16, 16)), "assets/ui/icons/tab_ores.png")


# --- Font -------------------------------------------------------------------------
# 5x7 capitals. Lower case letters draw as capitals.
GLYPHS = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
    ".": [".....", ".....", ".....", ".....", ".....", ".....", "..#.."],
    ",": [".....", ".....", ".....", ".....", ".....", "..#..", ".#..."],
    ":": [".....", "..#..", ".....", ".....", ".....", "..#..", "....."],
    "!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
    "?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
    "-": [".....", ".....", ".....", ".###.", ".....", ".....", "....."],
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    "=": [".....", ".....", "#####", ".....", "#####", ".....", "....."],
    "(": ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#."],
    ")": [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#..."],
    "/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
    "%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
    "'": ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."],
    "<": ["...#.", "..#..", ".#...", "#....", ".#...", "..#..", "...#."],
    ">": [".#...", "..#..", "...#.", "....#", "...#.", "..#..", ".#..."],
    "_": [".....", ".....", ".....", ".....", ".....", ".....", "#####"],
}
GLYPH_W, GLYPH_H, ADVANCE, LINE_HEIGHT, COLUMNS = 5, 7, 6, 9, 16


def font():
    names = sorted(GLYPHS)
    rows = (len(names) + COLUMNS - 1) // COLUMNS
    atlas = Image.new("RGBA", (COLUMNS * (GLYPH_W + 1), rows * (GLYPH_H + 1)), (0, 0, 0, 0))
    places = {}
    for i, ch in enumerate(names):
        x, y = (i % COLUMNS) * (GLYPH_W + 1), (i // COLUMNS) * (GLYPH_H + 1)
        places[ch] = (x, y)
        for gy, row in enumerate(GLYPHS[ch]):
            for gx, px in enumerate(row):
                if px == "#":
                    atlas.putpixel((x + gx, y + gy), (255, 255, 255, 255))
    save(atlas, "assets/fonts/dwarf_5x7.png")

    chars = ['char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=4 page=0 chnl=15']
    for ch in names:
        x, y = places[ch]
        codes = [ord(ch)] + ([ord(ch.lower())] if ch.isalpha() else [])
        for code in codes:
            chars.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=1 xadvance=%d page=0 chnl=15"
                         % (code, x, y, GLYPH_W, GLYPH_H, ADVANCE))
    text = "\n".join([
        'info face="Dwarf5x7" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 '
        'padding=0,0,0,0 spacing=1,1' % LINE_HEIGHT,
        "common lineHeight=%d base=8 scaleW=%d scaleH=%d pages=1 packed=0" % (LINE_HEIGHT, atlas.width, atlas.height),
        'page id=0 file="dwarf_5x7.png"',
        "chars count=%d" % len(chars),
    ] + chars) + "\n"
    with open(os.path.join(ROOT, "assets/fonts/dwarf_5x7.fnt"), "w", newline="\n") as f:
        f.write(text)


if __name__ == "__main__":
    frames()
    icons()
    font()
    print("art written")
