class_name MarketInterior
extends BuildingInterior
## The market's room: the stall against the back wall, worked from the spot
## in front of it.

@onready var stall: MarketStall = $Stall


func setup(world: World, owner_building: Building) -> void:
	super(world, owner_building)
	stall.setup(world)
