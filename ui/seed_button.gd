class_name SeedButton
extends Button
## A seed bag for one crop in the farming tools.

signal chosen(crop: CropDef)

var crop: CropDef


func setup(for_crop: CropDef) -> void:
	crop = for_crop
	text = "%s seeds" % crop.display_name


func _pressed() -> void:
	chosen.emit(crop)
