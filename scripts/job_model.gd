class_name JobModel
extends RefCounted
## Pure job rules: availability (hours, rep, energy), rank by xp, shift pay. Data from jobs.json.

var jobs: Dictionary

func _init(data: Dictionary) -> void:
	jobs = data

func ids() -> Array:
	return jobs.keys()

## Hours window may wrap past midnight (start > end).
func in_hours(id: String, hour: float) -> bool:
	var h: Dictionary = jobs[id]["hours"]
	var s := float(h["start"])
	var e := float(h["end"])
	var t := fposmod(hour, 24.0)
	if s <= e:
		return t >= s and t < e
	return t >= s or t < e

## rep: {"honest": int, "street": int}
func meets_rep(id: String, rep: Dictionary) -> bool:
	var r: Dictionary = jobs[id]["rep"]
	return int(rep.get(String(r["kind"]), 0)) >= int(r["min"])

func rank_index(id: String, xp: int) -> int:
	var idx := 0
	var ranks: Array = jobs[id]["ranks"]
	for i in ranks.size():
		if xp >= int(ranks[i]["xp"]):
			idx = i
	return idx

func rank_name(id: String, xp: int) -> String:
	return String(jobs[id]["ranks"][rank_index(id, xp)]["name"])

## XP still needed for next rank, or -1 at max rank.
func xp_to_next(id: String, xp: int) -> int:
	var i := rank_index(id, xp)
	var ranks: Array = jobs[id]["ranks"]
	if i >= ranks.size() - 1:
		return -1
	return int(ranks[i + 1]["xp"]) - xp

func shift_pay(id: String, xp: int) -> int:
	var j: Dictionary = jobs[id]
	var mult := float(j["ranks"][rank_index(id, xp)]["pay_mult"])
	return int(round(float(j["pay"]) * mult))

## "" when the shift can start, otherwise a reason: hours, rep, energy.
func can_work(id: String, hour: float, rep: Dictionary, energy: float) -> String:
	if not jobs.has(id):
		return "unknown"
	if not in_hours(id, hour):
		return "hours"
	if not meets_rep(id, rep):
		return "rep"
	if energy < float(jobs[id]["energy"]):
		return "energy"
	return ""

## Result of a shift: {ok, reason, pay, energy_cost, xp_gain, xp, promoted, rank}.
func work_shift(id: String, hour: float, rep: Dictionary, energy: float, xp: int) -> Dictionary:
	var why := can_work(id, hour, rep, energy)
	if why != "":
		return {"ok": false, "reason": why, "pay": 0, "energy_cost": 0, "xp_gain": 0, "xp": xp, "promoted": false, "rank": rank_name(id, xp) if jobs.has(id) else ""}
	var j: Dictionary = jobs[id]
	var pay := shift_pay(id, xp)
	var nxp := xp + int(j["xp_per_shift"])
	return {"ok": true, "reason": "", "pay": pay, "energy_cost": int(j["energy"]), "xp_gain": int(j["xp_per_shift"]),
		"xp": nxp, "promoted": rank_index(id, nxp) > rank_index(id, xp), "rank": rank_name(id, nxp)}

## Game minutes after a shift, never past the end of the day (so a shift cannot skip the night's pass-out).
func minutes_after_shift(id: String, minutes: float) -> float:
	return minf(minutes + float(jobs[id].get("shift_hours", 4)) * 60.0, float(GameClock.DAY_LENGTH_MIN) - 1.0)

## A job may need another job's xp first (astronaut trainee needs a Launch-pad career). {} when open.
func requirement(id: String) -> Dictionary:
	return jobs[id].get("requires", {})

func unlocked(id: String, job_xp: Dictionary) -> bool:
	var r := requirement(id)
	if r.is_empty():
		return true
	return int(job_xp.get(String(r["job"]), 0)) >= int(r["xp"])

