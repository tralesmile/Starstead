class_name ShopHours
extends RefCounted
## Opening hours of public buildings (data/hours.json). Closed doors can be picked; closed counters become a till to crack.
## Pure rules: no autoloads, so tests can run them.

const TILL_ACTIONS := ["shop", "bank", "coffee", "notice", "debt", "hoops", "ring", "licence"]
static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = DataDB.load_json("hours")
	return _cfg

static func has_hours(id: String) -> bool:
	return cfg().has(id) and id != "rules"

static func is_open(id: String, hour: float) -> bool:
	if not has_hours(id):
		return true   # police, hospital, your own buildings never close
	var e: Dictionary = cfg()[id]
	return hour >= float(e["open"]) and hour < float(e["close"])

static func hours_text(id: String) -> String:
	if not has_hours(id):
		return "open 24h"
	var e: Dictionary = cfg()[id]
	return "%d:00-%d:00" % [int(e["open"]), int(e["close"])]

static func lock_level(id: String) -> int:
	return int(cfg()[id]["lock"]) if has_hours(id) else 0

static func pick_chance(id: String, skill: int) -> float:
	var r: Dictionary = cfg()["rules"]
	var c := float(r["base_chance"]) - float(r["per_level"]) * lock_level(id) + float(r["per_skill"]) * skill
	return clampf(c, float(r["min"]), float(r["max"]))

static func alarm_chance(id: String) -> float:
	return float(cfg()[id]["alarm"]) if has_hours(id) else 0.0

static func till_cash(id: String, rng: RandomNumberGenerator) -> int:
	if not has_hours(id):
		return 0
	var t: Array = cfg()[id]["till"]
	return rng.randi_range(int(t[0]), int(t[1]))

## Counter action as seen right now: a closed counter turns into "till".
static func counter_action(id: String, action: String, hour: float) -> String:
	if action in TILL_ACTIONS and not is_open(id, hour):
		return "till"
	return action

## Today's break-in state: lock picked and till emptied, keyed by building id -> {"in": day, "till": day}.
static func broken_in(state: Dictionary, id: String, day: int) -> bool:
	return int(state.get(id, {}).get("in", -1)) == day

static func till_ready(state: Dictionary, id: String, day: int) -> bool:
	return int(state.get(id, {}).get("till", -1)) != day

static func mark(state: Dictionary, id: String, key: String, day: int) -> void:
	var e: Dictionary = state.get(id, {})
	e[key] = day
	state[id] = e
