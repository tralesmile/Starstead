class_name RaceModel
extends RefCounted
## Pure race rules: checkpoints, lap timing, ranking by progress, payout by place, best-time record.

var checkpoints: Array = []  # Vector2 positions, visited in order; last one closes the lap
var laps := 1
var radius := 24.0
var payouts: Array = [200, 100, 50]
var best_time := -1.0
var racers := {}  # id -> {"cp": int (next checkpoint), "lap": int, "t": float, "lap_start": float, "finish": float, "best_lap": float}
var clock := 0.0

func _init(cps: Array = [], lap_count: int = 1, hit_radius: float = 24.0) -> void:
	checkpoints = cps
	laps = lap_count
	radius = hit_radius

func add_racer(id: String) -> void:
	racers[id] = {"cp": 0, "lap": 0, "lap_start": 0.0, "finish": -1.0, "best_lap": -1.0, "dist": 0.0}

func start() -> void:
	clock = 0.0
	for id in racers:
		add_racer(id)

func is_finished(id: String) -> bool:
	return float(racers[id]["finish"]) >= 0.0

## Advance the clock and test racer position against its next checkpoint. Returns true if a checkpoint was hit.
func update(id: String, pos: Vector2, now: float) -> bool:
	clock = maxf(clock, now)
	var r: Dictionary = racers[id]
	if is_finished(id) or checkpoints.is_empty():
		return false
	var target: Vector2 = checkpoints[r["cp"]]
	r["dist"] = pos.distance_to(target)
	if r["dist"] > radius:
		return false
	r["cp"] = int(r["cp"]) + 1
	if int(r["cp"]) >= checkpoints.size():
		r["cp"] = 0
		r["lap"] = int(r["lap"]) + 1
		var lt: float = now - float(r["lap_start"])
		r["lap_start"] = now
		if float(r["best_lap"]) < 0.0 or lt < float(r["best_lap"]):
			r["best_lap"] = lt
		if int(r["lap"]) >= laps:
			r["finish"] = now
			record_time(now)
	return true

## Returns true when t is a new best.
func record_time(t: float) -> bool:
	if best_time < 0.0 or t < best_time:
		best_time = t
		return true
	return false

## Progress: completed checkpoints, minus a fraction for distance to the next one (0..1 scale).
func progress(id: String) -> float:
	var r: Dictionary = racers[id]
	if is_finished(id):
		return 1.0e9 - float(r["finish"])  # earlier finish ranks higher
	var done := int(r["lap"]) * checkpoints.size() + int(r["cp"])
	return float(done) + 1.0 / (1.0 + float(r["dist"]) / 100.0) * 0.5

## Racer ids, best first.
func ranking() -> Array:
	var ids: Array = racers.keys()
	ids.sort_custom(func(a, b): return progress(a) > progress(b))
	return ids

## 1-based place, or 0 if unknown.
func place(id: String) -> int:
	return ranking().find(id) + 1

func payout_for_place(p: int) -> int:
	if p < 1 or p > payouts.size():
		return 0
	return int(payouts[p - 1])

func serialize() -> Dictionary:
	return {"best_time": best_time}

func load_data(d: Dictionary) -> void:
	best_time = float(d.get("best_time", -1.0))

## n checkpoints on a ring around `center` (px); each is moved to the nearest drivable spot via ok(cell)->bool.
static func ring_checkpoints(center: Vector2, ring_r: float, n: int, ok: Callable) -> Array:
	var out: Array = []
	for i in n:
		var a := TAU * float(i) / float(n)
		var want := center + Vector2(cos(a), sin(a)) * ring_r
		var found := want
		var hit := false
		for step in range(0, 12):
			for k in 8:
				var q := want + Vector2.from_angle(TAU * k / 8.0) * 32.0 * step
				if ok.call(Vector2i(floori(q.x / 32.0), floori(q.y / 32.0))):
					found = (Vector2(floori(q.x / 32.0), floori(q.y / 32.0)) + Vector2(0.5, 0.5)) * 32.0
					hit = true
					break
			if hit:
				break
		out.append(found)
	return out

## Rival AI: drives straight at its next checkpoint at `spd` px/s; returns the new position.
static func ai_step(pos: Vector2, target: Vector2, spd: float, dt: float) -> Vector2:
	return pos.move_toward(target, spd * dt)

## Index of the start gate within `radius` px of pos (the nearest), or -1.
static func gate_near(pos: Vector2, gates: Array, radius: float = 110.0) -> int:
	var best := -1
	var bd := radius
	for i in gates.size():
		var d := pos.distance_to(gates[i])
		if d <= bd:
			bd = d
			best = i
	return best
