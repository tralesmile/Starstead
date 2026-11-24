class_name Household
extends RefCounted
## Pure household routines for city homes: who sleeps, who is awake at home and who is out (data/households.json).
## Robbery uses it: sleepers wake by noise, awake residents notice you, empty homes only have neighbours to hear.

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = DataDB.load_json("households")
	return _cfg

static func members(building_id: String) -> Array:
	return cfg()["homes"].get(building_id, [])

static func state_at(routine: String, hour: float) -> String:
	## "sleep", "away" or "home" (awake in the house).
	var h := fposmod(hour, 24.0)
	for e in cfg()["routines"].get(routine, []):
		var f := float(e["from"])
		var t := float(e["to"])
		var hit := (h >= f and h < t) if f < t else (h >= f or h < t)
		if hit:
			return String(e["state"])
	return "home"

static func present(building_id: String, hour: float) -> Array:
	## Residents inside the house now: [{name, outfit, bed, spots, state: sleep|home, depth}]
	var out: Array = []
	for m in members(building_id):
		var st := state_at(String(m["routine"]), hour)
		if st == "away":
			continue
		var d: Dictionary = (m as Dictionary).duplicate()
		d["state"] = st
		d["depth"] = float(cfg()["sleep_depth"].get(String(m["routine"]), 1.0))
		out.append(d)
	return out

static func awake_home(building_id: String, hour: float) -> Array:
	return present(building_id, hour).filter(func(m): return m["state"] == "home")

static func lights_on(building_id: String, hour: float) -> bool:
	return not awake_home(building_id, hour).is_empty()

static func nobody_home(building_id: String, hour: float) -> bool:
	return members(building_id).size() > 0 and present(building_id, hour).is_empty()

static func wake_threshold(base: float, building_id: String, hour: float) -> float:
	## Noise needed to wake the house: light sleepers lower it, an empty house only has neighbours (higher).
	var p := present(building_id, hour)
	if members(building_id).is_empty():
		return base
	if p.is_empty():
		return base * float(cfg()["away_threshold_mult"])
	var best := 99.0
	for m in p:
		if m["state"] == "home":
			return base * 0.5   # someone awake hears everything
		best = minf(best, float(m["depth"]))
	return base * best

static func suspicion_rate(dist_cells: float, sneaking: bool) -> float:
	## Suspicion per second of an awake resident who can see you (1.0 = they raise the alarm).
	var c := cfg()
	var rng := float(c["sneak_range_cells"]) if sneaking else float(c["see_range_cells"])
	if dist_cells > rng:
		return -0.5   # relax out of sight
	var r := 1.0 / float(c["suspicion_secs"])
	return r * (float(c["sneak_suspicion_mult"]) if sneaking else 1.0) * (1.0 + (rng - dist_cells) / rng * 0.5)

static func spot_cell(layout: Dictionary, furniture_id: String) -> Vector2:
	## Pixel offset (inside the room, origin = room top-left) in front of a furniture piece; (-1,-1) if missing.
	for f in layout["furniture"]:
		if f["id"] == furniture_id:
			var c: Vector2i = f["cell"]
			var s: Vector2i = f["size"]
			return Vector2((c.x + s.x * 0.5) * 32.0, (c.y + s.y) * 32.0 + 14.0)
	return Vector2(-1, -1)

static func stand_pos(layout: Dictionary, m: Dictionary, hour: float) -> Vector2:
	## Where an awake resident idles: cycles through their spots every 2 hours.
	var spots: Array = m.get("spots", [])
	for k in spots.size():
		var i := (int(floor(hour / 2.0)) + k) % spots.size()
		var p := spot_cell(layout, String(spots[i]))
		if p.x >= 0.0:
			return p
	return Vector2(float(layout["w"]) * 16.0, float(layout["h"]) * 32.0 - 40.0)

static func window_lit(building_id: String, idx: int, n: int, hour: float) -> bool:
	## Is window idx of n lit? Only while somebody is awake at home; flats light a share of windows by how many are in.
	var ms := members(building_id).size()
	if ms == 0:
		return true
	var up := awake_home(building_id, hour).size()
	if up == 0:
		return false
	var lit := clampi(ceili(float(n) * float(up) / float(ms)), 1, n)
	return idx < lit

const SHOVE_REACH := 42.0
const SHOVE_EVERY := 1.4
const SHOVE_FORCE := 1.1
const SHOVE_ENERGY := 3.0

static func shove(dist_px: float, cooldown: float, dt: float) -> Dictionary:
	## A woken resident shoves the intruder out when within reach; returns {hit, cooldown}.
	var cd := maxf(cooldown - dt, 0.0)
	if dist_px <= SHOVE_REACH and cd <= 0.0:
		return {"hit": true, "cooldown": SHOVE_EVERY}
	return {"hit": false, "cooldown": cd}

static func greeting(name: String, grudge: bool, hour: float) -> String:
	## What an awake resident says when you talk to them (grudge after a robbery).
	if grudge:
		return "%s: You again! Get out before I call the police." % name
	if hour >= 19.0 or hour < 6.0:
		return "%s: It's late... but come in, I suppose." % name
	if hour < 11.0:
		return "%s: Morning! Mind the mat." % name
	return "%s: Oh, hello. Make yourself at home." % name
