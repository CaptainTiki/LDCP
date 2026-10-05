# Decisions log

Calls made while building, and why. Newest at the bottom.

## Handoff 01: first slice

**Dev folders.** The handoff says `.dev/`. The repo already had `.tests/` and `.tools/`, so those are used instead: tests in `.tests/`, tooling and this file in `.tools/`. Both are git-ignored, as the GDD asks for the dev dot-folder. GUT stays in `addons/gut` (it has to, to work as an editor plugin) and runs tests from `.tests/` without trouble via `.tools/run_tests.ps1`.

**Folder layout.** By feature, each owning its components: `actors/dwarf/{components,roles}`, `entities/{components,buildings,farm_plot,workstations,ore_node}`, `world/{nav,surface,mine}`, `economy/`, `game/`, `ui/`, and `data/` (`defs/` holds the Resource scripts, the rest is `.tres` content).

**Scale.** Calibrated against a Rusty's Retirement screenshot at 1080p: the strip is 450 screen px tall (`GameWindow.strip_height`), which stretches the 300px-tall viewport 1.5x, so the world's 2x camera zoom lands at Rusty's 3x pixel scale and the roster comes out about 130px wide with dwarves two across. The pool holds 16 dwarves to match a 2x8 roster. Viewport is 1280x300 with `canvas_items` + `expand`, so the strip height drives UI scale and extra screen width just shows more world. The world camera is zoomed 2x. Nav/mine cell is 8px (`NavGrid.CELL`), a surface slot is 32px (`Placeable.SLOT_PIXELS`). These two are constants rather than tuning values because authored scene positions depend on them.

**One nav grid, registered by owners.** `NavGrid` is just a set of standable cells plus door portals. The surface registers its ground row, the shaft its ladder cells, the terrain its tunnels, interiors their floors. Pathfinding is a plain breadth-first search. Interiors live at y = -2400 and connect by portal, so "walk into a building" is ordinary pathfinding.

**Roles instead of a task queue.** Each job is a small node (`FarmerRole`, `StationWorkerRole`, `MinerRole`, `IdleRole`, `MealBreak`) that re-decides every tick what it should be doing. They keep almost no state, so moving or destroying things mid-task needs no special handling.

**Player clicks bypass carrying.** Hand-harvested crops, hand-chipped ore and hand-loaded stoves move items straight to or from the Great Hall. The player has no back to carry things on, and the kick-start has to work when no dwarf is free.

**Farm plots are fixed-crop.** "Potato Plot" and "Barley Plot" are separate build options (one scene each, inheriting `farm_plot.tscn`). Simpler than a seed-picking UI for now. Farmers tend every plot in town, whichever plot they were dropped on.

**Footprints.** Read as width x height in slots. Only the width reserves slots. Kitchen and brewery are 2x1, hall 2x2, plots and the mine entrance 1x1.

**Defs don't point back at themselves.** A `BuildingDef` references its scene, so the scene must not reference the def (cyclic load). The `Surface` assigns `def` when it places something, and pre-placed buildings get it set on their instance in `world.tscn`.

**Excavation.** Tunnels grow from "heads", one two-tall column at a time: mostly flat, sometimes a short slope, sometimes a fork into an upper and lower branch joined by a plank. Safety rule: a column is only dug if the cells directly above and below it are solid, and planned columns are reserved so two heads can't undermine each other. `test_excavation.gd` digs six stress-seeded networks and checks nothing is ever stranded. Tunnels never merge and there are no mid-tunnel side branches, so a level can eventually run out of heads. Miners then wait at the landing. Good enough for the slice.

**Ore nodes.** 2x2 cells, solid, never dug through. Revealed when a dug cell comes within 2 cells, worked from the nearest standable cell within 3. The first copper node sits 6 columns from the landing on the same row, and new tunnels run straight for 6 columns, so the first find is guaranteed and quick. Nodes don't deplete. Gems skipped (optional).

**Lift.** Buying it re-flags the shaft's ladder cells as lift cells, which move at `lift_speed` instead of `ladder_speed`. A little platform shows under a riding dwarf. No separate lift car entity or queueing.

**Hunger and thirst only drain while working** (changed 2026-10-04, see the end of this file). Dwarves eat the longest-lasting meal and drink the strongest drink in stock.

