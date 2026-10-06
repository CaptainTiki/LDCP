# LDCP progress

Where the project stands, what's next, and how to pick it back up. Last updated at the end of the session of 2026-10-06 (version `proto-0.10.6.42`).

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
  - Crops are slow: 6.5 to 17 minutes of watered growth (a potato takes 10), 2 waterings each, and a harvest of 2. Dry soil pauses growth. Two plots of potatoes feed about one dwarf (`.tools/food_chain.gd`).
  - Each plant's grow time is ±10% and each watering's length ±20%, so a field ripens and dries unevenly. One farmer keeps up with 27 plots, and a sowing of 27 lasts about 10 minutes.
  - Player tools: Hoe (roots up a plant), Bucket, Shears. Harvests go into the player's hands and are dropped off at the Great Hall.
- **Needs.**
  - Food is shift length and runs down all the time; drink is work rate (50% floor) and only drains while working.
  - Dwarves eat sitting in a chair, and wait for a free one if all are taken.
- **Idling.** A dwarf whose job has nothing at all for him potters about near his workplace with a "?" over his head: by the mine entrance, inside his kitchen or brewery, among the plots, or outside the Great Hall with no job. His card says why: no job, nothing sown, no recipe set, missing ingredients, no tunnel to dig. Waiting that sorts itself out (crops growing, a stove cooking) isn't idling.
- **Great Hall.** Furniture (chair, table, long table): placed, moved, turned and removed on a floor grid. Placement can never wall off the room. The game starts with 4 dwarves, 2 tables and 4 chairs, a 3x3 block of 9 farm plots, and 40 gruel and 10 grog.
- **Stations.**
  - Stove, mash pot, fermenter, smelter and anvil are furniture that makes things.
  - A station rests with no recipe. A worker picks the best-quality thing he can make from the hall (each meal, drink and mash has a quality number), brings the ingredients, sets the recipe and loads it; then it runs on a timer. A tool is only forged while a dwarf in its job lacks one.
  - The player's pick in the room tab is their own: clicking the free station starts a batch of it. "Cancel batch" stops one and puts what went in back in the hall.
  - For the player, ingredients leave storage only when the bar fills.
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
- **Market.** A building with a stall. Its room tab lists every item that sells, by category, with a keep number (everything is kept until the player sets one). A trader carries anything above a keep number to the stall and sells it, a load at a time, for passive income.
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
| Carrot | harvest 15 crops, 15 coins |
| Onion | cook 15 meals, 30 coins |
| Barley | make 4 drinks, 20 coins |
| Wheat | make 10 drinks, 40 coins |
| Radish | make 20 drinks, 50 coins |

Brewing crops (barley, wheat, radish) only unlock once the brewery is making drinks, so nothing is grown before it can be used.

- **Meals,** worst to best: gruel (1 of any crop), potato soup (2 potatoes), roast carrots (4 carrots), stew (4 potatoes), onion soup (2 onions + 4 potatoes). Each is more food per crop than the one before.
- **Drinks:** grog (rough mash: any 2 crops), ale (barley mash), wheat beer (wheat mash; long and steady), radish spirit (radish mash; short and sharp).
- **Buildings:**
  - Great Hall and mine entrance: placed at start.
  - Kitchen: no unlock.
  - Brewery: cook 10 meals, then 60 coins.
  - Smeltery: mine 15 ore, then 80 coins + 5 ore.
  - Forge: smelt 5 ingots, then 50 coins + 3 ingots.
  - Market: sell 30 items by hand, then 30 coins.

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

## Playtest (2026-10-06)

`game_2026-10-06_09-19-59`: 74 minutes, played, on `proto-0.10.5.34` (before the watering change and the HUD refactor). Got through every building: kitchen, smeltery (15:34), brewery (35:17), forge (50:33). 486 crops harvested, 73 meals, 88 drinks, 277 ore. Visits at minutes 1, 8-10, 16-17, 36-37, 41-43, 47-51 and 62.

What the log showed:
- **Watering:** one farmer couldn't keep 18-27 plots watered; plots were dry about as often as growing. Fixed the same morning (2 waterings per crop, ±10% growth, ±20% per watering).
- **HUD:** the top bar grew until it pushed the roster and side panel off screen. Fixed the same morning (HUD refactor).
- **Dwarves were thirsty 63% of the time** (244 of 387 dwarf-minutes at the 50% floor), even with 47-69 grog in the hall. They only drink when they come in to eat, and a meal lasts much longer than a drink: stew 600s of work, grog 180s.
- **The farm sat empty 55% of the game.** The farmer was idle with "Nothing sown" for 15 minutes; the 19-minute gap between visits (17 to 36) left all 27 plots empty for about 10 minutes. The watering change makes sowings shorter still (27 plots: about 10 minutes, was 20).
- **Potatoes were the bottleneck, while carrots and onions piled up.** Gruel, stew, onion soup and potato mash all need potatoes; carrots only make roast carrots. After the first two potato sowings the player sowed 35 carrots and 18 onions, and no more potatoes. For the last 10 minutes two stoves and a mash pot had "no ingredients", with 132 carrots and 104 onions in the hall.
- **Much more food made than eaten:** 73 meals made, 18 eaten; 88 drinks made, 17 drunk. Hunger only drains while working, and station workers spent 30-60% of their time hauling, so they ate about one meal in 40 minutes.
- **Coins only came from selling during visits,** and sat at 0 from minute 62 on despite the hall's stock. The brewery's milestone came at 16:46, but the coins for it came at the next visit, at 34:41.
- **Mining:** only 1 of 3 deposits found in 74 minutes (the known gap: miners prefer found nodes to digging).
- **Hauling:** the smeltery and brewery workers hauled 43-49% of the time, and the smeltery's 3 smelters each stood unattended 15-25% of the time.
- The forge's smith waited 62% of his time while the anvil ran its 90s timer. Expected with one anvil; not a bug.

