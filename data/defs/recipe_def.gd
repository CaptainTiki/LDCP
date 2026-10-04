class_name RecipeDef
extends Resource
## One thing a station can make: what goes in, what comes out, how much work
## it takes to load, and how long the station then runs on its own.

@export var id: StringName
@export var display_name: String = ""
@export var input: ItemDef
@export var input_count: int = 1
@export var output: ItemDef
@export var output_count: int = 1
## Work to load the station: a dozen clicks for the player, a few seconds
## for a dwarf.
@export var load_work: float = 5.0
## Seconds the station then runs unattended.
@export var process_seconds: float = 60.0
