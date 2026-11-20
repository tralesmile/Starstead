class_name YardHeist
extends RefCounted
## Pure rules for lifting Vance crates inside the rocket yard (open once the gate is). Each crate can be
## cleared once per week. Loot is deterministic per crate and week; it is theft, so it adds heat and street rep.
## `looted` maps crate index -> day it was last cleared.

const COOLDOWN_DAYS := 7
const LOOT := [
	{"item": "iron_bar", "n": 2, "cash": 90},
	{"item": "", "n": 0, "cash": 180},
	{"item": "copper_bar", "n": 2, "cash": 120},
]
const REP := 2

static func crate_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in VanceYard.props():
		if String(p["kind"]) == "crates":
			out.append(p["cell"] + Vector2i(0, 1))
	return out

static func ready(looted: Dictionary, idx: int, day: int) -> bool:
	return not looted.has(idx) or day - int(looted[idx]) >= COOLDOWN_DAYS

static func loot(idx: int, day: int) -> Dictionary:
	return LOOT[(idx * 3 + day / COOLDOWN_DAYS) % LOOT.size()]

static func days_left(looted: Dictionary, idx: int, day: int) -> int:
	if ready(looted, idx, day):
		return 0
	return COOLDOWN_DAYS - (day - int(looted[idx]))

static func nearest(pos: Vector2) -> int:
	## Index of the crate whose cell is closest to a world position (-1 when none within 3 cells).
	var best := -1
	var bd := 96.0
	var cs := crate_cells()
	for i in cs.size():
		var d := pos.distance_to(Vector2(cs[i]) * 32.0 + Vector2(16, 16))
		if d < bd:
			bd = d
			best = i
	return best