**Selling** is "1" or "All" per item. Hire price grows by a flat amount per extra dwarf. 

**Views.** Surface and Mine are two camera framings. The camera also pans freely (right/middle drag, wheel, arrow keys) so the shaft climb can be watched. "Located Here" uses surface = above ground, mine = below, interior = that room.

**Window.** `GameWindow` makes the borderless always-on-top strip at runtime. F10 toggles a normal window. If the editor embeds the game window, turn embedding off to see the strip. FPS capped at 30 with low-processor mode on.

**UI lists** (build, shop, roster) are made by instancing small authored scenes per catalog entry (`catalog_button.tscn`, `sell_row.tscn`, `roster_entry.tscn`). No autoloads anywhere.

**Scenes were written as text,** not saved from the editor, so the first editor save will add UIDs and reorder some lines. Harmless.

**Not done yet from the handoff:** fade/zoom view transitions, gems, wider tunnel pockets. No measured CPU figure yet either, only the FPS cap and low-processor mode.

## Top-down town (design change, 2026-10-04)

The town and building interiors are now seen from above, Rusty's style. Only the mine is side-on. This replaces the side-view strip described in Handoff 01, and a few entries above are superseded by it.

**Three regions, joined by doors.** The world is still one coordinate space and one nav grid, but the town (y = -1200), the mine (y >= 0) and the interiors (y = -2400) are separate regions that only connect through nav portals. The mine entrance is a door onto the top of the shaft, exactly like a building door. Because of that the mine entrance can now be moved like any other building.

**Views.** Surface, Mine and Interior are separate camera views. Each pans within its own bounds (the mine pans vertically so the ladder climb can still be watched), and each remembers where it was. There is no scrolling from one into another. Clicking the mine entrance opens the mine view, clicking a building opens its interior.

**Nav cells come in two kinds.** `TOP_DOWN` cells allow 8-way walking (no corner cutting). Other cells keep the side-view rules: sideways, one-cell steps, vertical only on ladders. Regions are far apart, so the two kinds never touch.

**Town grid.** 16px tiles (two nav cells a side), 128 x 9 tiles, which fills the 150px-tall view. Placement is free on the grid. Footprints: plots 2x2, kitchen and brewery 3x2, Great Hall 4x3, mine entrance 2x2. Buildings block walking; farm plots are walked on.

**Doors can't be walled in.** Every building also claims the row of tiles in front of it, so nothing can be built on a doorstep. A determined player could still fence part of town off with a wall of buildings; nothing checks for that yet. Dwarves caught under a newly placed building can walk out.

**Draw order** is y-sort across the town and the dwarves, with building origins at the bottom-left of their footprint. Farm plots draw underneath dwarves. Inside rooms, dwarves always draw over furniture.

**Interiors** are rectangles of floor with the door in the bottom wall. Workstations still go into three fixed slots, and a dwarf stands on the cell in front of a station to use it. Free furniture placement is the natural next step.

**Not isometric.** This is a straight top-down grid drawn with a slight tilt (roof plus a front wall), which is what the Rusty's reference is. True isometric would need a different grid.

## Needs drain only while working (2026-10-04)

Playtest: with food and drink ticking down constantly, the first trip down the ladder used up half of both bars and three dwarves cleared a handful of cells before climbing back to eat. Now hunger and thirst only tick on sim ticks where the dwarf applied work. Walking, climbing, hauling, waiting and idling are free.

What this changes: a meal's `shift_seconds` and a drink's `duration_seconds` are now seconds of real work. The ladder still costs wall-clock time on every meal trip and every ore haul, so the lift still pays for itself, but a long commute can no longer eat the whole shift. Idle dwarves no longer eat the pantry bare.

## Single-tile farm plots and hand tools (2026-10-04)

Farming changed from "place a Potato Plot and forget it" to tending individual plants.

**Farm Plot** is one buildable, one tile, one plant. The plant is drawn growing through stages (seedling, two growing stages, ripe with its produce showing).

**Player tools** sit in the top bar: a seed bag per crop, the Bucket and Harvest. One click with the right tool does the whole action (sow, water, harvest), and holding the button and dragging sweeps the tool across plots. Right-click, or clicking the tool again, puts it away. Dragging also paints rows of new plots while placing. This replaces the earlier "each click is a little work" rule for plots; ore nodes and workstations still use it.

