class_name ToolDef
extends ItemDef
## A tool a dwarf can carry: it speeds up one kind of job. A dwarf holds one
## tool at a time and swaps up to a better one for his job whenever he's at
## the Great Hall and one is in storage.

## The job this tool is for.
@export var job: JobAssignment.Kind = JobAssignment.Kind.MINER
## Multiplies the dwarf's work rate while he does that job.
@export var work_multiplier: float = 1.5
