class_name CarTheft
extends RefCounted
## Pure car-theft rules: parked cars along the Port Halden kerbs (a different set each day), hot-wiring odds by
## street skill and lock, the owner/alarm reaction, and what the garage chop shop pays for a hot car.

const REACH := 40.0
const ROWS := [-1, 1, -13 + 0, 12, 14]   # kerb rows along the E-W streets
const XS := [168, 172, 176, 180, 184, 188, 196, 200, 204, 208, 212, 216]
const LOCKS := ["basic", "alarmed", "hardened"]
const BASE := {"basic": 0.45, "alarmed": 0.3, "hardened": 0.15}
const VALUE := {"basic": 180, "alarmed": 320, "hardened": 520}

static func _h(a: int, b: int, c: int) -> int:
	return absi((a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) % 1000

## Cars parked today: [{id, cell, heading, paint, lock, value}], deterministic per day. About 40% of kerb slots hold a car.
static func slots(day: int) -> Array:
	var out: Array = []
	for r in ROWS:
		for x in XS:
			var h := _h(day, x, r)
			if h >= 400:
				continue
			var lock: String = LOCKS[0] if h < 240 else LOCKS[1] if h < 340 else LOCKS[2]
			out.append({"id": "pc_%d_%d" % [x, r], "cell": Vector2i(x, r), "heading": PI if r % 2 != 0 else 0.0,
				"paint": (h * 7) % 5, "lock": lock, "value": int(VALUE[lock])})
	return out

static func nearest(list: Array, pos: Vector2, taken: Array) -> Dictionary:
	var best := {}
	var bd := REACH
	for s in list:
		if taken.has(s["id"]):
			continue
		var d := pos.distance_to((Vector2(s["cell"]) + Vector2(0.5, 0.5)) * 32.0)
		if d < bd:
			bd = d
			best = s
	return best

static func hotwire_chance(street_level: int, lock: String) -> float:
	return clampf(float(BASE.get(lock, 0.3)) + 0.06 * float(street_level), 0.1, 0.9)

## One attempt: roll_a decides the hot-wire, roll_b the alarm (alarmed locks scream on a failure, hardened ones always).
static func attempt(street_level: int, lock: String, roll_a: float, roll_b: float) -> Dictionary:
	var ok := roll_a < hotwire_chance(street_level, lock)
	var alarm := false
	if not ok:
		alarm = lock == "hardened" or (lock == "alarmed" and roll_b < 0.7) or roll_b < 0.15
	elif lock == "alarmed":
		alarm = roll_b < 0.3
	return {"ok": ok, "alarm": alarm}

static func owner_sees(nearby_npcs: int, hour: float, roll: float) -> bool:
	var base := 0.25 + 0.2 * float(mini(nearby_npcs, 3))
	if hour >= 21.0 or hour < 5.0:
		base *= 0.5
	return roll < base

## Chop shop price: worth less when battered; none for a clean (not hot) car.
static func chop_price(value: int, health_frac: float) -> int:
	return int(round(float(value) * (0.35 + 0.4 * clampf(health_frac, 0.0, 1.0))))

static func chop_heat(hot_seen: bool) -> float:
	return 12.0 if hot_seen else 0.0