**Harvest goes into the player's hand,** not straight to storage. It holds one crop type at a time (up to `hand_capacity`) and is dropped off by clicking the Great Hall. While holding crops that click does not enter the hall.

**The plot remembers its crop.** Sowing by hand chooses it; farmers then re-sow that crop after every harvest. Farmers ignore a plot nobody has ever sown. The four starting plots come with a crop already chosen (two potato, two barley) so a farmer assigned on a fresh game has something to do.

**Seeds are free and unlimited** for now. No seed item, no seed cost.

**Numbers.** A plant yields 2. Farmer work per plant is 1 to sow, 1 to water, 1.5 to harvest. A plot costs 3 coins.

## Rusty's-style farming and side panel (2026-10-04)

Direction from the user: emulate Rusty's Retirement closely, don't invent new gameplay yet. Supersedes parts of the previous section.

**Only the player sows.** Seeds cost 1 coin each (`CropDef.seed_cost`). Farmers water, harvest and haul, and leave harvested plots empty for the player to sow again. The starting plots begin unsown.

**Farming tools** live in the Farming tab: Hoe (roots up a plant, ripe or not, for no yield), Look (the magnifier; shows what it clicked in the top bar), Bucket, Shears. Then a seed bag per crop showing the stored count and the seed price, then locked squares. Farm Plot is bought, moved and destroyed in the Buildings tab like any building.

**Side panel** is a column of tabs down its left edge (X to fold at the top, Farm, Ores, Build, Shop, Debug, and Opts at the bottom), with the chosen page beside it. Picking any tab reopens a folded panel.

**Ores tab** lists ores with stored count and sell price, then locked squares for ores and ingots to come. Display only for now.

**Options tab** has the desktop-strip toggle (same as F10) and Quit.

**Top bar** shows what the player is holding and what it does, or what Look last saw.

**Farmers on unsown plots.** Dropping a dwarf on any plot makes him a farmer, sown or not. With nothing to water or harvest he waits beside the plot he was put on.

## UI art pass (2026-10-04)

**Integer 3x scale.** The canvas is now 640x150 (width expands to fill), with `scale_mode = integer`, so the 450px strip shows it at exactly 3x, the same pixel density as Rusty's. Before, it was 300px tall at 1.5x, which smears pixel art. The world camera went from zoom 2 to zoom 1, so the world framing is unchanged. All UI sizes are now in art pixels.

**Placeholder pixel art is generated** by `.tools/art/make_ui_art.py` from character grids, so a sprite is edited by editing its grid and re-running. The output in `assets/` is the real game asset; hand-drawn art can replace any PNG later without code changes.
- `assets/ui/frames/`: 9-slice button states (normal, hover, pressed/toggled gold, disabled), panel, recessed slot.
- `assets/ui/icons/`: tools, tab icons, lock, coin, close.
- `assets/items/`: one 16x16 icon per item (`ItemDef.icon`).
- `assets/fonts/dwarf_5x7`: a 5x7 all-caps bitmap font (BMFont). Lower case draws as capitals. Only the characters the UI uses exist; add glyphs to the table as needed. Replace with a licensed pixel font before release if preferred.

**One theme** (`ui/theme.tres`) carries the font and every frame. `SlotPanel` is a PanelContainer variation for recessed squares (storage slots, roster entries, top-bar chips).

**Layouts like Rusty's.** Farm and Ores squares are icon + stored count + coin price. Tabs are icon buttons. The top bar shows coin and food/drink chips (zero counts hidden); crops and ores live in their tabs. Roster entries are a portrait, job letter and two bars, with the name and status in the tooltip.

**Not yet:** the world (grass, plots, buildings, mine tiles, dwarves) and the text drawn in the world still use the old greybox and default font. That's the next pass.

## World art pass (2026-10-04)

Everything in the world now draws from sprites. Art is generated by `.tools/art/make_world_art.py` into `assets/{town,crops,buildings,interiors,mine,dwarf}`; any PNG can be swapped for hand-drawn art without code changes.

**Generators live in `.tools/gen/`** (`gen_data.py`, `gen_scenes.py`, `gen_ui.py`). The .tscn/.tres files were written by these, so it's easiest to change a scene there and re-run, or edit the scene in Godot and stop using the generator for it.