## Playtest (2026-10-06, afternoon)

`game_2026-10-06_13-49-55`: 72 minutes, played, on `proto-0.10.6.40` (stations running themselves, food all the time, harvests of 2, the market). The pacing felt good until the player moved on to carrots, onions and wheat and stopped sowing potatoes:
- Every meal and the brewery's mash needed potatoes. The cook was idle ("Missing ingredients") 38 of 72 minutes, and 164 crops made only 29 meals.
- The pantry ran out of meals twice (52:16, 56:30). The player bought gruel twice, and even after resowing, potatoes took too long to come back.
- The trader had nothing to sell for 29 minutes; there was never a surplus.
- The smelters stood unattended 66-75% of the time with one worker for three.

Changed in response: gruel takes 1 of any crop and grog comes from a rough mash of any 2, so the kitchen only stops when the hall has no crops at all. Potato soup (2 potatoes) sits just above gruel. Better meals give more food per crop. See DECISIONS.md "Cooking from whatever's on hand".

## Next up

1. **Waiting on the user's call:**
   - **Drinks between meals.** Dwarves only drink when they come in to eat. Thirsty (at the 50% floor) 63% of the time in the morning playtest; 28% in the afternoon one, now that food runs down all the time and they eat more often. Options: come in for a drink when it runs out; drinks last as long as meals; carry one along.
   - **One worker for three smelters.** In the afternoon playtest each smelter stood unattended 66-75% of the time: the smeltery worker spends most of his time hauling. More workers per building, or less hauling (a bigger load of ore, output that waits for a full trip)?
   - **Mine controls and finds** (proposal). A Mine tab while in the mine view: one row per found deposit with − N + miners (0 leaves it alone; the rest dig), and a "dig the shaft down" switch that runs the ladder to the bottom of the layer. Random finds while digging (copper chunks, rarer in dirt than stone) so mining out the whole layer pays. Questions: − N + per deposit or on/off per ore type; which finds first; how long digging out the copper layer should take with ~4 miners (about 2 hours at today's numbers). Only 1 of 3 deposits was found in either of today's playtests.
   - Later: fertilizer as an endgame upgrade, for more food from fewer plots (user's idea).
   - Later: meals that give bonuses (move speed and the like), so better food is worth more than its length (user's idea).
2. **A long test run** on `proto-0.10.6.41` (cooking from whatever's on hand), reading the log. Watch:
   - running out of food: 9 plots feed about 4 dwarves. Gruel from any crop should make the stall rare; when it does come, everyone waits in the hall until the player buys gruel or works by hand (the user's call to keep that stall);
   - whether the kitchen eats the brewery's barley, wheat and radish as gruel or rough mash;
   - whether 40 starting gruel lasts until the first cooked meal (the first potatoes come in around minute 10);
   - when the brewery (cook 10 meals) and onions (15 meals) unlock;
   - whether the market's passive income keeps unlocks moving between visits;
   - stations' "unattended" vs "no ingredients" shares.

   `.tools/food_chain.gd` re-checks the food math after any tuning change: about 2.1 plots of potatoes per dwarf today.
3. **Recipes again.**
   - Wheat and radish only make gruel and their drinks.
   - Bread would want an oven station.
   - Onion soup still needs potatoes as well as onions.
4. **Deeper mine**, later: the lift as a later-game upgrade; iron, gold and platinum layers, each its own ant-farm level, reached through a door at the bottom of the level above's ladder.
5. **Metal follow-ups**, when ready:
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
  - 96 tests, all passing.
- **Generators** (in `.tools/`):
  - Most `.tscn` and `.tres` files are written by `.tools/gen/gen_data.py`, `gen_scenes.py` and `gen_ui.py`. Edit there and re-run, or edit a scene in Godot and stop regenerating it.
  - Art comes from `.tools/art/make_ui_art.py` and `make_world_art.py` (they need Pillow: `python -m pip install pillow` on a new machine). Any PNG in `assets/` can be replaced by hand.
- **Godot path:** `.tools/run_tests.ps1` defaults to a `D:` Steam install. On the other desktop Godot is at `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\`; pass `-Godot` or set `GODOT`.
- **After pulling on the other machine,** run Godot once with `--headless --import` before the tests. Scripts with a new `class_name` aren't in that machine's class cache until then, and most tests fail with errors like "Could not find type LogWatcher".
- **Game log:** on Windows the logs are in `%APPDATA%\Godot\app_userdata\LDCP\logs\` (beside Godot's own `godot.log`). Logs worth keeping are copied into `.logs/` in the repo at the end of a session, so they travel to the other machine.
- **Screenshots:** `.tools/screenshots.gd` captures town, mine, hall, kitchen and brewery views. Run Godot with `-s .tools/screenshots.gd -- <folder>`.
- **Food chain:** `.tools/food_chain.gd` plays a steady player headless for 90 game minutes (or `-- <minutes>`) and prints how many dwarves a plot and a stove feed. Run Godot with `--headless -s .tools/food_chain.gd`.
- **Decision log:** `.tools/DECISIONS.md` has the reasoning behind every call made so far.
- `.tests/`, `.tools/` and `.logs/` are tracked in git, so they travel with the repo. `addons/gut/` is not: install GUT 9.7.1 on a new machine. See `CLAUDE.md`.
