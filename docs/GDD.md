# Dwarf Town Idle: Light GDD

*Working title. Living document, so expect it to change.*

## Pitch

A desktop idle game that sits along the bottom of your screen, Rusty's Retirement style. A small dwarven town on the surface farms, cooks and brews to keep its miners fed and watered. Below the town, those miners carve an ever-growing ant-farm mine. You assign dwarves to jobs, place buildings and workstations, and step in by hand when something stalls. The dwarves do the rest.

**Core relationship:**
`Farming → Food / Drink → Dwarves → Mining → Ore → Coins → Settlement upgrades`

**Goal:** a commercially viable Steam release. The prototype is meant to grow into the product. It is not a throwaway.

This is a separate game from *Little Computer Dwarves*. They share a theme, not a codebase or a design.

## Design pillars

1. **Stall, don't collapse.** Running out of something makes dwarves wait, not die. Nothing the player neglects is permanently lost. The player can always kick-start a stalled town by hand or with emergency supplies.
2. **Upgrades solve problems you've watched.** The player sees dwarves slog up a long ladder, *then* buys the lift. Every purchase answers a visible pain.
3. **The world stays busy.** Dwarves physically walk, carry, chip, cook and pour. Resources move on dwarf backs, not through invisible pipes.
4. **The mine becomes your mine.** Important ore deposits are placed deliberately, but the dwarves dig the tunnels themselves, so every mine ends up shaped differently.
5. **Dwarves are autonomous.** The player assigns jobs. The player never steers individual dwarves.

## Format

- Bottom-of-screen desktop window, about twice the height of the Little Computer Dwarves strip (~300px to start, configurable), full width.
- **Right panel:** fold-out controls (build, shop, settings), like Rusty's.
- **Left panel:** fold-out dwarf roster, ~64px wide.
- **Center:** the current view (Surface, Building Interior or Mine).
- Windows first.

## Views

- **Surface / Town:** the main view. Farm plots, buildings, the mine entrance, and dwarves going about their work. Buildings and plots can be placed, moved and destroyed, so redesigning the town is part of play.
- **Building Interior:** click a building (with no tool selected) to go inside. Buildings are shells, and placed workstations and furniture make them useful.
- **Mine:** a side-view, ant-farm cutaway below the town. The shaft from the surface entrance leads down to the levels.

## Dwarves

- Assigned to jobs, buildings, ore nodes or the mine by dragging them from the roster.
- They pick their own tasks within an assignment and fetch their own inputs.
- **Roster** filters: *Located Here* / *All Dwarves*. A farmer can be reassigned to the mine without walking him anywhere first.
- Names now. Skills, traits and experience come later.

## Needs model

Two needs, two different jobs:

**Food = shift length (hard gate).**
- A meal fills the food bar, and the meal type sets how long it lasts. Better meals mean longer shifts and fewer trips.
- When food runs out, the dwarf finishes his current unit of work and walks to the Great Hall to eat.
- With no food in the hall, he sits at a table and waits. That's the stall.

**Drink = work rate (soft multiplier).**
- With no drink, a dwarf works at **50%**. He never stops working because he's thirsty.
- Each drink has a **low and high multiplier** and a **duration**. A fresh drink starts at its high and tapers toward its low, then toward the 50% floor as it runs out.
- Drink drains faster than food, so the back half of a long shift is a visible slog.
- Dwarves never make a trip just for a drink. They top up drink whenever they're in the hall for food.
- Animation speed tracks the multiplier, so you can spot a thirsty dwarf from across the screen.

Example drinks (placeholder numbers):

| Drink | Low | High | Duration | Source |
|---|---|---|---|---|
| Grog | 50% | 75% | short | Always purchasable |
| Ale | 50% | 100% | medium | Early brewery |
| Aged mushroom cap cognac | 50% | 150% | 30 min | Late brewery |

**Emergency supplies:** **gruel** (food) and **grog** (drink) can always be bought. Gruel restarts a stalled town. Grog is a cheap bonus before the brewery is unlocked, and a fallback after.

**Later upgrade idea:** underground keg stations at mine landings let miners top up drink without the full trip.

## Work model

Everything productive is **work units applied to a station**:

