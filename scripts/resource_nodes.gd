class_name ResourceNodes
extends RefCounted
## Trees (axe) and rocks (pickaxe): hits to break, drops, tree stump regrows after days.

const HP := {"tree": 5, "rock": 3}
const DROPS := {"tree": ["wood", 3], "rock": ["stone", 2]}
const TOOL := {"tree": "axe", "rock": "pickaxe"}
const REGROW_DAYS := 4

var nodes: Dictionary = {}   # cell -> {"kind", "hp", "stump_days"} ; stump_days>0 means chopped
var removed_rocks: Dictionary = {}

func add(kind: String, cell: Vector2i) -> void:
	nodes[cell] = {"kind": kind, "hp": HP[kind], "stump_days": 0}

func is_solid(cell: Vector2i) -> bool:
	return nodes.has(cell) and nodes[cell].stump_days == 0

func hit(cell: Vector2i, tool: String) -> Dictionary:
	## Returns {} on no effect, {"hit":true} on damage, {"id","n"} when broken.
	if not is_solid(cell) or TOOL[nodes[cell].kind] != tool:
		return {}
	var n = nodes[cell]
	n.hp -= 1
	if n.hp > 0:
		return {"hit": true}
	var d: Array = DROPS[n.kind]
	if n.kind == "tree":
		n.stump_days = REGROW_DAYS
	else:
		nodes.erase(cell)
	return {"id": d[0], "n": d[1]}

func next_day() -> void:
	for c in nodes:
		var n = nodes[c]
		if n.stump_days > 0:
			n.stump_days -= 1
			if n.stump_days == 0:
				n.hp = HP[n.kind]
