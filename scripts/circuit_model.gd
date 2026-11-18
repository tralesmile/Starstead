class_name CircuitModel
extends RefCounted
## Pure layout of the Halden race circuit + sports park (docs/EARTH_MAP.md E6), world cells (homestead chunk = 0..63).
## Chunk (1,6): a forced-land rectangle with an oval asphalt track (driven clockwise from the start line at the
## south straight), an infield with the pit office, the Sports Hall and a football pitch, a grandstand outside.

const RECT := Rect2i(-124, 136, 56, 48)          # x -124..-69, y 136..183 forced to land
const CENTER := Vector2(-96.0, 160.0)
const A := 22.0                                   # semi-axes of the track centre line (cells)
const B := 15.0
const HALF_W := 2.0                               # half track width (cells)
const PITCH_CELL := Vector2i(-110, 164)           # top-left of the 6x4-cell football pitch
const GOAL_CELL := Vector2i(-107, 164)            # penalty spot interactable (goal on the pitch's north edge)
const START_CELL := Vector2i(-96, 175)
const LICENCE_PRICE := 150
const PRIZE_MULT := 3
const N_CP := 12

static func in_rect(c: Vector2i) -> bool:
	return RECT.has_point(c)

static func _d(c: Vector2i) -> float:
	## Normalised ellipse distance of a cell centre: 1.0 on the centre line.
	var dx := (float(c.x) + 0.5 - CENTER.x) / A
	var dy := (float(c.y) + 0.5 - CENTER.y) / B
	return sqrt(dx * dx + dy * dy)

static func is_track(c: Vector2i) -> bool:
	return in_rect(c) and absf(_d(c) - 1.0) * (A + B) * 0.5 <= HALF_W

static func is_infield(c: Vector2i) -> bool:
	return in_rect(c) and not is_track(c) and _d(c) < 1.0

static func is_kerb(c: Vector2i) -> bool:
	## Track cell that touches grass: gets a red/white rumble strip.
	if not is_track(c):
		return false
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not is_track(c + o):
			return true
	return false

static func on_circuit(c: Vector2i) -> bool:
	return is_track(c) or is_infield(c)

static func point_at(theta: float) -> Vector2:
	## Centre-line point in cells at angle theta (0 = start line on the south straight, then west: clockwise on screen).
	return Vector2(CENTER.x - A * sin(theta), CENTER.y + B * cos(theta))

static func checkpoints(n: int = N_CP) -> Array:
	## Pixel positions of the checkpoints; the last one is the start/finish line.
	var out: Array = []
	for i in n:
		out.append(point_at(TAU * float(i + 1) / float(n)) * 32.0 + Vector2(16, 16) - Vector2(16, 16))
	return out

static func start_px() -> Vector2:
	return point_at(0.0) * 32.0

static func grid_slots(k: int) -> Vector2:
	## Starting grid behind the line (east of it, since the cars head west): slot 0 = pole.
	var lane := -16.0 if k % 2 == 0 else 16.0
	return start_px() + Vector2(28.0 + 30.0 * k, lane)

static func _b(id: String, sprite: String, x: int, y: int, w: int, door_px: int, name: String, kind: String) -> Dictionary:
	return {"id": id, "sprite": sprite, "cell": Vector2i(x, y), "w": w, "door": Vector2i(x + door_px / 32, y + 2), "name": name, "door_px": door_px, "kind": kind}

static func buildings() -> Array:
	return [
		_b("circ_pit", "pit_building", -108, 150, 4, 32, "Pit office", "pit"),
		_b("circ_hall", "sports_hall", -101, 150, 5, 64, "Halden Sports Hall", "sports"),
	]

static func kind_of(building_id: String) -> String:
	for b in buildings():
		if b["id"] == building_id:
			return String(b["kind"])
	return ""

static func props() -> Array:
	return [
		{"kind": "grandstand", "cell": Vector2i(-96, 181)},
		{"kind": "gantry", "cell": Vector2i(-96, 178)},
		{"kind": "tyres", "cell": Vector2i(-99, 172)},
		{"kind": "tyres", "cell": Vector2i(-93, 172)},
		{"kind": "tyres", "cell": Vector2i(-122, 160)},
		{"kind": "flag", "cell": Vector2i(-94, 178)},
		{"kind": "goal", "cell": GOAL_CELL},
		{"kind": "goal", "cell": GOAL_CELL + Vector2i(1, 0)},
	]

static func licence_ok(has_licence: bool, money: int) -> Dictionary:
	## Buying the circuit licence at the pit office.
	if has_licence:
		return {"ok": false, "why": "owned", "cash": money}
	if money < LICENCE_PRICE:
		return {"ok": false, "why": "broke", "cash": money}
	return {"ok": true, "why": "", "cash": money - LICENCE_PRICE}

static func prize(place: int, laps: int, payouts: Array) -> int:
	if place < 1 or place > payouts.size():
		return 0
	return int(payouts[place - 1]) * laps * PRIZE_MULT
