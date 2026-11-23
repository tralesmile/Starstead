class_name BusinessModel
extends RefCounted
## Own business: the Port Halden cafe franchise. Buy the deed, hire up to level 3 (more tables, a barista, a bakery),
## and every night it earns a small deterministic profit into the till; walk in and collect (the till holds at most
## CAP_DAYS of takings, so passive income needs visits).

const PRICES := [1200, 1800, 3000]          # deed (level 1), then the upgrades to level 2 and 3
const PROFIT := [0, 55, 120, 210]            # base takings per night by level
const CAP_DAYS := 7
const MIN_HONEST_REP := 3                    # the bank wants a clean name for the loan paperwork
const MAX_LEVEL := 3

var level := 0
var till := 0
var total_earned := 0

static func night_profit(lvl: int, day: int, rain: bool = false) -> int:
	## Deterministic +-15% wobble, +20% on weekend days (day % 7 in 5..6), -10% when it rained.
	if lvl <= 0:
		return 0
	var base := float(PROFIT[clampi(lvl, 0, MAX_LEVEL)])
	var wobble := 1.0 + (float(absi(hash("cafe:" + str(day))) % 7 - 3) / 3.0) * 0.15
	var weekend := 1.2 if day % 7 >= 5 else 1.0
	return int(round(base * wobble * weekend * (0.9 if rain else 1.0)))

func next_cost() -> int:
	return PRICES[level] if level < MAX_LEVEL else 0

func can_buy(cash: int, honest_rep: int) -> String:
	## "" when allowed, else a short reason.
	if level >= MAX_LEVEL:
		return "maxed"
	if level == 0 and honest_rep < MIN_HONEST_REP:
		return "rep"
	if cash < next_cost():
		return "cash"
	return ""

func buy(cash: int, honest_rep: int) -> Dictionary:
	var why := can_buy(cash, honest_rep)
	if why != "":
		return {"ok": false, "why": why, "cash": cash}
	var cost := next_cost()
	level += 1
	return {"ok": true, "why": "", "cash": cash - cost, "level": level}

func day_tick(day: int, rain: bool = false) -> int:
	var p := night_profit(level, day, rain)
	var room := maxi(0, PROFIT[level] * 2 * CAP_DAYS - till)   # cap scales with the level's top takings
	var add := mini(p, room)
	till += add
	total_earned += add
	return add

func collect(cash: int) -> Dictionary:
	var got := till
	till = 0
	return {"cash": cash + got, "got": got}

func name_for_level() -> String:
	return ["No franchise", "Corner Cafe", "Busy Bistro", "Halden Grand Cafe"][clampi(level, 0, MAX_LEVEL)]

func to_dict() -> Dictionary:
	return {"level": level, "till": till, "total": total_earned}

func from_dict(d: Dictionary) -> void:
	level = clampi(int(d.get("level", 0)), 0, MAX_LEVEL)
	till = maxi(0, int(d.get("till", 0)))
	total_earned = maxi(0, int(d.get("total", 0)))
