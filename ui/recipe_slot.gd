class_name RecipeSlot
extends Button
## One recipe in the room tab: what goes in, an arrow, what comes out.
## Pick it to set the selected station making it.

signal chosen(recipe: RecipeDef)

var recipe: RecipeDef

@onready var _in_icon: TextureRect = $Margin/Row/InIcon
@onready var _in_count: Label = $Margin/Row/InCount
@onready var _out_icon: TextureRect = $Margin/Row/OutIcon
@onready var _out_count: Label = $Margin/Row/OutCount


func setup(for_recipe: RecipeDef) -> void:
	recipe = for_recipe
	_in_icon.texture = recipe.input.icon
	_in_count.text = str(recipe.input_count)
	_out_icon.texture = recipe.output.icon
	_out_count.text = str(recipe.output_count)
	tooltip_text = "%s\n%d %s makes %d %s\n%d seconds" % [recipe.display_name, recipe.input_count,
			recipe.input.display_name, recipe.output_count, recipe.output.display_name, roundi(recipe.process_seconds)]


## Pressed when the station is making this; greyed out when it can't be
## chosen (not enough in the hall, or the station takes poured mash).
func refresh(station: Workstation, storage: Storage) -> void:
	set_pressed_no_signal(station.recipe == recipe and not station.is_idle())
	disabled = station.is_fed_by_station() or storage.count(recipe.input) < recipe.input_count


func _pressed() -> void:
	chosen.emit(recipe)