## Extra reward per shift by job and rank: {item, qty, energy_back, rep_bonus}.
func perk(id: String, rank_idx: int) -> Dictionary:
	var out := {"item": "", "qty": 0, "energy_back": 0, "rep_bonus": 0, "car_fuel": 0.0, "car_health": 0.0, "ring_window": 0.0}
	match String(jobs[id].get("perk", "")):
		"food":
			out["item"] = "fried_egg" if rank_idx < 2 else "grilled_fish"
			out["qty"] = 1 + rank_idx
		"wood":
			out["item"] = "wood"
			out["qty"] = 2 + 2 * rank_idx
		"ore":
			out["item"] = ["coal", "copper_ore", "iron_ore"][clampi(rank_idx, 0, 2)]
			out["qty"] = 1 + rank_idx
		"heal":
			out["energy_back"] = 6 + 4 * rank_idx
		"wanted":
			out["rep_bonus"] = 1 + rank_idx
		"grounds":
			out["item"] = "fertiliser"
			out["qty"] = 2 + rank_idx
		"pit":   # the crew tops up your own car after the shift
			out["car_fuel"] = [0.35, 0.65, 1.0][clampi(rank_idx, 0, 2)]
			out["car_health"] = [25.0, 50.0, VehicleMath.HEALTH_MAX][clampi(rank_idx, 0, 2)]
		"spar":   # seconds added to the dodge window in your own boxing bouts
			out["ring_window"] = 0.05 + 0.04 * float(clampi(rank_idx, 0, 2))
	return out

## Passive ring training: nothing until you have worked a shift at a job with the "spar" perk.
func ring_bonus(job_xp: Dictionary) -> float:
	var best := 0.0
	for id in ids():
		var xp := int(job_xp.get(id, 0))
		if xp > 0:
			best = maxf(best, float(perk(id, rank_index(id, xp))["ring_window"]))
	return best

## Where you stand outside a building to work there: just below the middle of its front.
static func door_spot(b: Dictionary) -> Vector2:
	return TownModel.sprite_bottom_center(b) + Vector2(0, 14)

## Is the workplace in reach? `inside` is the room you are in ("" outdoors). Rooms live far from the door spots,
## so indoors only that public building's own jobs count (never from inside someone's home).
static func in_reach(place: String, inside: String, spots: Dictionary, pos: Vector2, radius: float = 60.0) -> bool:
	if inside != "":
		return place == inside and inside in InteriorModel.PUBLIC
	return spots.has(place) and (spots[place] as Vector2).distance_to(pos) < radius

## Another prompt (a door, room furniture) with the job prompt after it.
static func join_prompt(a: String, b: String) -> String:
	if a == "" or b == "":
		return a + b
	return a + "    " + b

## Car state after a pit perk: {fuel, health}, both capped at full.
static func service_car(fuel: float, health: float, p: Dictionary) -> Dictionary:
	return {"fuel": minf(VehicleMath.FUEL_MAX, fuel + VehicleMath.FUEL_MAX * float(p.get("car_fuel", 0.0))),
		"health": minf(VehicleMath.HEALTH_MAX, health + float(p.get("car_health", 0.0)))}

## One job to offer at a workplace: the first one you can work right now, else the first unlocked one that is
## in hours (so the refusal names the right reason), else the first unlocked, else "".
func pick_at(place: String, hour: float, rep: Dictionary, energy: float, job_xp: Dictionary) -> String:
	var first := ""
	var open_now := ""
	for id in ids():
		if place_of(id) != place or not unlocked(id, job_xp):
			continue
		if first == "":
			first = id
		if can_work(id, hour, rep, energy) == "":
			return id
		if open_now == "" and in_hours(id, hour):
			open_now = id
	return open_now if open_now != "" else first

func place_of(id: String) -> String:
	return String(jobs[id].get("place", ""))

## Human reason for a refused shift.
static func reason_text(why: String, job_name: String) -> String:
	match why:
		"hours": return "%s: not working hours" % job_name
		"rep": return "%s: your reputation is too low" % job_name
		"energy": return "%s: too tired" % job_name
	return "Cannot work"
