class_name RecipeSlot
extends Button
## One recipe in the room tab: what goes in (one or two ingredients), an
## arrow, what comes out. Pick it to make it yourself: clicking the station
## while it's free starts a batch. The dwarves choose their own.
## Ingredients the hall is short of show in red.

signal chosen(recipe: RecipeDef)

const SHORT_COLOR: Color = Color(1.0, 0.45, 0.4)

## Shown for an ingredient that's "any crop" rather than one item.
@export var any_icon: Texture2D

var recipe: RecipeDef
var _tooltip: String = ""

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
			var stack: ItemStack = recipe.inputs[i]
			_in_icons[i].texture = any_icon if stack.is_any() else stack.item.icon
			_in_counts[i].text = str(recipe.inputs[i].count)
	_out_icon.texture = recipe.output.icon
	_out_count.text = str(recipe.output_count)
	_tooltip = "%s\n%s makes %d %s\n%d seconds" % [recipe.display_name, recipe.describe_inputs(),
			recipe.output_count, recipe.output.display_name, roundi(recipe.process_seconds)]
	tooltip_text = _tooltip


## Pressed while it's the player's pick; greyed out only when the station
## takes poured mash instead.
func refresh(station: Workstation, storage: Storage) -> void:
	set_pressed_no_signal(station.player_recipe == recipe)
	disabled = station.is_fed_by_station()
	var short: bool = false
	for i: int in recipe.inputs.size():
		var stack: ItemStack = recipe.inputs[i]
		var is_short: bool = stack.available_in(storage) < stack.count
		_in_counts[i].modulate = SHORT_COLOR if is_short else Color.WHITE
		short = short or is_short
	tooltip_text = _tooltip + ("\nNot enough in the hall yet" if short else "")


func _pressed() -> void:
	chosen.emit(recipe)
