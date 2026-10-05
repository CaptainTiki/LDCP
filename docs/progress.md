# LDCP progress

Where the project stands, what's next, and how to pick it back up. Last updated during the session of 2026-10-05 (version `proto-0.10.5.30`).

## Where we are

The first playable slice is done and has grown well past the original handoff. "A little of everything" now runs end to end:

`farm -> cook / brew -> feed dwarves -> mine -> smelt -> forge tools -> faster dwarves`, with unlocks gating the way.

The guiding rule for design: **emulate Rusty's Retirement first; propose before inventing new gameplay.** Content is scoped to the early game (roughly the first 20-30 minutes) until the systems around it exist.

### Systems in the game

- **Views.** Top-down town, side-on mine, top-down building interiors. Separate camera views joined by doors; no scrolling between them.
- **Window.** 450px strip at the bottom of the screen at an exact 3x pixel scale (640x150 canvas). F10 toggles a normal window.
- **Farming.**
  - Farm plots are 1-tile buildings, bought, moved and destroyed in the Build tab.
  - The player sows (1 coin per seed); farmers water, harvest and haul, but never sow.
  - Player tools: Hoe (roots up a plant), Look, Bucket, Shears. Harvests go into the player's hands and are dropped off at the Great Hall.
- **Needs.**
  - Food is shift length; drink is work rate (50% floor). Both drain only while working.
  - Dwarves eat sitting in a chair, and wait for a free one if all are taken.
- **Idling.** A dwarf whose job has nothing at all for him potters about near his workplace with a "?" over his head: by the mine entrance, inside his kitchen or brewery, among the plots, or outside the Great Hall with no job. His card says why: no job, nothing sown, no recipe set, missing ingredients, no tunnel to dig. Waiting that sorts itself out (crops growing, a stove cooking) isn't idling.
- **Great Hall.** Furniture (chair, table, long table): placed, moved, turned and removed on a floor grid. Placement can never wall off the room. The game starts with 4 dwarves, 2 tables and 4 chairs, a 3x3 block of 9 farm plots, and 10 gruel and 10 grog.
- **Stations.**
  - Stove, mash pot, fermenter, smelter and anvil are furniture that makes things.
  - Pick a recipe, fill the loading bar (player clicks or a dwarf), then the station runs on a timer.
  - Ingredients leave storage only when the bar fills.
  - A station is worked from its front cell, which turns with it.
- **Brewing.** Mash pot -> fermenter. The player pours by clicking an empty fermenter, then a finished pot. Brewers move mash themselves. One mash makes several drinks.
- **Recipes.** Up to two ingredients. Dwarves carry one tool and one item type at a time, so two ingredients means two trips.
- **Mining.**
  - The copper layer starts right under the grass: about 6 rows of dirt with a ragged edge, stone below.
  - The shaft starts short, landing in the dirt beside the first copper deposit.
  - Miners tunnel on their own (slopes, planks, forks; can never trap a dwarf), reveal hand-placed copper nodes, and haul ore up the ladder.
  - One miner per tunnel end. A miner with no free end opens a new tunnel off the side of the shaft, or digs the shaft deeper until there's room for one.
  - The lift makes the climb fast (meant to become a later-game upgrade).
- **Metal.** Smelter (3 ore -> 1 ingot); anvil (2 ingots -> copper pick or copper sickle).
- **Tools.** A pick or sickle makes its job 1.5x faster. Dwarves upgrade at the hall. A reassigned dwarf with the wrong tool goes to swap it before doing anything else.
- **Unlocks.**
  - A lifetime Ledger counts everything harvested, made and mined.
  - Each unlock is a milestone (any Ledger counter), then a trade (coins early; ore and ingots later).
  - Locked squares show their progress, then an offer.
- **UI.**
  - Rusty's-style side panel: tabs for Farm, Ores, Build, Shop, Debug and Options. Inside a building, a room tab replaces them.
  - Left roster of dwarves. Hovering one shows a card and an arrow over him; clicking jumps the camera to him; the camera toggle makes it follow him.
  - Top bar: coins and food/drink chips, plus a status line.
