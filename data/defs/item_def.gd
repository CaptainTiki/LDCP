class_name ItemDef
extends Resource
## Anything that can sit in storage or ride on a dwarf's back.

## Groups for lists of every item, like the market's.
enum Category { OTHER, CROP, MEAL, DRINK, BREWING, METAL, TOOL }

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
## How good it is. A worker left to himself makes the best his station can
## (RecipeChooser). Meals, drinks and the mash for each drink have one.
@export var quality: int = 0
@export var category: Category = Category.OTHER
