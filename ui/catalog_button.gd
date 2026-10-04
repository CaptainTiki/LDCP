class_name CatalogButton
extends Button
## A button that stands for one thing with a price: a building to place, a
## workstation or supply to buy, an unlock. Lists in the side panel are made
## by instancing one of these per catalog entry.

signal chosen(payload: Resource)

var payload: Resource
var cost: int = 0


func setup(for_payload: Resource, label: String, coin_cost: int) -> void:
	payload = for_payload
	cost = coin_cost
	text = "%s  %dc" % [label, coin_cost]


func _pressed() -> void:
	chosen.emit(payload)


## Greys the button out when the purse is too light.
func refresh(wallet: Wallet) -> void:
	disabled = not wallet.can_afford(cost)