- **Town grass** is drawn by `Ground` (world/surface/ground.gd): one 16px tile at a time, variant picked by a hash of the tile (plain, tufts, flowers, stones), drawn once.
- **Farm plots** swap a dry or wet soil texture, and the plant is a 4-frame sprite per crop (`CropDef.growth_frames`): three growth stages, then ripe.
- **Buildings** are one sprite each: roof with the front wall, door and windows below, matching `door_offset_cells`.
- **Interiors**: a 9-slice stone wall frame, tiled plank floor, door, storage pile, table; stove and fermenter sprites with a small status light.
- **Mine terrain** is now a `TileMapLayer` (tile set `world/mine/terrain_tiles.tres`, 8px tiles) instead of a scaled image. Each kind of cell has a couple of variants picked by hash, and dug-out cells under a ceiling get a shadow tile. Ladder, lift rails, planks and ore deposits are textures.
- **Dwarf**: body sprite, a white beard sprite tinted per dwarf, a pick on the swing pivot, and a sack tinted the colour of what he carries.
- **World text** uses the pixel font: the UI theme is now also the project's default theme.

Room spacing in `Interiors` went to 1600px so one room never shows at the edge of another's view.

## Great Hall furniture (2026-10-04)

**The game starts with 4 dwarves,** and the hall with 2 small tables and 4 chairs (one either side of each table), authored in `great_hall_interior.tscn`.

**Furniture** (`FurnitureDef` + `Furniture`) stands on the room's 8px floor grid. Chair 1x1 (5c, a seat, walked on), table 2x2 (10c), long table 4x2 (20c); tables block walking. Placement rules live in `BuildingInterior.can_place`: inside the floor, not on the door cell or a reserved rect (the storage pile and the spot in front of it), not overlapping, and never walling off part of the floor (a flood fill from the door must still reach every open cell). Chairs can go anywhere; they don't have to touch a table.

**Dwarves eat in chairs.** The meal break claims a free chair; with every chair taken the dwarf waits by the storage pile ("Waiting for a seat", `!` badge) until one frees up. Chairs free up as soon as a meal ends, so too few chairs is a queue, not a hard stall. Moving or removing an occupied chair just makes the dwarf find another.

**Hall tab.** Opening the Great Hall swaps the side panel to the Hall tab (only Options stays): Move, Remove, then the furniture with prices along the top; food counts on the left, drink counts on the right. Leaving the hall restores the previous tab. Farming and building tools are put away on entering, the furniture tool on leaving.

**Turning furniture.** Furniture has a `facing` (quarter turns clockwise). Odd turns swap the footprint (a long table goes 4x2 to 2x4) and the sprite turns about the middle of the footprint. While a piece is in hand (placing, or picked up with Move), right-click turns it; otherwise right-click still puts the tool away. The Turn tool in the Hall tab turns placed pieces where they stand, only if the turned piece fits there. The starting chairs face their tables.

## Open-plan workstations (2026-10-04)

**Workstations are furniture.** `WorkstationDef` extends `FurnitureDef` and `Workstation` extends `Furniture`, so stoves and fermenters are bought, placed, turned, moved and removed with the same tool and rules as tables and chairs. Interior workstation slots are gone. Stations are 2x2 and block walking.

**Front access.** A station is worked from the cell in front of it (below the sprite as drawn, turning with it; `Furniture.front_of`). Placement requires that cell to be on the floor and clear, and nothing may later be placed on any station's front cell. So a station can never face a wall or be blocked in.

**Kitchen and brewery come furnished** with one stove / one fermenter against the back wall. Extra stations cost their `cost` and are bought from the room tab.

**The room tab** replaces the hall tab and follows whichever building is open: furniture and food/drink in the Great Hall; that building's stations and their ingredients (left) and products (right) elsewhere. The Build tab no longer has an indoors mode, and `Shop.buy_workstation` is gone.

## Recipes, playing stations, brewing chain (2026-10-04)

