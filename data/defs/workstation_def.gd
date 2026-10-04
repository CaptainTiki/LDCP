class_name WorkstationDef
extends FurnitureDef
## Furniture that makes things. Placed, turned and moved like any furniture;
## a dwarf works it from the cell in front.

## Everything this station can make.
@export var recipes: Array[RecipeDef] = []
## Set when this station's ingredients come out of another station rather
## than from storage: a fermenter is fed by a mash pot. Such a station picks
## its recipe from whatever is poured into it.
@export var fed_by: WorkstationDef
