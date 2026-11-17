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

func place_of(id: String) -> String:
	return String(jobs[id].get("place", ""))

## Human reason for a refused shift.
static func reason_text(why: String, job_name: String) -> String:
	match why:
		"hours": return "%s: not working hours" % job_name
		"rep": return "%s: your reputation is too low" % job_name
		"energy": return "%s: too tired" % job_name
	return "Cannot work"