**Recipes are data** (`RecipeDef`: one input item and count, one output and count, load work, process seconds). A `WorkstationDef` lists its recipes. Multi-ingredient recipes would need dwarves to carry more than one item type, so they wait for now.
- Stove: stew (2 potato, 60s), gruel (1 potato, 20s).
- Mash pot: barley mash (3 barley, 30s), potato mash (2 potato, 20s).
- Fermenter (`fed_by` = mash pot): ale (1 barley mash makes 4, 180s), grog (1 potato mash makes 4, 90s). Loading a fermenter is the pour (4 work).
Potatoes, the cheapest crop, are the source of both emergency staples, gruel and grog. The shop still sells both.

**Station states:** idle (no recipe) -> loading (bar fills with work) -> processing (timer) -> output ready. Ingredients leave storage only when the loading bar fills. A storage-fed station goes straight back to loading the same recipe after its output is taken; a fermenter goes back to idle and waits for mash.

**Playing a station** (no tool in hand): clicking selects it and the room tab lists its recipes; picking one sets it. Each click while loading adds `manual_work_per_click`, only while the ingredients are in the hall (or poured in). Clicking a finished station puts the output in the player's hands, dropped off at the Great Hall like a harvest. The top bar describes the selected station.

**Pouring:** click an empty fermenter and the top bar asks for a finished mash pot; click one and the mash moves in. The fermenter still has to be loaded (clicked, or a dwarf finishes it). Holding mash in hand and clicking an empty fermenter pours it too.

**Dwarves never choose recipes.** Cooks/brewers empty finished stations, carry mash straight to a fermenter that takes it (or to the hall if none is free), fetch ingredients for stations that have a recipe set, finish loading anything the player poured, and feed idle fermenters from mash in the hall.

**Fermenters wobble** while brewing. Every station shows a small bar: yellow loading, orange working, green done. The brewery comes with a mash pot and a fermenter.

## Ledger, unlocks and the first crop ladder (2026-10-04)

**Ledger** (`economy/ledger.gd`, a child of World): lifetime counters keyed by name. Totals `harvested`, `meals_made`, `drinks_made`, `mined`, and per item `harvested:<id>`, `made:<id>`, `mined:<id>`. Recorded where things happen: `FarmPlot.harvest()`, a station finishing a batch, an ore node yielding ore.

**Unlocks are two gates** (`UnlockDef` on a CropDef or BuildingDef): a milestone (any Ledger counter and a target), then a trade (coins now; `items` for ore and ingots later). `Unlocks` (economy) runs the trades and remembers what's open by resource path. Crops show in the Farming tab as a padlock with progress ("12 /20"), then as an offer ("Buy" and the price) once the milestone is met, then as seeds. Building unlocks show the same way in the Shop tab. A recipe is on the menu once every crop it needs is unlocked.

**First ladder** (roughly the first 20-30 minutes; all placeholder numbers):
- Carrot: harvest 20 crops (any), trade 15 coins. Grows fast (30s).
- Onion: cook 15 meals, trade 30 coins. Grows slowly (75s).
- Brewery: harvest 20 barley, trade 60 coins (was a plain 60-coin unlock).
- Meals: gruel (1 potato, 20s cook, 90s shift), roast carrots (2 carrots, 30s, 200s), stew (2 potatoes, 60s, 300s), onion soup (1 onion + 2 potatoes, 90s, 480s).
- Drinks unchanged: grog and ale.

**Two-ingredient recipes:** recipes have `inputs` (a list of item stacks). A station keeps what's been dropped in for the current batch. Dwarves bring one kind of ingredient per trip and drop it in, and only work the bar once everything is inside. The player's clicks take whatever is missing from the hall when the bar fills. Switching recipe, or removing the station, returns anything inside to the hall.

**More crops and drinks (2026-10-04).** Radish (harvest 40 crops, 25 coins; grows in 35s) and wheat (make 10 drinks, 40 coins; 60s). Each gets a mash (3 crops make 1 mash) and a drink. Drinks now trade strength against length:
- Wheat beer: 90% fresh, lasts 240s; 4 per mash, 150s brew.
- Radish spirit: 115% fresh but only 60s; 3 per mash, 120s brew.
Neither crop has a meal yet.

## First metal industry (2026-10-04)

