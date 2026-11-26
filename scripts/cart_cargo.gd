class_name CartCargo
extends RefCounted
## The ore riding in the mine cart. One hold shared by every floor's cart: whatever the bag cannot take back stays
## in here (and in the save), so ore is never lost. Pure: the bag is passed in.

const CAPACITY := 60          # pieces
const FULL_WEIGHT := 100.0    # weight at which the physics load reaches 1.0
const ORES: Array[String] = ["gold_ore", "silver_ore", "iron_ore", "copper_ore", "coal"]   # loading order: best first
const WEIGHT := {"coal": 1.0, "copper_ore": 1.5, "iron_ore": 2.0, "silver_ore": 2.0, "gold_ore": 3.0}
const COLORS := {"coal": Color(0.15, 0.14, 0.2), "copper_ore": Color(0.76, 0.33, 0.12), "iron_ore": Color(0.5, 0.34, 0.34),
	"silver_ore": Color(0.52, 0.66, 0.86), "gold_ore": Color(0.9, 0.68, 0.08)}

var items: Dictionary = {}    # ore id -> pieces

func count() -> int:
	var c := 0
	for id in items:
		c += int(items[id])
	return c

func weight() -> float:
	var w := 0.0
	for id in items:
		w += float(WEIGHT[id]) * int(items[id])
	return w

func load_fraction() -> float:
	return clampf(weight() / FULL_WEIGHT, 0.0, 1.0)

func add(id: String, n: int) -> int:
	## Returns how many went in (ore only, up to CAPACITY).
	if not WEIGHT.has(id):
		return 0
	var put := clampi(n, 0, maxi(0, CAPACITY - count()))
	if put > 0:
		items[id] = int(items.get(id, 0)) + put
	return put

func load_from(bag: Inventory) -> int:
	var moved := 0
	for id in ORES:
		var put := add(id, bag.count(id))
		if put > 0:
			bag.remove(id, put)
			moved += put
	return moved

func unload_to(bag: Inventory) -> Dictionary:
	## What does not fit in the bag stays in the cart. Returns {"moved", "left"}.
	var moved := 0
	for id in items.keys():
		var n := int(items[id])
		var left := bag.add(id, n)
		moved += n - left
		_put(id, left)
	return {"moved": moved, "left": count()}

func spill(n: int) -> Dictionary:
	## Takes up to n pieces off the top of the heap (from the biggest pile each time). Returns id -> pieces.
	var out := {}
	for i in n:
		var top := ""
		for id in ORES:
			if int(items.get(id, 0)) > int(items.get(top, 0)):
				top = id
		if top == "":
			break
		_put(top, int(items[top]) - 1)
		out[top] = int(out.get(top, 0)) + 1
	return out

func _put(id: String, n: int) -> void:
	if n > 0:
		items[id] = n
	else:
		items.erase(id)

func heap(max_lumps: int = 14) -> Array[String]:
	## One ore id per drawn lump, mixed in proportion to the load; every ore aboard shows at least once.
	var out: Array[String] = []
	var total := count()
	if total <= 0:
		return out
	var lumps := mini(max_lumps, ceili(total / 2.0))
	var used := {}
	for i in lumps:
		var best := ""
		var best_need := -INF
		for id in ORES:
			if not items.has(id):
				continue
			var need := float(items[id]) / total * lumps - int(used.get(id, 0))
			if not used.has(id):
				need += lumps
			if need > best_need:
				best = id
				best_need = need
		used[best] = int(used.get(best, 0)) + 1
		out.append(best)
	return out

func serialize() -> Dictionary:
	return items.duplicate()

func deserialize(d: Variant) -> void:
	## Not capped: a save must give back everything it held.
	items.clear()
	if d is Dictionary:
		for id in d:
			if WEIGHT.has(id) and int(d[id]) > 0:
				items[id] = int(d[id])
