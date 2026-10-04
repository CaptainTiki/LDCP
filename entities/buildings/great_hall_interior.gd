class_name GreatHallInterior
extends BuildingInterior
## The hall's room: a storage pile by the door, and whatever tables and
## chairs the player has set out.

@onready var _storage_spot: Marker2D = $StorageSpot


func storage_cell() -> Vector2i:
	return cell_at(_storage_spot)
