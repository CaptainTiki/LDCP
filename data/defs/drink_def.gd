class_name DrinkDef
extends ItemDef
## Drink. A fresh drink starts at its high multiplier and tapers to its low.

@export var low_multiplier: float = 0.5
@export var high_multiplier: float = 1.0
@export var duration_seconds: float = 120.0
## Shape of the taper: x is how much of the duration has elapsed (0..1),
## y is the remaining strength (1 = high multiplier, 0 = low multiplier).
@export var taper: Curve


func multiplier_at(elapsed_ratio: float) -> float:
	var clamped: float = clampf(elapsed_ratio, 0.0, 1.0)
	# Without a curve fall back to a straight line so the drink still works.
	var strength: float = taper.sample(clamped) if taper != null else 1.0 - clamped
	return lerpf(low_multiplier, high_multiplier, strength)
