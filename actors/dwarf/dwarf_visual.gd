class_name DwarfVisual
extends Node2D
## Greybox dwarf animation. It only reads the dwarf's state: tool swings when
## working, a bob when walking, a slump when sitting. Everything runs at the
## drink multiplier, so a thirsty dwarf visibly drags.

@export var swing_speed: float = 9.0
@export var bob_speed: float = 10.0

var _anim_time: float = 0.0

@onready var _dwarf: Dwarf = get_parent() as Dwarf
@onready var _beard: ColorRect = $Beard
@onready var _tool_pivot: Node2D = $ToolPivot
@onready var _carry_slot: ColorRect = $CarrySlot
@onready var _lift_car: ColorRect = $LiftCar


func _process(delta: float) -> void:
	if not _dwarf.is_active:
		return
	_anim_time += delta * _dwarf.clock.speed_scale * _dwarf.thirst.multiplier()
	_beard.color = _dwarf.color
	scale.x = _dwarf.mover.facing

	var is_working: bool = _dwarf.worker.is_working()
	_tool_pivot.visible = is_working
	_tool_pivot.rotation = sin(_anim_time * swing_speed) * 0.9 if is_working else 0.0

	if _dwarf.mover.is_moving():
		position.y = roundf(-absf(sin(_anim_time * bob_speed)) * 1.5)
	elif _dwarf.is_sitting:
		position.y = 3.0
	else:
		position.y = 0.0

	_carry_slot.visible = not _dwarf.carrier.is_empty()
	if _carry_slot.visible:
		_carry_slot.color = _dwarf.carrier.item.color
	_lift_car.visible = _dwarf.mover.is_on_lift()
