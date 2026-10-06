# LDCP progress

Where the project stands, what's next, and how to pick it back up. Last updated at the end of the session of 2026-10-05 (version `proto-0.10.5.34`).

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
  - Crops are slow and big: 3 to 7.5 minutes of watered growth for 6 crops, and 2 waterings each. Dry soil pauses growth.
  - Each plant's grow time is ±10% and each watering's length ±20%, so a field ripens and dries unevenly. One farmer keeps up with 27 plots, and a sowing of 27 lasts about 10 minutes.
  - Player tools: Hoe (roots up a plant), Bucket, Shears. Harvests go into the player's hands and are dropped off at the Great Hall.
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
  - Rusty's-style side panel: tabs for Farm, Build, Ores, Inventory, Shop, Debug and Options, zigzagging down two staggered columns. Inside a building, a room tab replaces them.
  - Inventory tab: everything in the Great Hall with counts and prices; pick one to sell one or all.
  - Left roster of dwarves. Hovering one shows a card and an arrow over him; clicking jumps the camera to him; the camera toggle makes it follow him.
  - Top bar: coins, plants growing, idle dwarves; the Look button (magnifying glass); the view buttons. It never grows, so the panels stay on screen.
  - Look: with the glass in hand, hovering a station, plot, building or deposit pops up what it's up to. Any click puts it away. The same pop-up reminds the player where crops in hand go and how to finish a pour.
