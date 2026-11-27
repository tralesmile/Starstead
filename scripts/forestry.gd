class_name Forestry
extends RefCounted
## Pure tree-seed model: what a felled tree sheds, planted saplings, and the trees they grow into.
## Grown trees are ordinary ResourceNodes "tree" cells (chop/stump/regrow); we only remember where they are.

var data: Dictionary = {}   # forestry.json
var saplings: Dictionary = {}   # cell -> {"kind": "oak"/"pine", "age": int}
var grown: Dictionary = {}      # cell -> "oak"/"pine"
var rev := 0                    # bumps on every change so the view knows when to redraw

func _init(d: Dictionary = {}) -> void:
	data = d

func grow_days() -> int:
	return maxi(1, int(data.get("grow_days", 6)))

func kind_for_seed(item: String) -> String:
	var seeds: Dictionary = data.get("seeds", {})
	for k in seeds:
		if String(seeds[k]) == item:
			return k
	return ""

## Extra drops [{id, n}] of a felled tree of `kind`; rolls are 0..1.
func fell_drops(kind: String, seed_roll: float, sap_roll: float) -> Array:
	var out: Array = []
	var seeds: Dictionary = data.get("seeds", {})
	if seeds.has(kind) and seed_roll < float(data.get("seed_chance", 0.0)):
		out.append({"id": String(seeds[kind]), "n": 1})
	var chance := float(data.get("sap_chance", 0.0))
	if sap_roll < chance:
		out.append({"id": "sap", "n": 1 + int(sap_roll / chance * float(data.get("sap_max", 1)))})
	return out

## 0 sprout, 1 young, 2 nearly a tree.
static func stage(age: int, total: int) -> int:
	return clampi(int(float(age) * 3.0 / float(maxi(total, 1))), 0, 2)

## `blocked`: anything already on the cell (the caller knows about soil, props, buildings...); sdf keeps it on dry land.
static func can_plant(tile: int, sdf: float, blocked: bool) -> bool:
	return tile <= 2 and sdf > 1.0 and not blocked

func plant(cell: Vector2i, item: String) -> bool:
	var kind := kind_for_seed(item)
	if kind == "" or saplings.has(cell) or grown.has(cell):
		return false
	saplings[cell] = {"kind": kind, "age": 0}
	rev += 1
	return true

func days_left(cell: Vector2i) -> int:
	return maxi(1, grow_days() - int(saplings[cell].age)) if saplings.has(cell) else 0

## Overnight growth. Full-grown saplings become choppable trees unless `blocked.call(cell)` says the spot got built on.
func next_day(nodes: ResourceNodes, blocked: Callable = Callable()) -> int:
	var made := 0
	for c in saplings.keys():
		var s: Dictionary = saplings[c]
		s.age = mini(int(s.age) + 1, grow_days())
		if s.age >= grow_days() and not (blocked.is_valid() and blocked.call(c)):
			grown[c] = String(s.kind)
			saplings.erase(c)
			nodes.saved.erase(c)
			nodes.add("tree", c)
			made += 1
	rev += 1
	return made

## After a load: put grown trees back into ResourceNodes (which applies their saved damage/stump).
func register(nodes: ResourceNodes) -> void:
	for c in grown:
		if not nodes.nodes.has(c):
			nodes.add("tree", c)

func to_dict() -> Dictionary:
	var s: Array = []
	for c in saplings:
		s.append([c.x, c.y, saplings[c].kind, saplings[c].age])
	var g: Array = []
	for c in grown:
		g.append([c.x, c.y, grown[c]])
	return {"saplings": s, "grown": g}

func from_dict(d: Dictionary) -> void:
	saplings = {}
	grown = {}
	for e in d.get("saplings", []):
		saplings[Vector2i(int(e[0]), int(e[1]))] = {"kind": str(e[2]), "age": int(e[3])}
	for e in d.get("grown", []):
		grown[Vector2i(int(e[0]), int(e[1]))] = str(e[2])
	rev += 1
