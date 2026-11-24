class_name DerbyModel
extends RefCounted
## Pure rules for the animal derby: 4 runners over a straight, hold to gallop (faster but drains stamina), release to trot and recover.
## A winded runner crawls until stamina recovers past WIND_OK.

const TRACK := 400.0          # distance units to the finish
const FEE := 20
const TROT := 40.0
const GALLOP := 56.0
const DRAIN := 0.24           # stamina per second while galloping
const REGEN := 0.16           # stamina per second while trotting
const WIND_OK := 0.35
const WINDED_MULT := 0.55
const PRIZES := [150, 60, 25, 0]

static func runner(speed_bonus: float = 0.0) -> Dictionary:
	return {"pos": 0.0, "stamina": 1.0, "winded": false, "bonus": speed_bonus, "done": -1.0}

static func speed(r: Dictionary, gallop: bool) -> float:
	var base := GALLOP if (gallop and not r["winded"]) else TROT
	if r["winded"]:
		base = TROT * WINDED_MULT
	return base * (1.0 + float(r["bonus"]))

static func step(r: Dictionary, gallop: bool, dt: float) -> void:
	var g: bool = gallop and not r["winded"]
	r["pos"] = float(r["pos"]) + speed(r, gallop) * dt
	var s := float(r["stamina"]) + (-DRAIN if g else REGEN) * dt
	r["stamina"] = clampf(s, 0.0, 1.0)
	if float(r["stamina"]) <= 0.0:
		r["winded"] = true
	elif r["winded"] and float(r["stamina"]) >= WIND_OK:
		r["winded"] = false

## Rival AI: gallops while stamina is above a threshold that depends on skill 0..1.
static func rival_gallops(r: Dictionary, skill: float) -> bool:
	if r["winded"]:
		return false
	return float(r["stamina"]) > lerpf(0.55, 0.12, clampf(skill, 0.0, 1.0))

## Slipstream: tucked 3-18 units behind another runner gives up to +7% speed (fades with the gap).
static func draft_mult(gap: float) -> float:
	if gap < 3.0 or gap > 18.0:
		return 1.0
	return 1.0 + 0.07 * (1.0 - (gap - 3.0) / 15.0)

static func nearest_ahead_gap(poss: Array, i: int) -> float:
	var best := 1e9
	for j in poss.size():
		var g := float(poss[j]) - float(poss[i])
		if j != i and g > 0.0 and g < best:
			best = g
	return best

static func finished(r: Dictionary) -> bool:
	return float(r["pos"]) >= TRACK

## Place (0 = first) of runner i given finish times (-1 = not finished -> ranked by position).
static func place(poss: Array, times: Array, i: int) -> int:
	var p := 0
	for j in poss.size():
		if j == i:
			continue
		var ti := float(times[i])
		var tj := float(times[j])
		if ti >= 0.0 and tj >= 0.0:
			if tj < ti:
				p += 1
		elif tj >= 0.0:
			p += 1
		elif ti < 0.0 and float(poss[j]) > float(poss[i]):
			p += 1
	return p

static func prize(place_idx: int) -> int:
	return PRIZES[clampi(place_idx, 0, PRIZES.size() - 1)]

## Mount quality: bond 0..100 and gear speed add up to a small bonus (max +12%).
static func bonus_for(bond: int, gear_speed: float = 0.0) -> float:
	return clampf(float(bond) / 100.0 * 0.08 + gear_speed, 0.0, 0.12)
