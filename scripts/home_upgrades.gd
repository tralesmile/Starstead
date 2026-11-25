class_name HomeUpgrades
extends RefCounted
## Pure money sink: the Town Hall builder sells farmhouse upgrades in tiers (data/home_upgrades.json).
## Effects: bag slots, kitchen energy multiplier, cellar sell multiplier.

var defs: Dictionary
var levels: Dictionary = {}   # id -> tier owned (0..costs.size())

func _init(d: Dictionary = {}) -> void:
	defs = d if not d.is_empty() else DataDB.load_json("home_upgrades")

func ids() -> Array:
	return defs.keys()

func max_level(id: String) -> int:
	return Array(defs[id]["costs"]).size()

func level(id: String) -> int:
	return int(levels.get(id, 0))

func next_cost(id: String) -> int:
	var l := level(id)
	return -1 if l >= max_level(id) else int(defs[id]["costs"][l])

func value(id: String) -> float:
	var l := level(id)
	return float(defs[id]["base"]) if l == 0 else float(defs[id]["values"][l - 1])

func can_buy(id: String, cash: int) -> String:
	## "" when buyable, else "maxed", "cash" or "unknown".
	if not defs.has(id):
		return "unknown"
	if level(id) >= max_level(id):
		return "maxed"
	return "cash" if cash < next_cost(id) else ""

func buy(id: String, cash: int) -> Dictionary:
	var why := can_buy(id, cash)
	if why != "":
		return {"ok": false, "why": why, "cash": cash}
	var cost := next_cost(id)
	levels[id] = level(id) + 1
	return {"ok": true, "why": "", "cash": cash - cost, "level": level(id)}

func bag_slots() -> int:
	return int(value("bag"))

func eat_mult() -> float:
	return value("kitchen")

func sell_mult() -> float:
	return value("cellar")

func total_spent() -> int:
	var t := 0
	for id in defs:
		for i in level(id):
			t += int(defs[id]["costs"][i])
	return t

func label(id: String) -> String:
	## "Pack straps  2/2  (50 slots)"
	var d: Dictionary = defs[id]
	return "%s  %d/%d  (%s)" % [d["name"], level(id), max_level(id), String(d["fmt"]) % (int(value(id)) if String(d["fmt"]).contains("%d") else value(id))]

func to_dict() -> Dictionary:
	return levels.duplicate()

func from_dict(d: Dictionary) -> void:
	levels = {}
	for k in d:
		if defs.has(str(k)):
			levels[str(k)] = clampi(int(d[k]), 0, max_level(str(k)))
