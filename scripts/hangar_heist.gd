class_name HangarHeist
extends RefCounted
## Pure rules for the Vance hangar break-in (Act 2 finale heist): a 14x9-cell room guarded by three sweeping
## security cameras. Standing in a camera cone (not hidden behind crates) fills the detection meter; full = the
## alarm trips and you are thrown out empty-handed with heat. Crack the three cases (hold E) and walk out the door
## to bank the loot. One raid per week.

const W := 14
const H := 9
const CELL := 32.0
const COOLDOWN_DAYS := 7
const CRACK_TIME := 1.6         # seconds of holding E per case
const DETECT_RATE := 0.9        # meter/s in a cone
const DECAY_RATE := 0.5
const SNEAK_RATE := 0.55        # sneaking halves the build-up
const CASES := [
	{"cell": Vector2i(1, 1), "item": "", "n": 0, "cash": 400, "rep": 2},
	{"cell": Vector2i(12, 1), "item": "iron_bar", "n": 3, "cash": 120, "rep": 2},
	{"cell": Vector2i(6, 0), "item": "copper_bar", "n": 3, "cash": 250, "rep": 3},
]
const CRATES := [Rect2i(3, 3, 2, 1), Rect2i(9, 3, 2, 1), Rect2i(6, 5, 2, 1), Rect2i(1, 5, 1, 2), Rect2i(12, 5, 1, 2)]
## cameras: pivot (px), centre angle (rad), sweep amplitude (rad), period (s), phase, range (px), fov (rad)
const CAMS := [
	{"pos": Vector2(2.0 * CELL, 0.2 * CELL), "mid": 0.9, "amp": 0.6, "period": 6.0, "phase": 0.0, "range": 230.0, "fov": 0.7},
	{"pos": Vector2(12.0 * CELL, 0.2 * CELL), "mid": 2.25, "amp": 0.6, "period": 7.0, "phase": 1.7, "range": 230.0, "fov": 0.7},
	{"pos": Vector2(7.0 * CELL, 0.2 * CELL), "mid": 1.57, "amp": 0.75, "period": 5.0, "phase": 3.1, "range": 250.0, "fov": 0.6},
]
const DOOR_X := 6

static func ready(last_day: int, day: int) -> bool:
	return last_day < 0 or day - last_day >= COOLDOWN_DAYS

static func days_left(last_day: int, day: int) -> int:
	return 0 if ready(last_day, day) else COOLDOWN_DAYS - (day - last_day)

static func cam_angle(i: int, t: float) -> float:
	var c: Dictionary = CAMS[i]
	return float(c["mid"]) + float(c["amp"]) * sin(TAU * t / float(c["period"]) + float(c["phase"]))

static func crate_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in CRATES:
		out.append(Rect2(Vector2(r.position) * CELL, Vector2(r.size) * CELL))
	for c in CASES:
		out.append(Rect2(Vector2(c["cell"]) * CELL, Vector2(CELL, CELL)))
	return out

static func entrance() -> Vector2:
	return Vector2((DOOR_X + 0.5) * CELL, (H - 1) * CELL + 8.0)

static func at_door(p: Vector2) -> bool:
	return p.y > H * CELL - 6.0 and absf(p.x - (DOOR_X + 0.5) * CELL) < 24.0

static func hidden(from: Vector2, to: Vector2) -> bool:
	## True when a crate (not a case) blocks the straight line from a camera to the player.
	for r in CRATES:
		var rect := Rect2(Vector2(r.position) * CELL, Vector2(r.size) * CELL)
		if _seg_hits(from, to, rect):
			return true
	return false

static func _seg_hits(a: Vector2, b: Vector2, r: Rect2) -> bool:
	var steps := 24
	for i in steps + 1:
		if r.has_point(a.lerp(b, float(i) / steps)):
			return true
	return false

static func seen_by(i: int, t: float, p: Vector2) -> bool:
	var c: Dictionary = CAMS[i]
	var d: Vector2 = p - Vector2(c["pos"])
	if d.length() > float(c["range"]) or d.length() < 1.0:
		return false
	var diff := absf(angle_difference(d.angle(), cam_angle(i, t)))
	if diff > float(c["fov"]) * 0.5:
		return false
	return not hidden(Vector2(c["pos"]), p)

static func seen(t: float, p: Vector2) -> bool:
	for i in CAMS.size():
		if seen_by(i, t, p):
			return true
	return false

static func step_meter(meter: float, in_cone: bool, sneaking: bool, delta: float) -> float:
	if in_cone:
		return clampf(meter + (SNEAK_RATE if sneaking else DETECT_RATE) * delta, 0.0, 1.0)
	return clampf(meter - DECAY_RATE * delta, 0.0, 1.0)

static func case_near(p: Vector2) -> int:
	var best := -1
	var bd := 44.0
	for i in CASES.size():
		var d := p.distance_to((Vector2(CASES[i]["cell"]) + Vector2(0.5, 1.0)) * CELL)
		if d < bd:
			bd = d
			best = i
	return best

static func total_cash(opened: Array) -> int:
	var s := 0
	for i in opened:
		s += int(CASES[int(i)]["cash"])
	return s
