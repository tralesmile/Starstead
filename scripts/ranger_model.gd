class_name RangerModel
extends RefCounted
## Pure hunting law (owner 2026-11-18: hunting licence / ranger heat). Small game is free for everyone.
## Big game (deer, boar) needs a licence sold at the Town Hall and has a daily bag limit. Poaching, or going over
## the limit, builds ranger heat; at 100 the ranger collects a fine and takes hides. Heat cools each night.

const PROTECTED := ["deer", "boar"]
const LICENCE_COST := 120
const LICENCE_DAYS := 28        # one season
const BAG_LIMIT := 3            # protected animals per day with a licence
const POACH_HEAT := 45
const OVER_LIMIT_HEAT := 30
const FINE_AT := 100
const FINE := 150
const NIGHT_COOL := 20

var licence_until := -1         # last day the licence is valid (-1 = none)
var heat := 0
var taken_day := -1
var taken := 0                  # protected animals taken on taken_day

static func protected_species(id: String) -> bool:
	return id in PROTECTED

func licensed(day: int) -> bool:
	return day <= licence_until

func days_left(day: int) -> int:
	return maxi(0, licence_until - day + 1)

func buy(day: int, money: int) -> Dictionary:
	## {ok, cash, why}: renewing early adds a season on top of what is left.
	if money < LICENCE_COST:
		return {"ok": false, "cash": money, "why": "Needs $%d" % LICENCE_COST}
	if days_left(day) > LICENCE_DAYS:
		return {"ok": false, "cash": money, "why": "Already paid up"}
	licence_until = maxi(day - 1, licence_until) + LICENCE_DAYS
	return {"ok": true, "cash": money - LICENCE_COST, "why": ""}

func on_kill(species: String, day: int) -> Dictionary:
	## {legal, heat_added, fine_due, msg}. fine_due means the ranger collects now (heat resets).
	var out := {"legal": true, "heat_added": 0, "fine_due": false, "msg": ""}
	if not protected_species(species):
		return out
	if taken_day != day:
		taken_day = day
		taken = 0
	taken += 1
	var add := 0
	if not licensed(day):
		add = POACH_HEAT
		out["msg"] = "Poaching! %s needs a hunting licence (Town Hall)" % species.capitalize()
	elif taken > BAG_LIMIT:
		add = OVER_LIMIT_HEAT
		out["msg"] = "Over the daily limit of %d" % BAG_LIMIT
	else:
		out["msg"] = "Licensed kill %d/%d today" % [taken, BAG_LIMIT]
	if add > 0:
		out["legal"] = false
		out["heat_added"] = add
		heat += add
		if heat >= FINE_AT:
			heat = 0
			out["fine_due"] = true
	return out

static func fine_amount(money: int) -> int:
	return mini(FINE, maxi(0, money))

func new_day() -> void:
	heat = maxi(0, heat - NIGHT_COOL)

func to_dict() -> Dictionary:
	return {"licence_until": licence_until, "heat": heat, "taken_day": taken_day, "taken": taken}

func from_dict(d: Dictionary) -> void:
	licence_until = int(d.get("licence_until", -1))
	heat = clampi(int(d.get("heat", 0)), 0, FINE_AT)
	taken_day = int(d.get("taken_day", -1))
	taken = int(d.get("taken", 0))
