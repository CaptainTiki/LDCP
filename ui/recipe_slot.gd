class_name RecipeSlot
extends Button
## One recipe in the room tab: what goes in (one or two ingredients), an
## arrow, what comes out. Pick it to set the selected station making it.

signal chosen(recipe: RecipeDef)

var recipe: RecipeDef

@onready var _in_icons: Array[TextureRect] = [$Margin/Row/In1Icon as TextureRect, $Margin/Row/In2Icon as TextureRect]
@onready var _in_counts: Array[Label] = [$Margin/Row/In1Count as Label, $Margin/Row/In2Count as Label]
@onready var _out_icon: TextureRect = $Margin/Row/OutIcon
@onready var _out_count: Label = $Margin/Row/OutCount


func setup(for_recipe: RecipeDef) -> void:
	recipe = for_recipe
	for i: int in _in_icons.size():
		var has_input: bool = i < recipe.inputs.size()
		_in_icons[i].visible = has_input
		_in_counts[i].visible = has_input
		if has_input:
			_in_icons[i].texture = recipe.inputs[i].item.icon
			_in_counts[i].text = str(recipe.inputs[i].count)
	_out_icon.texture = recipe.output.icon
	_out_count.text = str(recipe.output_count)
	tooltip_text = "%s\n%s makes %d %s\n%d seconds" % [recipe.display_name, recipe.describe_inputs(),
			recipe.output_count, recipe.output.display_name, roundi(recipe.process_seconds)]


## Pressed when the station is making this; greyed out when it can't be
## chosen (not enough in the hall, or the station takes poured mash).
func refresh(station: Workstation, storage: Storage) -> void:
	set_pressed_no_signal(station.recipe == recipe and not station.is_idle())
	var short: bool = false
	for stack: ItemStack in recipe.inputs:
		if storage.count(stack.item) < stack.count:
			short = true
	disabled = station.is_fed_by_station() or short


func _pressed() -> void:
	chosen.emit(recipe)
