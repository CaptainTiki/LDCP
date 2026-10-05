class_name LogFormat
extends RefCounted
## Text helpers for the game log.

## Exported properties that are art, not tuning.
const _ART_CLASSES: Array[StringName] = [&"Texture2D", &"PackedScene", &"Curve"]


## Game time as h:mm:ss.
static func time(seconds: float) -> String:
	var whole: int = floori(seconds)
	return "%d:%02d:%02d" % [whole / 3600, (whole / 60) % 60, whole % 60]


## How a stretch of ticks was spent, as "work 62%, walk 20%", in `order`.
static func shares(ticks: Dictionary, order: Array[String]) -> String:
	var total: int = 0
	for key: String in ticks:
		total += ticks[key]
	if total == 0:
		return "-"
	var parts: PackedStringArray = []
	for key: String in order:
		var count: int = ticks.get(key, 0)
		if count > 0:
			parts.append("%s %d%%" % [key, roundi(100.0 * count / total)])
	return ", ".join(parts)


## Counts as "3 Potato, 2 Stew", biggest first.
static func counts(amounts: Dictionary) -> String:
	var names: Array = amounts.keys()
	names.sort_custom(func(a: String, b: String) -> bool: return amounts[a] > amounts[b])
	var parts: PackedStringArray = []
	for item_name: String in names:
		parts.append("%d %s" % [amounts[item_name], item_name])
	return ", ".join(parts) if not parts.is_empty() else "none"


## The name a player knows a resource by.
static func name_of(thing: Resource) -> String:
	if thing == null:
		return "-"
	var shown: Variant = thing.get(&"display_name")
	if shown is String and not (shown as String).is_empty():
		return shown
	var id: Variant = thing.get(&"id")
	if id != null and not str(id).is_empty():
		return str(id)
	return thing.resource_path.get_file().get_basename()


## A resource's tuning as "key=value" pairs: its exported numbers and flags,
## and the names of the resources it points to. Art is left out.
static func describe(thing: Resource) -> String:
	var parts: PackedStringArray = []
	for property: Dictionary in thing.get_property_list():
		var usage: int = property.usage
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (usage & PROPERTY_USAGE_STORAGE):
			continue
		if property.type == TYPE_COLOR or property.class_name in _ART_CLASSES:
			continue
		var key: String = property.name
		if key == "id" or key == "display_name":
			continue
		var value: Variant = thing.get(key)
		var text: String = _enum_name(property, value) if property.hint == PROPERTY_HINT_ENUM else _value(value)
		parts.append("%s=%s" % [key, text])
	return " ".join(parts)


## An enum property's value by name, e.g. "Miner" rather than 3.
static func _enum_name(property: Dictionary, value: Variant) -> String:
	for entry: String in (property.hint_string as String).split(","):
		var entry_value: int = int(entry.get_slice(":", 1)) if entry.contains(":") else -1
		if entry_value == value:
			return entry.get_slice(":", 0).capitalize()
	return str(value)


static func _value(value: Variant) -> String:
	if value == null:
		return "-"
	if value is ItemStack:
		var stack: ItemStack = value
		return "%d %s" % [stack.count, name_of(stack.item)]
	if value is UnlockDef:
		var unlock: UnlockDef = value
		return "(%s %d, then %s)" % [unlock.counter, unlock.needed, unlock.describe_price()]
	if value is Resource:
		return name_of(value)
	if value is Array:
		var entries: PackedStringArray = []
		for entry: Variant in value:
			entries.append(_value(entry))
		return "[%s]" % ", ".join(entries)
	return str(value)
