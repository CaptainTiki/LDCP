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

## Second playtest (2026-10-05)

A 45-minute run, mostly left alone (`game_2026-10-05_12-20-32.log`).
- Food now lasts as meant: miners came in for gruel every 5:00 to 5:27. The starting 10 gruel and 10 grog ran out at 20:27; after that miners spent about half the game waiting for food.
- The kitchen never cooked. It was built at 0:28, but recipe buttons were greyed out until the hall held the ingredients, so no recipe was ever set; 28 potatoes sat in the hall.
- The farmer was idle 39 minutes ("Nothing sown"), as expected with no replanting.
- Mining: 429 cells dug, 86 ore, 438 coins from selling it. The tunnels ran dead straight and never forked.

Fixes:
- **Recipes can be picked before the ingredients exist.** The station waits ("Gruel, waiting for 1 Potato") and its cook shows "Missing ingredients". On the recipe button, an ingredient the hall is short of shows its count in red, and the tooltip says the station will wait. Only mash-fed stations (fermenters) keep their recipes greyed out. The station panel in the room tab now has a status line under the station's name (`Workstation.status_text()`), the same text the Look tool shows.
- **Tunnelling bug: a blocked slope was never given up.** A tunnel that started sloping up and hit the surface kept its slope pending forever, and a pending slope blocks both new slopes and forks, so the tunnel ran flat to the edge of the level. Now a slope ends as soon as a column can't follow it (the surface, a deposit in the way).
- **Tunnels wander more** (my call, data in `level_1.tres`): slope chance 10% to 20% a column, fork chance 4% to 6%, and forking stops at 8 tunnel ends instead of 5, no longer counting the shaft itself.

Seen while checking, not changed: miners always prefer a found deposit to digging, and deposits never run out. In a 45-minute replay with 3 miners all three deposits were found by minute 10, and from then on nobody dug. The mine only grows if there are more miners than deposits.

## Third playtest (2026-10-05)

Two logs: an 80-minute run left alone after the first minute (`game_2026-10-05_14-02-10.log`, 14 clicks, no cook assigned, so nothing was cooked and miners went hungry from 19:26), and a 32-minute run played (`game_2026-10-05_15-22-37.log`).
- The player came in every 7 to 10 minutes (bursts of 10 to 39 clicks, almost all re-sowing a farm that grew to 36 plots) and was idle in between. But each sowing kept the farm busy only 3 to 6 minutes, so the farmer went "Nothing sown" well before the next visit and plots sat empty 49% of the game. The town spends most of its time stalled waiting for the player, which reads as "always being asked to interact". Not changed yet; options are with the user.
- Drinks ran out at 14:36 and never came back: the brewery needed 20 barley harvested, and nobody grows barley before there's a brewery to use it.
- Stew lasted about 8.5 minutes between meals for a miner; 33 meals in 32 minutes; the smeltery ran from 16:28.