- **Smeltery** (unlock: mine 15 ore, then trade 80 coins + 5 copper ore) comes with a **smelter**: 3 copper ore make 1 copper ingot (60s).
- **Forge** (unlock: smelt 5 ingots, then trade 50 coins + 3 ingots) comes with an **anvil**: 2 ingots make a copper pick or a copper sickle (90s). These are the first unlock trades priced in goods.
- **Tools** (`ToolDef`, an item with a `job` and a `work_multiplier`). A dwarf carries one tool. Whenever he's at the hall (eating, or dropping goods off) he swaps to the best tool for his current job that's in storage, putting his old one back.
  A dwarf whose tool doesn't fit his job (reassigned, or made idle) goes to the Great Hall before doing anything else (`ToolErrand`): he puts the tool back, drops off what he's carrying, and takes the best tool for his new job if there is one. If he's already heading in to eat, he swaps at the meal instead. Dwarves also upgrade at any hall visit, but don't make a trip just because a better tool has been made. The copper pick makes miners 1.5x and the copper sickle does the same for farmers; the tool only counts while he's doing its job. His pick sprite takes the tool's colour, and the roster tooltip names it.
- The Ores tab lists copper ore, copper ingots and both tools.
- Not yet: smelting fuel (coal or charcoal), tools wearing out, and tools for cooks.

## Pointing dwarves out (2026-10-04)

Clicking a roster entry (without dragging) jumps the camera to that dwarf: into the room he is in, or to the town or mine view centred on him (`ViewCamera.show_dwarf`). With the camera toggle (top bar, next to Town/Mine) on, the camera then sticks to him: centred as he walks, changing view as he goes down the shaft or through a door. While following, panning and the view buttons are overridden; turn follow off to look elsewhere.

