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
