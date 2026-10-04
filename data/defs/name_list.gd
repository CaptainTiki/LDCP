class_name NameList
extends Resource
## Syllables that are glued together to name a new dwarf.

@export var starts: PackedStringArray = []
@export var ends: PackedStringArray = []


func random_name(rng: RandomNumberGenerator) -> String:
	if starts.is_empty() or ends.is_empty():
		return "Dwarf"
	return starts[rng.randi() % starts.size()] + ends[rng.randi() % ends.size()]