`DwarfPool.hovered` is the dwarf under the cursor, in the world (hit-tested against each dwarf's sprite rect) or in the roster. While one is hovered: a small arrow shows over his head, his roster entry lights up (job letter turns gold), and a `DwarfCard` follows the cursor with his name, status, food and drink bars (drink name and current work rate), what he's carrying and his tool. The roster's old tooltip is gone in favour of the card. The Look tool also works on dwarves (one line in the top bar). There's no mood yet; the card's work rate stands in for it.

## Dev folders are tracked (2026-10-05)

`.tests/` and `.tools/` are now in git, so the tests, generators, art scripts and this log travel with the repo (the user works on two machines). Godot still never imports dot-folders, so they stay out of the game itself. `addons/gut/` stays git-ignored at the user's choice; install GUT 9.7.1 on each machine. `CLAUDE.md` at the repo root carries the working rules for any Claude session.

## The copper layer, a shaft that grows, idlers in the hall (2026-10-05)

Playtest: three of four starting dwarves mined. Two took the landing's two tunnel ends and the third stood at the landing with no sign of why; forks (4% a column, none in the first 6) were the only source of new tunnel ends. Above the level sat 28 rows of undiggable bedrock, half the mine view. This entry supersedes the "Excavation" and "Ore nodes" paragraphs near the top where they differ.

**The ground.** Mine level 1 is the copper layer and now starts right under the grass (it sat 28 rows down). It is 256 x 36 cells; the terrain is 38 rows, so two rows of bedrock show under it. The top `dirt_rows` (6) rows are dirt and the rest is stone. The line between them is pushed up and down by 2D noise (`dirt_edge_rows`, 2.5), so it is ragged and leaves the odd pocket. Dirt takes 2 work a cell, stone 5.

**The shaft starts short** (user's call, option A over a full-depth shaft). It lands with dwarves' feet on row 4, in the dirt, about a 5-second climb. The first copper deposit sits in the dirt on the ceiling of the landing's east tunnel, so the first miner down finds it within a couple of columns. (While hidden it looks like a grey stone in the dirt: a hint, and left that way.) The landing tunnel heading for the nearest deposit is offered first. The other two deposits are out in the stone, west at rows 12-13 and deep east at rows 25-26.

**Where tunnel ends come from.** One miner per tunnel end stays (the user likes one dwarf working the end of each snake). A miner looking for one takes, in order: the one he has; the nearest free tunnel end; a new tunnel off the side of the shaft; the shaft itself, to dig deeper. Only when none of these exists does he have nothing to do.
- Branches off the shaft open at the shallowest height with room, alternating sides, and run flat for `branch_straight_columns` (2) before they may wander. A branch needs `branch_gap_rows` (3) solid rows between it and any other tunnel leaving that side of the shaft, so they are 5 rows apart. A branch is just a tunnel end whose first stand cell is a ladder rung, so the existing safety rule covers it.
- The shaft is dug down one cell at a time by a miner standing on the bottom rung, and the ladder (or lift) follows it down. It is only dug when nobody can open a branch, and the moment it is deep enough for one, it lets its digger go to open it. So the ladder grows only as the mine needs room, and the climb gets longer as the mine does. It stops one row above the level's floor.
- Code: `DigSafety` (the never-trap-a-dwarf rule and the reservations) and `ShaftDigging` (branch spots, digging down) were split out of `Excavation`, which keeps the heads, claims and tunnel steering. `MineLevel` now cuts the shaft itself after filling the ground.

**Direction for later (user, 2026-10-05).** The lift is a later-game upgrade, not an early one. Deeper metals (iron, then gold, platinum, maybe more) each get their own layer with its own ant-farm thickness, deeper and longer than copper. The bottom of each layer's ladder becomes a door into the next level, the way buildings have doors. None of this is built yet; lift price and timing need revisiting with it.

**Idlers sit in the hall with a "?".** Any dwarf whose job has nothing at all for him (unassigned, a farmer with nothing sown anywhere, a cook or brewer with no recipe set or missing ingredients, a miner with no room to dig) walks to the Great Hall and sits in a free chair, or stands by the storage pile if none is free. A "?" shows over his head, the roster badge is "?", and his card says why ("No job", "Nothing sown", "No recipe set", "Missing ingredients", "No tunnel to dig"). Wandering idlers are gone.
- "Nothing at all" means nothing will change until the player acts. Waiting that sorts itself out isn't idling: a farmer with crops growing waits by his plot, a cook with a batch cooking (or a station another dwarf is on) waits inside, as before. That keeps the "?" meaning "you need to do something".
- `Idler` is a dwarf component that roles call each tick they have nothing, like `Worker.work_on`; the first tick none does, he gets up. This kept the roles' "re-decide every tick" shape without a separate role per job.
- Idlers give up their chair to anyone who comes in to eat (`GreatHall.claim_seat` stands an idler up if every chair is taken).
- Later: a tavern that idlers prefer to the hall.

**The "?" art** is the font's own "?" in near-white with a dark outline (`outlined()` in `make_ui_art.py`).

## Game log (2026-10-05)

The game keeps a plain-text log of every session, so a playthrough can be read back afterwards to see how the tuning plays. It's a permanent part of the game, not a playtest add-on (user's call), and lives in `user://logs/` (on Windows `%APPDATA%\Godot\app_userdata\LDCP\logs\`), one `game_<date>_<time>.log` per session.
- Godot's own engine log shares the folder. Godot rotates `godot*.log` files there, so ours start with `game_` and are never touched by it. The newest 100 game logs are kept.
- **What's in it.** A header with the version, the start time and every tuning and content number (game tuning, mine level, crops, items, recipes, buildings, furniture), dumped from the Resources so new fields show up by themselves. Then events stamped with game time: the starting state, the first of each thing harvested, made or mined, unlock milestones reached, affordable and traded, buildings built and removed, recipes picked, hall furniture, deposits found, the shaft deepening, the lift, hires, jobs, tools, dwarves going idle (with the reason and for how long), dwarves waiting on an empty pantry, the pantry running out, game speed. Each game minute (with the clock time): coins earned and spent, what was harvested, made and mined, storage, how the plots and each station spent the minute, the player's clicks and sowing, the mine, and each dwarf's minute split into work, haul, walk, climb, eat, wait, idle, no food and no seat. Running totals every 5 game minutes and when the game closes.
- **How.** `GameLog` (a child of `Game`, set up last) writes the file and drives four `LogWatcher` children on the sim clock: Economy, Town, Mine, Crew. Watchers mostly compare state once a game second and write down what changed, rather than every system calling into the log; the gameplay code only gained `Ledger.counters()`, `Dwarf.job_title()`, `GridMover.is_climbing()` and `WorldInput.player_clicked`. Lines are flushed as written, so a crash or a killed window still leaves the log up to that second.
- Only a game run as the main scene starts its own log. Tests, the screenshot tool and other tools that instance `game.tscn` don't, but can call `GameLog.start(folder)`.
- Each unlock step is logged once, the first time it's reached, so coins hovering around a price don't make "can afford" flicker.

**No replanting in the early game (user, 2026-10-05).** Farmers don't resow a harvested plot; the player sows every crop. Automatic replanting would leave the player nothing to do but watch. Revisit later in the game, if at all.

## First playtest (2026-10-05)

A 12-minute run, read back from the game log (`game_2026-10-05_10-43-29.log`). What it showed:
- **Sowing was a treadmill.** The player bought 14 more plots in the first 10 minutes (18 in all), and with crops growing in 30 to 60 seconds that's about 20 sows a minute to keep up: 106 clicks in 12 minutes, mostly sowing, and no down time. Plots sat empty 35% of the time anyway.
- **Food ran short.** The starting 6 gruel and 6 grog were gone by 5:46. Gruel's 90-second shift sent miners up the ladder to eat every minute and a half; the food bar visibly emptied in under a minute of play.
- **The kitchen couldn't keep up.** 6 meals in 12 minutes against about 2 eaten a minute; the pantry ran out four times. The cook spent 38% of his time hauling (gruel takes 1 potato, so one trip per batch) and the stoves 41% of theirs waiting to be loaded. Not changed yet; options are with the user.
- **Assigning a cook looked broken.** The new dwarf was dropped on the kitchen, but no stove had a recipe, so he walked straight off to sit in the hall ("No recipe set"). Dropping him inside the kitchen did nothing at all.
- The shaft never went past row 5: with 3 miners and one deposit found, one works the deposit and two the landing's tunnels, so nobody needs the shaft.

Changes (user's calls, unless noted):
- **Crops grow half as fast:** potato 90s, barley 120s, carrot 60s, radish 70s, onion 150s, wheat 120s. Watering stays at 30s, so a farmer's work per minute is unchanged and each crop needs about twice the waterings.
- **Food and drink last twice as long:** gruel 180s, roast carrots 400s, stew 600s, onion soup 960s; grog 180s, ale 360s, wheat beer 480s, radish spirit 120s; dwarves start with 180s of food. Cognac stays at the GDD's 30 minutes (my call: it's a late drink, not part of this feedback).
- **The game starts with 10 gruel and 10 grog,** and a **3x3 block of 9 plots** beside the Great Hall (the user built two 3x3 blocks in the run).
- **Right-click puts away any tool,** including furniture being placed or carried (it used to turn the piece in hand, which left no quick way to stop placing stoves). The mouse wheel now turns a piece in hand, since the wheel does nothing indoors. Supersedes the turning note in "Great Hall furniture".
- **A dwarf dropped anywhere inside a workplace's room** (on a stove or the bare floor) is assigned to that building; dropped inside the Great Hall, he goes off duty, the same as dropping him on the hall in town.

**Idlers stay by their workplace (user, 2026-10-05).** Supersedes "Idlers sit in the hall with a '?'" above. Sitting in the hall made the town a ghost town, and made a new cook with no recipe look unassigned as he walked off. Now a dwarf with nothing at all to do potters about near his workplace with the "?" (a random standable cell within 6 cells, then a 2-6 second pause): a miner by the mine entrance, a cook or brewer inside his building, a farmer among the plots (around the one he was dropped on), and a dwarf with no job outside the Great Hall (my call; he has no workplace). Idlers no longer take hall chairs, so the chair-sharing rule is gone. The pottering lives in `Idler.potter()`, which the old `IdleRole` wander became.

**Cooks keep one trip per ingredient (user, 2026-10-05).** Hauling stays as it is: a cook fetches one batch's worth of one ingredient per trip. The trips are the movement we want to see, and they make the timings matter: ingredients per recipe (so trips per batch), loading work, cook time, how long a meal lasts and how fast it's eaten all get tuned together, from the logs. Ideas parked for that tuning, not built:
- A recipe could make several servings (2 potatoes make 4 stew rather than 1).
- If meals end up lasting around 5 minutes, moods could slow a dwarf's work by the quality of his food, on top of the drink's boost.

**The game log counts what's eaten and drunk.** Each minute ("Eaten and drunk: 3 Gruel, 2 Grog") and in the totals, with each dwarf's meal count and how often he came in to eat (from his first meal to his last). `Hunger.ate` and `Thirst.drank` signals feed it.
