class_name WorkReceiver
extends Node
## Everything productive is work applied to one of these. A station owns a
## receiver, says how much work the current job needs, and reacts when it
## completes. Dwarves and player clicks both feed the same receiver.

## `worker` is the Dwarf who finished the job, or null for a player click.
signal completed(worker: Node)
## Work was added or the job was reset; for progress bars.
signal progressed

@export var work_required: float = 1.0

var progress: float = 0.0
## Only one dwarf works a receiver at a time. See try_claim().
var claimed_by: Node = null


func apply_work(amount: float, worker: Node = null) -> void:
	progress += amount
	if progress >= work_required:
		progress = 0.0
		completed.emit(worker)
	progressed.emit()


## Starts a fresh job needing `new_work_required` work.
func reset(new_work_required: float) -> void:
	work_required = new_work_required
	progress = 0.0
	progressed.emit()


func ratio() -> float:
	return clampf(progress / work_required, 0.0, 1.0) if work_required > 0.0 else 0.0


## Reserves the receiver for one worker. Returns false if someone else has it.
func try_claim(worker: Node) -> bool:
	if claimed_by != null and is_instance_valid(claimed_by) and claimed_by != worker:
		return false
	claimed_by = worker
	return true


func release(worker: Node) -> void:
	if claimed_by == worker:
		claimed_by = null
