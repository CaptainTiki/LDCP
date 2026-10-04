class_name ContentCatalog
extends Resource
## The lists the UI is built from: what can be built, bought and sold.

## Every item the game knows about, in the order the readout shows them.
@export var items: Array[ItemDef] = []
## Crops the player has seeds for.
@export var crops: Array[CropDef] = []
## Everything that may appear in the build menu.
@export var buildings: Array[BuildingDef] = []
