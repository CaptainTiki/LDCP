class_name ItemDef
extends Resource
## Anything that can sit in storage or ride on a dwarf's back.

@export var id: StringName
@export var display_name: String = ""
## Shown in the UI: storage tabs, the top bar, shop rows.
@export var icon: Texture2D
## Greybox colour for the carried-item slot and UI swatches.
@export var color: Color = Color.WHITE
## Coins per unit when sold at the Great Hall. 0 means it cannot be sold.
@export var sell_price: int = 0
## Coins per unit when bought from the shop. 0 means it cannot be bought.
@export var buy_price: int = 0
