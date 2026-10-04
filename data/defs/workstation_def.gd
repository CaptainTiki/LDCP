class_name WorkstationDef
extends Resource
## A workstation that turns one item into another: a short burst of dwarf
## work to load it, then a timed process that runs on its own.

@export var id: StringName
@export var display_name: String = ""
## Scene instanced into a building's interior slot. Its root is a Workstation.
@export var scene: PackedScene
@export var cost: int = 20

@export_group("Recipe")
@export var input: ItemDef
@export var input_count: int = 2
@export var output: ItemDef
@export var output_count: int = 1
## Work a dwarf must apply to load the ingredients.
@export var load_work: float = 6.0
## Seconds the station then runs unattended.
@export var process_seconds: float = 60.0
