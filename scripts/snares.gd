class_name Snares
extends RefCounted
## Pure hunting snares (PLAN Hunting: traps): set on dry land, a catch waits overnight by habitat, emptied by hand.
## A sprung snare shows a bundle; bait (any grilled meat / vegetable) is not needed. snares[cell] = {"ready": Array, "habitat": String}.

const MAX_HELD := 2
const BREAK_AFTER := 6      # a snare that caught this many animals frays and breaks
var snares: Dictionary = {}

static func habitat_for(chunk: Vector2i) -> String:
	## Pine forest chunks (0..2, 2..4) trap game birds and hares; highlands (3..5, 0..2) goats are too big, so hares only.
	if chunk.x <= 2 and chunk.y >= 2 and chunk.y <= 4:
		return "forest"
	return "meadow"

static func catch_for(roll: float, habitat: String) -> Array:
	## Item ids caught for roll in 0..1 (an empty array = the hare slipped out).
	if habitat == "forest":
		if roll < 0.15:
			return []
		if roll < 0.55:
			return ["raw_meat", "hide"]
		if roll < 0.85:
			return ["raw_meat", "feather"]
		return ["raw_meat", "raw_meat", "hide"]
	if roll < 0.3:
		return []
	if roll < 0.8:
		return ["raw_meat"]
	return ["raw_meat", "hide"]

static func can_place(sdf: float, blocked: bool) -> bool:
	## Dry ground at least one tile from the water, nothing built or growing there.
	return sdf > 1.0 and not blocked

func place(cell: Vector2i, sdf: float, habitat: String, blocked: bool = false) -> bool:
	if not can_place(sdf, blocked) or snares.has(cell):
		return false
	snares[cell] = {"ready": [], "habitat": habitat, "uses": 0}
	return true

func night_tick(rng: RandomNumberGenerator, raining: bool) -> int:
	## Rain washes the scent away: half the chance. Returns how many snares caught something.
	var n := 0
	var broken: Array = []
	for c in snares:
		var s: Dictionary = snares[c]
		if not (s["ready"] as Array).is_empty():
			continue
		if rng.randf() < (0.35 if raining else 0.7):
			var got := catch_for(rng.randf(), String(s["habitat"]))
			if not got.is_empty():
				s["ready"] = got
				s["uses"] = int(s["uses"]) + 1
				n += 1
	return n

func is_ready(cell: Vector2i) -> bool:
	return snares.has(cell) and not (snares[cell]["ready"] as Array).is_empty()

func collect(cell: Vector2i) -> Array:
	## Returns the items and re-sets the snare; a worn-out snare is removed (its cell is then free).
	if not is_ready(cell):
		return []
	var out: Array = (snares[cell]["ready"] as Array).duplicate()
	snares[cell]["ready"] = []
	if int(snares[cell]["uses"]) >= BREAK_AFTER:
		snares.erase(cell)
	return out

func worn(cell: Vector2i) -> bool:
	return snares.has(cell) and int(snares[cell]["uses"]) >= BREAK_AFTER - 1

func pick_up(cell: Vector2i) -> bool:
	## Only an empty snare can be picked up; a sprung one must be emptied first.
	return snares.has(cell) and not is_ready(cell) and snares.erase(cell)

func to_array() -> Array:
	var out := []
	for c in snares:
		out.append({"x": c.x, "y": c.y, "ready": snares[c]["ready"], "habitat": snares[c]["habitat"], "uses": snares[c]["uses"]})
	return out

func from_array(a: Array) -> void:
	snares = {}
	for e in a:
		var r: Array = []
		for x in e.get("ready", []):
			r.append(str(x))
		snares[Vector2i(int(e.x), int(e.y))] = {"ready": r, "habitat": str(e.get("habitat", "meadow")), "uses": int(e.get("uses", 0))}