- **Art.** Generated placeholder pixel art for everything, with a 5x7 pixel font.
- **Game log.** Each session writes `user://logs/game_<date>_<time>.log`: the tuning in play, events as they happen, a summary each game minute (including where each dwarf's time went) and totals. See DECISIONS.md.

### Content (all numbers are placeholders)

| Crops | Unlock |
|---|---|
| Potato | start |
| Carrot | harvest 20 crops, 15 coins |
| Onion | cook 15 meals, 30 coins |
| Barley | make 4 drinks, 20 coins |
| Wheat | make 10 drinks, 40 coins |
| Radish | make 20 drinks, 50 coins |

Brewing crops (barley, wheat, radish) only unlock once the brewery is making drinks, so nothing is grown before it can be used.

- **Meals:** gruel (1 potato), roast carrots (2 carrots), stew (2 potatoes), onion soup (1 onion + 2 potatoes).
- **Drinks:** grog (potato mash), ale (barley mash), wheat beer (wheat mash; long and steady), radish spirit (radish mash; short and sharp).
- **Buildings:**
  - Great Hall and mine entrance: placed at start.
  - Kitchen: no unlock.
  - Brewery: cook 10 meals, then 60 coins.
  - Smeltery: mine 15 ore, then 80 coins + 5 ore.
  - Forge: smelt 5 ingots, then 50 coins + 3 ingots.

## Playtests (2026-10-05)

Five runs, read back from the game log. The logs are kept in `.logs/` in the repo; DECISIONS.md has a section on each with the changes it led to.

| Log | Length | How it was played | What it showed |
|---|---|---|---|
| `game_2026-10-05_10-43-29` | 12 min | played | Sowing was a treadmill (crops grew in 30-60s, ~20 sows a minute for 18 plots); food ran out at 5:46; one cook couldn't keep up; a cook with no recipe walked off to the hall, so assigning looked broken; dwarves couldn't be dropped inside a building. |
| `game_2026-10-05_11-36-53` | 44 min | left alone | Farm empty 94% of the game ("Nothing sown"); the starting food ran out and miners waited half the game for more. |
| `game_2026-10-05_12-20-32` | 46 min | mostly left alone | Food length now right (a miner eats gruel every ~5 min); the kitchen never cooked because recipes couldn't be picked before the ingredients existed; tunnels ran dead straight (a slope bug). |
| `game_2026-10-05_14-02-10` | 80 min | left alone after minute 1 | No cook was assigned, so nothing was cooked; miners waited for food ~70% of the game. |
| `game_2026-10-05_15-22-37` | 32 min | played | Visits every 7-10 min, but each sowing kept the farm busy only 3-6 min, so the town spent most of its time waiting on the player (plots empty 49%); drinks ran out at 14:36 with no way to brew (the brewery needed barley nobody grew); stew lasted ~8.5 min a meal; 33 meals; smeltery running from 16:28. |

Changed in response: crops grow half as fast, food and drink last twice as long, 10 gruel and 10 grog and a 3x3 farm to start, right-click puts tools away, dwarves can be dropped anywhere inside a workplace, idle dwarves wait by their workplace with a "?", recipes can be picked before their ingredients exist (the station says what it's waiting for), the stuck-slope tunnelling bug is fixed and tunnels wander more, and the brewery unlocks by cooking 10 meals.

**The main lesson:** the town stalls whenever the player is away. Nearly every stall traces back to sowing (only the player sows, and a sowing lasts a few minutes) or to an empty pantry.

A review of the logs afterwards found:
- The farmer is the real limit on the farm: dry soil pauses growth, and planted plots were dry more of the time than growing.
- Barley and radish were grown with no use for them.
- The log's "loading" hid both a stove with no ingredients and one with no cook.

Changed in response: crops grow 3x as long for 3x the yield, so a sowing lasts about 2.5x longer; dwarves carry 6; barley, wheat and radish unlock from drinks made; and the log splits a station's waiting into loading, unattended and no ingredients. See DECISIONS.md "Slow crops, brewing crops after the brewery, station waits in the log".

## Next up

1. **Waiting on the user's call:**
   - **Replanting as a later unlock** (say a seed shed around minute 15-20). As Claude remembers it, Rusty's bots replant whatever crop a plot is set to, so "only the player sows" may already differ from Rusty's. A Rusty's screenshot would settle it.
   - **Mine controls and finds** (proposal). A Mine tab while in the mine view: one row per found deposit with − N + miners (0 leaves it alone; the rest dig), and a "dig the shaft down" switch that runs the ladder to the bottom of the layer. Random finds while digging (copper chunks, rarer in dirt than stone) so mining out the whole layer pays. Questions: − N + per deposit or on/off per ore type; which finds first; how long digging out the copper layer should take with ~4 miners (about 2 hours at today's numbers).
2. **More test runs** on the new numbers, reading the logs. Watch:
   - whether a sowing now outlasts the gap between visits;
   - whether the first harvest (now about 5-6 minutes in) comes before the starting gruel runs out;
   - stations' "unattended" vs "no ingredients" shares;
   - the smelter: its worker waited 59% of the time in the third playtest while ore piled up to about 50.

   Also: Cooks keep one trip per ingredient by design; tune ingredients per recipe, cook and load times, meal length and eating pace together. Parked ideas: recipes that make several servings, and food-quality moods that slow work.
3. **Recipes again.**
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
  - Once the copper layer has no room left for a tunnel, spare miners wait by the mine entrance ("No tunnel to dig").
  - Miners prefer found ore nodes to digging and nodes never run out, so digging stops once there's a node per miner (with 3 miners, by about minute 10).
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
  - 87 tests, all passing.
- **Generators** (in `.tools/`):
  - Most `.tscn` and `.tres` files are written by `.tools/gen/gen_data.py`, `gen_scenes.py` and `gen_ui.py`. Edit there and re-run, or edit a scene in Godot and stop regenerating it.
  - Art comes from `.tools/art/make_ui_art.py` and `make_world_art.py` (they need Pillow: `python -m pip install pillow` on a new machine). Any PNG in `assets/` can be replaced by hand.
- **Godot path:** `.tools/run_tests.ps1` defaults to a `D:` Steam install. On the other desktop Godot is at `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\`; pass `-Godot` or set `GODOT`.
- **After pulling on the other machine,** run Godot once with `--headless --import` before the tests. Scripts with a new `class_name` aren't in that machine's class cache until then, and most tests fail with errors like "Could not find type LogWatcher".
- **Game log:** on Windows the logs are in `%APPDATA%\Godot\app_userdata\LDCP\logs\` (beside Godot's own `godot.log`). Logs worth keeping are copied into `.logs/` in the repo at the end of a session, so they travel to the other machine.
- **Screenshots:** `.tools/screenshots.gd` captures town, mine, hall, kitchen and brewery views. Run Godot with `-s .tools/screenshots.gd -- <folder>`.
- **Decision log:** `.tools/DECISIONS.md` has the reasoning behind every call made so far.
- `.tests/`, `.tools/` and `.logs/` are tracked in git, so they travel with the repo. `addons/gut/` is not: install GUT 9.7.1 on a new machine. See `CLAUDE.md`.
