class_name GreatHallInterior
extends BuildingInterior
## The hall's room: a storage pile by the door and seats at the tables.

@onready var _storage_spot: Marker2D = $StorageSpot
@onready var _seats: Node2D = $Seats


func storage_cell() -> Vector2i:
	return cell_at(_storage_spot)


func seat_cell(index: int) -> Vector2i:
	var seat: Node2D = _seats.get_child(index % _seats.get_child_count()) as Node2D
	return cell_at(seat)
