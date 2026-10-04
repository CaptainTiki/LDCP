class_name Wallet
extends Node
## The town's coin purse.

signal changed

var coins: int = 0


func can_afford(cost: int) -> bool:
	return coins >= cost


func earn(amount: int) -> void:
	coins += amount
	changed.emit()


## Takes the coins if there are enough. Returns whether the purchase went through.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	coins -= cost
	changed.emit()
	return true