- **Art.** Generated placeholder pixel art for everything, with a 5x7 pixel font.
- **Game log.** Each session writes `user://logs/game_<date>_<time>.log`: the tuning in play, events as they happen, a summary each game minute (including where each dwarf's time went) and totals. See DECISIONS.md.

### Content (all numbers are placeholders)

| Crops | Unlock |
|---|---|
| Potato, Barley | start |
| Carrot | harvest 20 crops, 15 coins |
| Onion | cook 15 meals, 30 coins |
| Radish | harvest 40 crops, 25 coins |
| Wheat | make 10 drinks, 40 coins |

- **Meals:** gruel (1 potato), roast carrots (2 carrots), stew (2 potatoes), onion soup (1 onion + 2 potatoes).
- **Drinks:** grog (potato mash), ale (barley mash), wheat beer (wheat mash; long and steady), radish spirit (radish mash; short and sharp).
- **Buildings:**
  - Great Hall and mine entrance: placed at start.
  - Kitchen: no unlock.
  - Brewery: harvest 20 barley, then 60 coins.
  - Smeltery: mine 15 ore, then 80 coins + 5 ore.
  - Forge: smelt 5 ingots, then 50 coins + 3 ingots.

## Next up

1. **Test runs.** Play the opening from a new game and tune pacing: grow times, cook and brew times, unlock milestones, prices, ladder speed. The first run (2026-10-05) halved crop growth, doubled food and drink, and grew the starting farm and pantry; see DECISIONS.md "First playtest".
   - Next: a second long run on the new numbers. Cooks keep one trip per ingredient by design; tune ingredients per recipe, cook and load times, meal length and eating pace together from the log. Parked ideas: recipes that make several servings, and food-quality moods that slow work.
2. **Recipes again.**
   - Wheat and radish have no meals yet.
   - Bread would want an oven station.
   - A third and fourth early meal could vary cook time vs. shift length further.
3. **Deeper mine**, later: the lift as a later-game upgrade; iron, gold and platinum layers, each its own ant-farm level, reached through a door at the bottom of the level above's ladder.
4. **Metal follow-ups**, when ready:
   - Smelting fuel (coal or charcoal).
   - Tools wearing out.
   - Tools for cooks.
   - Later trades priced in ingots.

### Known gaps and loose ends

- `docs/GDD.md` still describes the original side-view town and needs updating to match what's built.
- **Mine:**
  - Once the copper layer has no room left for a tunnel, spare miners sit in the hall ("No tunnel to dig").
  - Miners prefer found ore nodes to digging, so digging stalls once there's a node per miner.
  - There are no gems, and no wider tunnel pockets.
- **Town:** nothing stops the player fencing off part of the town with a wall of buildings.
- **Stations:** non-square stations would need rotation-aware click areas (all stations are 2x2 today).
- **Interface:**
  - No mood system yet; the dwarf card shows work rate in its place.
  - The follow camera overrides panning and the view buttons while it's on.
- **Not started:** save/load, offline progress, audio, real art, settings beyond the window toggle.
- **Idle CPU** hasn't been measured; the game is capped at 30 FPS in low-processor mode.

## Working notes

- **Commits:**
  - The message is a short name only; no body.
  - Every commit bumps `config/version` in `project.godot`.
  - Format: `proto-major.month.day.build`. The build number counts up and resets to 1 when a new month starts.
- **Tests:**
  - GUT, in `.tests/`. Run `.tools/run_tests.ps1`, or with Godot headless: `-s addons/gut/gut_cmdln.gd -gdir=res://.tests/unit,res://.tests/integration -gexit`.
  - 75 tests, all passing.
- **Generators** (in `.tools/`):
  - Most `.tscn` and `.tres` files are written by `.tools/gen/gen_data.py`, `gen_scenes.py` and `gen_ui.py`. Edit there and re-run, or edit a scene in Godot and stop regenerating it.
  - Art comes from `.tools/art/make_ui_art.py` and `make_world_art.py` (they need Pillow: `python -m pip install pillow` on a new machine). Any PNG in `assets/` can be replaced by hand.
- **Godot path:** `.tools/run_tests.ps1` defaults to a `D:` Steam install. On the other desktop Godot is at `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\`; pass `-Godot` or set `GODOT`.
- **Game log:** on Windows the logs are in `%APPDATA%\Godot\app_userdata\LDCP\logs\` (beside Godot's own `godot.log`).
- **Screenshots:** `.tools/screenshots.gd` captures town, mine, hall, kitchen and brewery views. Run Godot with `-s .tools/screenshots.gd -- <folder>`.
- **Decision log:** `.tools/DECISIONS.md` has the reasoning behind every call made so far.
- `.tests/` and `.tools/` are tracked in git, so they travel with the repo. `addons/gut/` is not: install GUT 9.7.1 on a new machine. See `CLAUDE.md`.
