class_name ResourceNodes
extends RefCounted
## Trees (axe) and rocks (pickaxe): hits to break, drops, tree stump regrows after days.

const HP := {"tree": 5, "rock": 3}
const DROPS := {"tree": ["wood", 3], "rock": ["stone", 2]}
const TOOL := {"tree": "axe", "rock": "pickaxe"}
const REGROW_DAYS := 4

var nodes: Dictionary = {}   # cell -> {"kind", "hp", "stump_days"} ; stump_days>0 means chopped
var removed_rocks: Dictionary = {}

var mined: Dictionary = {}   # cell -> true: rocks that were broken (kept so a save/reload does not bring them back)
var saved: Dictionary = {}   # cell -> [hp, stump_days] loaded from a save, applied when the cell registers

func add(kind: String, cell: Vector2i) -> void:
	if kind == "rock" and mined.has(cell):
		return
	nodes[cell] = {"kind": kind, "hp": HP[kind], "stump_days": 0}
	if saved.has(cell):
		var st: Array = saved[cell]
		saved.erase(cell)
		nodes[cell].hp = clampi(int(st[0]), 1, HP[kind])
		nodes[cell].stump_days = clampi(int(st[1]), 0, REGROW_DAYS)

func to_array() -> Array:
	## Only the cells that differ from a fresh world: [x, y, hp, stump_days] for damaged/chopped trees and
	## rocks, [x, y, -1, 0] for broken rocks. Also keeps deltas that were loaded but not registered yet
	## (a chunk that has not streamed in since the save).
	var out: Array = []
	for c in nodes:
		var n: Dictionary = nodes[c]
		if n.hp < HP[n.kind] or n.stump_days > 0:
			out.append([c.x, c.y, n.hp, n.stump_days])
	for c in saved:
		out.append([c.x, c.y, saved[c][0], saved[c][1]])
	for c in mined:
		out.append([c.x, c.y, -1, 0])
	return out

func from_array(a: Array) -> void:
	mined = {}
	saved = {}
	for e in a:
		if not (e is Array) or e.size() < 4:
			continue
		var c := Vector2i(int(e[0]), int(e[1]))
		if int(e[2]) < 0:
			mined[c] = true
		else:
			saved[c] = [int(e[2]), int(e[3])]
		if nodes.has(c):   # already registered (homestead): apply now
			if int(e[2]) < 0:
				nodes.erase(c)
			else:
				nodes[c].hp = clampi(int(e[2]), 1, HP[nodes[c].kind])
				nodes[c].stump_days = clampi(int(e[3]), 0, REGROW_DAYS)
				saved.erase(c)

var seen: Dictionary = {}   # streamed cells already registered (a mined rock must not respawn on reload)

func add_once(kind: String, cell: Vector2i) -> void:
	if seen.has(cell) or nodes.has(cell):
		return
	seen[cell] = true
	add(kind, cell)

func is_solid(cell: Vector2i) -> bool:
	return nodes.has(cell) and nodes[cell].stump_days == 0

func hit(cell: Vector2i, tool: String, power: int = 1) -> Dictionary:
	## Returns {} on no effect, {"hit":true} on damage, {"id","n"} when broken.
	if not is_solid(cell) or TOOL[nodes[cell].kind] != tool:
		return {}
	var n = nodes[cell]
	n.hp -= maxi(power, 1)
	if n.hp > 0:
		return {"hit": true, "hp": n.hp}
	var d: Array = DROPS[n.kind]
	if n.kind == "tree":
		n.stump_days = REGROW_DAYS
	else:
		nodes.erase(cell)
		mined[cell] = true
	return {"id": d[0], "n": d[1]}

func next_day() -> void:
	for c in nodes:
		var n = nodes[c]
		if n.stump_days > 0:
			n.stump_days -= 1
			if n.stump_days == 0:
				n.hp = HP[n.kind]
