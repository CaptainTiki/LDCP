# LDCP: Little Dwarven Computer People

A desktop idle game in Godot 4.7 (GDScript) that sits in a strip along the bottom of the screen, in the style of Rusty's Retirement. A dwarven town farms, cooks and brews to keep its miners going; the miners dig an ant-farm mine below.

**Start here:** `docs/progress.md` covers where the project stands and what's next. `.tools/DECISIONS.md` has the reasoning behind every design and engineering call so far. `docs/GDD.md` is the original vision (partly out of date; progress.md says where).

## How we work

- **Emulate Rusty's Retirement first.** For mechanics and UI, default to how Rusty's does it. When a new idea would diverge, propose it and let the user decide; don't just build it. The user shares Rusty's screenshots as reference, so ask for one when unsure.
- **Early game first.**
  - Keep content scoped to the phase being built: the first crop and recipe set targets roughly the first 20-30 minutes.
  - Don't reach for late-game content before the systems around it exist.
  - Milestones: ~200 meals cooked is early game; ~1000 is where endgame starts.
- **Unlocks** are a Ledger milestone (harvest N of a crop, N crops total, cook N meals, make N of a recipe...) and then a trade. The earliest trades cost coins; ore and ingots come later.
- **Dwarves** carry one tool and one item type at a time. Multi-ingredient recipes mean multiple trips.
- **"Nothing is instant in an idle game":** player actions on stations take work (clicks to fill a bar), then time.

## Commits

- Commit each finished build (a working, tested piece of work); no need to ask first.
- Message: a short name only (a few words). No body, no trailers.
- Every commit bumps `config/version` in `project.godot`. Format: `proto-major.month.day.build`, e.g. `proto-0.10.5.24`. Month and day are the commit date. The build number counts up across commits and resets to 1 when a new month starts (the first commit in November is `proto-0.11.<day>.1`).
- Don't push unless asked.

## Engineering rules

- GDScript with `class_name` and explicit static typing everywhere. Human-readable code; comments explain *why*.
- **Node-first, scenes-first.**
  - Don't build node trees in code.
  - Runtime nodes come only from instancing authored scenes, or from map generation (mine terrain).
  - Content and tuning live in `.tres` Resources under `data/`.
- **Small component scripts and clear ownership.**
  - No autoloads: the `Game` scene owns everything and passes references down.
  - Keep scripts small (~200 lines is a sign to split).
- **Fixed-rate sim:** gameplay advances on `SimClock` ticks; visuals interpolate.
- **Clean game folders:** dev-only material lives in dot-folders (`.tools/`, `.tests/`). Godot never imports dot-folders, so they stay out of the game.

## Project layout

- `game/`: Game root, sim clock, window.
- `world/`: world root, camera, input, player hand, nav grid, town surface, mine terrain and excavation.
- `actors/dwarf/`: the dwarf, its components (hunger, thirst, carrier, mover, worker, job), and its roles (farmer, station worker, miner, meal break, tool errand, idle).
- `entities/`: buildings and interiors, farm plots, furniture, workstations, ore nodes, shared components.
- `economy/`: wallet, storage, shop, ledger, unlocks.
- `ui/`: the HUD and its panels.
- `data/`: `defs/` holds the Resource scripts; everything else is `.tres` content.
- `assets/`: pixel art and the bitmap font.

## Tools

- **Tests:** GUT 9.7.1, with tests in `.tests/`.
  - Run `.tools/run_tests.ps1` (pass `-Godot <exe>` or set the `GODOT` environment variable).
  - Or run Godot headless with `-s addons/gut/gut_cmdln.gd -gdir=res://.tests/unit,res://.tests/integration -gexit`.
  - `addons/gut/` is git-ignored: on a new machine, install GUT 9.7.1 from the Asset Library into `addons/gut/` first.
  - Run the tests before every commit.
- **Generators** (Python, run from their own folder):
  - `.tools/gen/gen_data.py` writes the `.tres` content. `.tools/gen/gen_ui.py` writes the HUD scenes and, by importing `gen_scenes.py`, every world, entity and game scene.
  - Most scenes and data were made by these. Change content there and re-run, so regenerating never wipes a change.
  - If a scene gets hand-edited in Godot instead, note it in DECISIONS.md and stop generating that scene.
- **Art:** `.tools/art/make_ui_art.py` and `make_world_art.py` draw all placeholder art into `assets/` from small character grids (Python + Pillow). Any PNG can be swapped for hand-drawn art without code changes.
- **Game log:** every game run as the main scene writes `user://logs/game_<date>_<time>.log` (on Windows `%APPDATA%\Godot\app_userdata\LDCP\logs\`): the tuning in play, then events, minute summaries and totals. Read it to see how a playthrough went.
- **Screenshots:** run Godot (not headless) with `-s .tools/screenshots.gd -- <output folder>` to capture the main views.
- **Godot imports:** after adding art or resources, run Godot once with `--headless --import`.

## Logging

When making a design or engineering call, append it, with the why, to `.tools/DECISIONS.md`. At the end of a session, update `docs/progress.md`.
