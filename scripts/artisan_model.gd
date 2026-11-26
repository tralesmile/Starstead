class_name ArtisanModel
extends RefCounted
## Barn artisan machines (data/artisan.json): load raw goods, wait some nights, collect something worth about twice as much.
## Pure state: slot id -> {out, days_left}. Silver/gold crops are accepted but plain ones are used up first.

const SUFFIXES := ["", "_silver", "_gold"]

var machines: Dictionary
var slots: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
	machines = data.get("machines", {})

func has_machine(slot: String) -> bool:
	return machines.has(slot)

func _def(slot: String) -> Dictionary:
	var m: Dictionary = machines.get(slot, {})
	return machines.get(String(m["kind"]), {}) if m.has("kind") else m

func recipes(slot: String) -> Array:
	return _def(slot).get("recipes", [])

func label(slot: String) -> String:
	return String(machines.get(slot, {}).get("name", slot))

func busy(slot: String) -> bool:
	return slots.has(slot)

func ready(slot: String) -> bool:
	return slots.has(slot) and int(slots[slot]["days_left"]) <= 0

static func have(bag: Inventory, base: String) -> int:
	var n := 0
	for s in SUFFIXES:
		n += bag.count(base + s)
	return n

static func _take(bag: Inventory, base: String, n: int) -> void:
	for s in SUFFIXES:
		var k := mini(n, bag.count(base + s))
		if k > 0:
			bag.remove(base + s, k)
			n -= k
		if n <= 0:
			return

func best_recipe(slot: String, bag: Inventory) -> Dictionary:
	## The first recipe in data order that the bag can pay for (the list is ordered most valuable first).
	for r in recipes(slot):
		if have(bag, String(r["in"])) >= int(r["count"]):
			return r
	return {}

func load_machine(slot: String, bag: Inventory) -> Dictionary:
	## Returns the recipe started, or {} if the machine is full or nothing fits.
	if busy(slot):
		return {}
	var r := best_recipe(slot, bag)
	if r.is_empty():
		return {}
	_take(bag, String(r["in"]), int(r["count"]))
	slots[slot] = {"out": String(r["out"]), "days_left": int(r["days"])}
	return r

func collect(slot: String, bag: Inventory) -> String:
	## The product id, or "" if not ready or the bag is full (it then stays in the machine).
	if not ready(slot):
		return ""
	var out := String(slots[slot]["out"])
	if bag.add(out, 1) > 0:
		return ""
	slots.erase(slot)
	return out

func day_tick() -> int:
	## One night passes. Returns how many machines became ready.
	var n := 0
	for s in slots:
		var left := int(slots[s]["days_left"])
		if left > 0:
			slots[s]["days_left"] = left - 1
			if left == 1:
				n += 1
	return n

func prompt(slot: String, bag: Inventory, items: Dictionary) -> String:
	if ready(slot):
		return "E: Collect %s" % String(items.get(slots[slot]["out"], {}).get("name", slots[slot]["out"]))
	if busy(slot):
		var d := int(slots[slot]["days_left"])
		return "%s: %s ready in %d night%s" % [label(slot), String(items.get(slots[slot]["out"], {}).get("name", "")).to_lower(), d, "" if d == 1 else "s"]
	var r := best_recipe(slot, bag)
	if r.is_empty():
		var wants: Array[String] = []
		for q in recipes(slot):
			var nm := String(items.get(q["in"], {}).get("name", q["in"])).to_lower()
			wants.append(("%d %s" % [int(q["count"]), nm]) if int(q["count"]) > 1 else nm)
		if wants.size() > 3:
			return "%s: needs %s or another crop" % [label(slot), ", ".join(wants.slice(0, 3))]
		return "%s: needs %s" % [label(slot), " or ".join(wants)]
	return "E: Load %s (%d %s)" % [label(slot).to_lower(), int(r["count"]), String(items.get(r["in"], {}).get("name", r["in"])).to_lower()]

func to_dict() -> Dictionary:
	return slots.duplicate(true)

func from_dict(d: Dictionary) -> void:
	slots = {}
	for s in d:
		if machines.has(s) and d[s] is Dictionary and d[s].has("out"):
			slots[str(s)] = {"out": str(d[s]["out"]), "days_left": int(d[s].get("days_left", 0))}