- A station (ore node, crop plot, stove, fermenter, smelter) needs X work to produce its output, or to complete a task such as watering or harvesting.
- Work rate = `base rate × tool tier × drink multiplier`.
- The player clicking a station applies work at a low manual rate through the same system.
- **Workstation rhythm:** a short burst of dwarf input work (loading the stove, ~5–10s), then a timed process runs by itself and the dwarf is free to go.

## Farming

- Plant, water and harvest, by hand at first and by farmer dwarves once assigned.
- Unwatered crops pause growth rather than dying.
- Crops feed the kitchen (food) and the brewery (drink).

## Storage and logistics

- The **Great Hall** is central storage, and the place where dwarves eat and drink.
- Dwarves physically carry everything: ore to the hall, potatoes to the kitchen, stew back to the hall.
- Later: specialized storage (Ore House) for efficient districts.

## Mining

- Assigned miners dig autonomously: mostly horizontal tunnels, with gentle slopes, planks where the elevation changes, and the occasional branch.
- **Ore nodes** are placed deliberately per level but stay hidden until a tunnel exposes them. A revealed node becomes a permanent workstation that dwarves can be assigned to.
- Small random finds (gems) turn up while digging.
- Deeper levels are harder to dig and hold more valuable ore.
- **Travel is real.** Ladders are slow, and lifts and minecart tracks are the upgrades that fix it.

## Metals (later)

`Ore → Smeltery → Ingots → Forge → Better tools and workstations`

Ore can always be sold. Buying expensive ingots of a new tier bootstraps the smelter that can make that tier locally.

Workstation material tiers (roughly copper → iron → gold → platinum) can do lower-tier work and unlock new recipes. Limited workstation slots force a choice: keep an old station for throughput, or replace it with a better one.

## Art and audio

- 2D pixel art at about Rusty's Retirement density. A 16×16 logical grid is the starting assumption, with larger sprites overhanging their footprint.
- Side-view town above a side-view mine.
- Audio is wanted (pick taps, bubbling fermenters, a quiet ambience) and has to be pleasant enough to run all day.

## Engineering must-haves

These apply for the life of the project, not just the prototype.

- **Human-readable code.** Clear names, short functions, comments that explain *why*. Someone opening a script cold should follow it.
- **Node-first, scenes-first.** Everything the game uses is an editable, reusable `.tscn`, `.tres` or `.gd`. No node trees assembled in code. Runtime nodes come only from instancing authored scenes (placing a building, for example), or from map generation.
- **Content and config as Resources** (`.tres`): crops, drinks, meals, materials, buildings, workstations, levels.
- **Component-style scripts.** Each script does one focused thing (a `Thirst` component, a `WorkReceiver` component). No long general-purpose manager scripts.
- **Avoid autoloads.** Ownership flows down from a root scene, and references are passed in or exported. Use an autoload only if there is truly no clean alternative, and record why.
- `class_name` with explicit static typing everywhere.
- **Pool dynamic objects** (dwarves, carried-item visuals) as authored nodes, rather than creating and freeing them freely.
- **Clean repo: game files only.** Tooling, tests, scratch scenes and dev notes live in a dot-folder (`.dev/`), which is git-ignored and which Godot doesn't import.

## Open questions

- Long-term goal: an ending, endless play, prestige, or a mix?
- Hiring: cost, population cap, what limits growth?
- Final crop, meal and drink lists, and their numbers.
- Do ore nodes deplete?
- Mine level sizes and count, and how the digging algorithm chooses direction.
- How much of farming gets automated, and when?
- Paths: required, or just faster? Tiers?
- Save, load and offline progress: full catch-up or summarized?
- Pricing and scope for a first Steam release.

## Roadmap sketch (sequencing, not limits)

1. **First slice:** farm → kitchen and brewery → Great Hall → mine level 1 → sell ore → lift. *(current)*
2. Smeltery, forge, ingots, tool tiers.
3. Deeper levels, minecarts, keg stations, gems.
4. Paths, specialized storage, more crops, meals and drinks.
5. Save/load, offline progress, a "while you were away" summary.
6. Art pass, audio, polish.
7. Steam page / demo.