**The brewery unlocks by cooking 10 meals, then 60 coins** (user's call to move it off barley; the counter is my pick from their list of potatoes, meals or ore). Its first drink, grog, is brewed from potatoes, so it's useful the moment it's built. At the played run's pace it lands around minute 15, as the starting grog runs out. Onion stays at 15 meals.

## Slow crops, brewing crops after the brewery, station waits in the log (2026-10-05)

From a review of the third playtest's logs.

**Crops grow 3x as long and yield 3x** (user's call, option 1 of the sowing-pace options): potato 270s, carrot 180s, radish 210s, barley and wheat 360s, onion 450s, all yielding 6. Watering still lasts 30s, so each plant needs 3x the waterings. That's the point: dry soil pauses growth, and in the third playtest planted plots were dry more of the time than they were growing, so the farmer, not the grow time, decides how long a sowing lasts. Tripling his work per plot stretches each sowing about 3x for the same food per farmer-minute.
- Checked headless (one farmer, nobody hungry, all potatoes): 9 plots kept the farm busy 2.9 minutes before, 7.4 now; 27 plots 8.3 minutes before, 20.3 now (11.0 with two farmers). The player's visits were 7 to 10 minutes apart.
- This gives the player two levers: more plots keep the farm going longer while they're away; more farmers turn it into food faster.
- Replanting (option 3) stays a candidate for a later unlock.
- Seeds still cost 1 coin, so they cost a third as much per crop. The carrot milestone (harvest 20) now comes with the first harvest rather than the second. Both left as they are until a playtest says otherwise.

**Dwarves carry 6, not 5** (my call), so one plot's harvest fits on a farmer's back. At 5, every harvest left one crop that went into the hall without being carried. Miners carry one more ore per trip as a result. A farmer already carrying something now takes it in first if the whole harvest won't fit on top of it (before, one more had to fit and the rest went to the hall uncarried).

**Brewing crops unlock from drinks** (user's call, extending the barley proposal to radish). In the third playtest 16 barley and 28 radishes sat unused, and 25 coins went on radish seeds. Now a crop doesn't unlock until something can use it:
- Barley: make 4 drinks (the first batch of grog), then 20 coins. It used to be a starting crop.
- Wheat: make 10 drinks, then 40 coins (unchanged).
- Radish: make 20 drinks, then 50 coins (it was harvest 40 crops, then 25 coins). The numbers are my pick.
- Until barley is unlocked, barley mash is off the mash pot's menu (`Unlocks.recipe_available`). The Farm tab lists crops in unlock order: potato, carrot, onion, barley, wheat, radish.

**The log splits a station's waiting into three.** "loading" used to cover everything with a recipe set. Now:
- "loading": a worker is stocking or loading it.
- "unattended": everything is to hand but nobody is on it, so the town is short of workers.
- "no ingredients": the hall lacks an ingredient, so the town is short of crops.

The playtests had both stalls showing as "loading": a stove set to onion soup when no onion had ever been sown, and (in the 80-minute run) a gruel stove that had no cook for the whole game.

## Fewer, longer waterings and uneven growth (2026-10-06)

From the user's morning playtest (`game_2026-10-06_09-19-59`). One farmer on 18 plots ran nonstop and still couldn't keep them watered: the water ran out just as he got round to each plot. And because every plant had the same numbers, a plant watered right at the end of a stage jumped a stage the moment it got water, as if it had been waiting on it.

**Each crop takes a set number of waterings** (user's call). Early crops take 2; slow later crops (around 20 minutes) are meant to take 3-4. `CropDef.waterings` replaces `watered_seconds` (30s, so a potato used to take 9). A watering keeps the soil wet for an even share of the growing still to do, so a potato's soil stays wet about 2.25 minutes.

**Plants and waterings vary** (user's call; the ±20% on water is my pick). Each plant's grow time is rolled when it's sown, ±10% (`grow_spread`), and each watering's length strays ±20% from an even share (`water_spread`). The last watering always lasts until the plant is ripe (my call), so a plant takes exactly its crop's waterings whatever the rolls; without that, about half the plants would need one more. Wet soil now dries under ripe plants and empty plots too, so plots dry out at varied times after harvest as well.

**Wet soil takes no more water** (my call). The bucket does nothing on wet soil; topping it up would spend one of the plant's waterings early.

Measured headless (one farmer, nobody hungry, every plot sown with potatoes at once):

| Plots | Before: farm empty after, planted plots dry | Now |
|---|---|---|
| 9 | 7.4 min, 27% | 6.7 min, 6% |
| 18 | 13.2 min, 58% | 8.3 min, 10% |
| 27 | 20.3 min, 70% | 10.4 min, 12% |
| 27, two farmers | 10.8 min, 49% | 7.6 min, 9% |

The farmer keeps up now. Most of his time goes on harvesting and hauling (a harvest of 6 fills his back, so each plot is a trip to the hall). The trade-off: last session stretched sowings by making watering the bottleneck. With that gone, a sowing lasts about the grow time plus the harvest, so 27 plots last about 10 minutes rather than 20, and a farmer makes food about twice as fast. Grow times are unchanged until a playtest says otherwise.

## HUD refactor: a top bar that can't grow, zigzag tabs, Inventory, the Look pop-up (2026-10-06)

From the user's playtest screenshot: inside a kitchen, the roster was pushed off the left edge and the side panel off the right. The top bar is one row whose minimum width kept growing: a chip for every meal and drink type in the hall, plus the hand-status text ("Stove: making stew, 20s to go"), plus the view buttons. Once it was wider than the gap between the roster and the side panel, the whole layout overflowed both ways. The status text also kept describing the last station clicked long after the player had moved on.

**The top bar is the town at a glance** (user's call): coins, plants growing (planted plots / all plots) and idle dwarves, then the Look button and the view buttons. Nothing in it grows as the town does. The food and drink chips are gone; the Inventory tab has the counts. Plots and idle dwarves have no change signals, so the readout polls them twice a second.

**The hand-status line is gone** (user's call). What it said moved:
- A selected station's status: the Look pop-up, and the room tab (unchanged).
- The pour prompt and "click the Great Hall" with crops in hand: the same pop-up beside the cursor, shown while they apply (my call, so the pour flow stays discoverable).
- The held-tool hints ("Bucket: click dry plants"): dropped. The Farm tab's tooltips say the same.

**Look is a hover tool, always in the top bar** (user's call). Pick up the magnifying glass and hover anything: a pop-up beside the cursor says what it is and what it's up to. A station shows its recipe, status, what's gone in and who's working it. A plot shows its crop, % grown, seconds to go, whether it's wet and how many waterings are left. Buildings, the mine entrance and deposits show their workers. A dwarf keeps his own card. **Any click in the world puts the glass away** and does nothing else (user's call). The Farm tab keeps its Look square too.

**Inventory tab** (user's call): a square for every kind of item the Great Hall holds (hidden at zero), with its count and sell price. Pick a square and the bar along the top sells one or all. Selling moved here from the Shop tab, which keeps Buy, Hire, the lift and Unlocks.

**Tabs zigzag in two staggered columns** (user's call). The 150px-tall tab column had no room for an eighth button. The X sits top right, then each tab drops half a step to the other side: Farm, Build, Ores, Inventory, Shop, Debug. Options stays at the bottom. Hidden tabs are skipped, so indoors the room tab closes up under the X. The side panel is 22px wider for it.

A test now checks the HUD's minimum width against the 640px canvas with one of everything in the hall, both in town and in a kitchen with a stove's recipes showing.

## Stations run themselves; the player's pick is their own (2026-10-06)

From the 74-minute playtest: the town stalled whenever the player was away, and stations only ever made what the player had set. The user asked for dwarves who get on with things, with the player able to step in.

**A station rests with no recipe** (user's call). A worker at a free station picks the best-quality recipe whose ingredients are all in the Great Hall, carries them over, and sets the recipe as the first of them goes in. When the output is taken away the station is free again, and the next batch is whatever is best then. So when potatoes run out, a cook falls back to roast carrots by himself.
- **Quality is a number on each item** (user's call): gruel 1, roast carrots 2, stew 3, onion soup 4; grog 1, ale 2, wheat beer 3, radish spirit 4, cognac 5; each mash ranks as its drink. Kept apart from how long a meal lasts, so meal lengths can be tuned freely, and ready for food moods later. The numbers are my pick, following unlock order.
- **Workers finish any batch already started**, theirs or the player's (my call), so a half-loaded station never sits stuck.
- **A tool is only forged while a dwarf in its job lacks one that good** (my call), counting tools in the hall and on other anvils. Tools never wear out, so an anvil left to pick freely would turn every ingot into spare picks. A smith with nothing wanted says "Nothing needed".
- `RecipeChooser` holds the rule. "No recipe set" is gone as an idle reason; a worker with nothing makeable says "Missing ingredients".

**The player's pick only affects what the player makes** (user's call). Picking a recipe in the room tab sets `Workstation.player_recipe` and nothing else. A click on the station while it's free, with everything for the recipe in the hall, starts a batch of it and puts the click's work in. While a batch is on, clicks load or empty it as before. Dwarves never read the player's pick.

**Cancel batch** (user's call): a button in the room tab while a batch is loading or cooking. What went in goes back to the hall, even from a pot already cooking (my call: nothing the player does loses goods). A finished batch isn't cancelled, just taken.

**The log** no longer says "set to" for every batch (dwarves start one every couple of minutes). It logs the player's picks instead. A free station's time splits like a loading one: a worker fetching for it ("loading"), something to make but nobody on it ("unattended"), nothing it can make ("no ingredients"), or nothing wanted ("idle").

Not built, to watch: a cook now turns every potato into a meal as fast as he can, so the kitchen and the brewery's potato mash compete for potatoes, and meals pile up with nothing to stop them. A stock target per station (stop at N stews) would fix both if it bites.

## Crops grow about 2.2x as long; the food chain tool (2026-10-06)

**A potato takes 10 minutes** (user's call, from 4.5); the others keep their ratio to it: carrot 400s, radish 480s, barley and wheat 800s, onion 1000s. Still 2 waterings each, so a watering lasts about 5 minutes on a potato.

**`.tools/food_chain.gd`** runs the real game headless with a steady player (every empty plot resown with potatoes at once; 1 farmer, 1 cook, 2 miners, 9 plots) and prints potatoes grown, meals made and eaten, and each dwarf's work share. It turns them into "one plot feeds N dwarves" and "one stove feeds N dwarves". The first run, 90 game minutes on these numbers:
- A plot gives 6 potatoes every 11.5 minutes (0.52 a minute).
- One stove made 42 stews (0.47 a minute; cooking 47% of the time, the rest waiting while the cook carried stew out and potatoes in).
- Dwarves ate 24 work-seconds of food a minute each. Miners worked about 70% of the time; the farmer 9% and the cook 8%, so they hardly ate: hunger only drains while working.
- So one plot of potatoes, cooked as stew, feeds about 6.5 dwarves, and one stove about 11.6. 346 potatoes were left over: one cook can't keep up with 9 plots.

The user's target is 2 plots per dwarf for now (1 per dwarf once meals and drinks last longer): about 13x less food per plot than today. Recipes alone can't get there (a stew would need about 25 potatoes), so the levers are on the table: more potatoes per meal, smaller harvests, hunger draining on all time spent on the job, shorter meals.

## Food all the time, meals twice the crops, harvests of 2 (2026-10-06)

The user's target: 2 plots of potatoes feed 1 dwarf for now (1 per dwarf later, once meals and drinks last longer). The food chain tool said a plot fed about 6.5 dwarves. Three levers, all the user's calls:
- **Food runs down all the time**, whatever the dwarf is doing, not just while he works. It used to be work-only (2026-10-04) because a ladder trip ate half of a 90-second meal. Meals now last 3 to 16 minutes, so a commute no longer matters, and cooks and farmers, who mostly walk and haul, now eat like everyone else (they worked 6-9% of the time and hardly ate). **Drink stays work-only**: it's the work-rate boost, and when to drink is still an open question.
- **Meals take twice the crops**: gruel 2 potatoes, roast carrots 4 carrots, stew 4 potatoes, onion soup 2 onions + 4 potatoes. Each still fits in one trip per ingredient. Mash recipes are unchanged (my call: the target was about food).
- **A harvest yields 2, not 6** (a third; the user offered a half or a quarter). Measured with the tool, 90 game minutes, 9 plots kept sown, 1 farmer, 1 cook, 2 miners:
  - Yield 3: one plot fed 0.7 dwarves (1.46 plots per dwarf).
  - Yield 2: one plot fed 0.5 dwarves (2.18 plots per dwarf). Chosen as nearest the target.
  - Each dwarf ate about 58 work-seconds of food a minute. One stove fed about 4 dwarves. Nobody waited for food.

Knock-on changes (my calls):
- **20 starting gruel, not 10.** With food running down all the time, 10 ran out at about minute 10, just before the first stew. Then every dwarf, the farmer and cook included, sat in the hall waiting for food; a finished stew sat in the stove and nothing was ever cooked again. 20 lasts to about minute 18.
- **Carrots unlock at 15 crops harvested, not 20**, so they still come with the first sowing (9 plots now yield 18).

To watch:
- **9 plots now just about feed the 4 starting dwarves**, so the town only grows as the farm does. If food runs out (the farm left empty, the player away), everyone stops, the farmer and cook included, and it doesn't restart by itself: the player buys gruel or waters, harvests and cooks by hand. "Hunger stalls, never hurts" made that rare before; now it's likely.
- **Milestones counted in meals come later for the same farm**: a plot makes a sixth of the meals it did. The brewery (10 meals) and onions (15 meals) will land later unless the player grows the farm.
- **A cook makes gruel when only 2-3 potatoes are in**, because it's the best he can make right then. Gruel is less food per potato than stew (90 work-seconds against 150), so trickling harvests waste some.

## The market (2026-10-06)

The user's idea: with food now tight per plot, surplus is still worth something if it can be sold without the player there. "Then it wouldn't matter that 3 dwarves are fed from 1 plot: the excess gets sold, and we have a passive income."

**A market building with a stall inside** (user's call on the idea; the shape is mine). It's built like the kitchen (30 coins, 3x2). Its room has one stall against the back wall, which isn't furniture (it can't be moved or removed), so the room tab shows no furniture tools there.

**The keep list lives in the market's room tab** (user's call). Every item that sells is listed by category (crops, meals, drinks, brewing, ore and metal, tools), each with its count in the hall and a - keep + control. The keep number steps through 0, 5, 10, 20, 50, 100 and "all" (my pick of steps). The count turns gold while some is for sale. Items carry a new `ItemDef.category` for the grouping.

**Everything is kept until the player sets a number** (user's call), so the market never sells seed potatoes or the brewery's barley by surprise.

**A trader works it** (user's call: "if you have a worker working it"). A dwarf dropped on the market gets a new job, Trader (`JobAssignment.Kind.TRADER`). He takes whatever the hall holds above a keep number, the item with the most to spare first, one kind and one load (up to 6) at a time. He puts it on the stall and works the stall to sell it, 2 work per item (`GameTuning.sell_work_per_item`, my pick). Coins arrive as each one sells. With nothing above a keep number he waits in the market with "Nothing to sell". A player's click on the stall puts in a little work, like any station. Prices are the same as selling by hand.

**Unlock: sell 30 by hand, then 30 coins** (user's call). Selling from the Inventory tab now counts in the ledger (`sold`, and `sold:<item>`), and so does the market.

**The world now holds the purse and the tuning** (`World.wallet`, `World.tuning`), handed down at setup like everything else, because the stall pays into the purse once it's placed.

## Running out of food stays a stall (2026-10-06)

With food tight, the town will run out when the player is away, and then everyone waits in the hall, the farmer and cook included, so it can't restart by itself. Offered: hungry dwarves with no food work on at half pace. **The user kept the stall**: it's the cost of running out, and the player ends it by buying gruel or by working the farm and stove by hand.
