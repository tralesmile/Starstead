class_name CrabPots
extends RefCounted
## Pure crab pots: placed on shallow water, fill overnight, emptied by hand. pots[cell] = {"ready": Array of item ids}.

const MAX_HELD := 3
var pots: Dictionary = {}

static func catch_for(roll: float, deep: bool) -> String:
	## Deeper water gives better pickings. roll in 0..1.
	if deep:
		return "carp" if roll < 0.25 else ("crab" if roll < 0.75 else "perch")
	return "minnow" if roll < 0.3 else ("crab" if roll < 0.8 else "perch")

func place(cell: Vector2i, sdf: float) -> bool:
	## Needs water at least half a tile deep so it floats, and no other pot there.
	if sdf > -0.5 or pots.has(cell):
		return false
	pots[cell] = {"ready": [], "deep": sdf < -3.0}
	return true

func day_tick(rng: RandomNumberGenerator) -> int:
	var n := 0
	for c in pots:
		var p: Dictionary = pots[c]
		if (p["ready"] as Array).size() < MAX_HELD and rng.randf() < 0.85:
			(p["ready"] as Array).append(catch_for(rng.randf(), bool(p["deep"])))
			n += 1
	return n

func is_ready(cell: Vector2i) -> bool:
	return pots.has(cell) and not (pots[cell]["ready"] as Array).is_empty()

func collect(cell: Vector2i) -> Array:
	## Empties the pot and returns the item ids; [] when there is nothing.
	if not pots.has(cell):
		return []
	var out: Array = (pots[cell]["ready"] as Array).duplicate()
	pots[cell]["ready"] = []
	return out

func pick_up(cell: Vector2i) -> bool:
	return pots.erase(cell)

func to_array() -> Array:
	var out := []
	for c in pots:
		out.append({"x": c.x, "y": c.y, "ready": pots[c]["ready"], "deep": pots[c]["deep"]})
	return out

func from_array(a: Array) -> void:
	pots = {}
	for e in a:
		var r: Array = []
		for x in e.get("ready", []):
			r.append(str(x))
		pots[Vector2i(int(e.x), int(e.y))] = {"ready": r, "deep": bool(e.get("deep", false))}
