class_name HarbourState
extends RefCounted
## Pure per-session state of the harbour: the weekly fishing contest entry and the night crate pickup.
## Callers pass day/hour/money so no autoload is touched. Results are dictionaries.

var contest_day := -1
var score := 0
var catches := 0
var crate_day := -1

func entered(day: int) -> bool:
	return contest_day == day

func enter(day: int, hour: float, money: int) -> Dictionary:
	if not HarbourModel.contest_open(day, hour):
		return {"ok": false, "money": money, "msg": "The contest is not open"}
	if entered(day):
		return {"ok": false, "money": money, "msg": "You are already entered"}
	if money < HarbourModel.ENTRY_FEE:
		return {"ok": false, "money": money, "msg": "Entry costs $%d" % HarbourModel.ENTRY_FEE}
	contest_day = day
	score = 0
	catches = 0
	return {"ok": true, "money": money - HarbourModel.ENTRY_FEE, "msg": "Entered! Longest catches in sea water count until 18:00"}

func add_catch(day: int, hour: float, cm: int) -> bool:
	## Only sea catches during the open contest count (the caller checks the sea).
	if not entered(day) or not HarbourModel.contest_open(day, hour):
		return false
	score += cm
	catches += 1
	return true

func finish(day: int, hour: float) -> Dictionary:
	## Settles the entry once the contest is over (or at the board after 18:00). Resets the entry.
	if not entered(day) or HarbourModel.contest_open(day, hour):
		return {"done": false}
	var rv := HarbourModel.rival_scores(day)
	var r := HarbourModel.rank(score, rv)
	var res := {"done": true, "rank": r, "prize": HarbourModel.prize(r), "score": score, "rivals": rv}
	contest_day = -1
	score = 0
	catches = 0
	return res

func can_take_crate(day: int, hour: float) -> bool:
	return HarbourModel.crate_available(day, hour) and crate_day != day

func take_crate(day: int, hour: float) -> bool:
	if not can_take_crate(day, hour):
		return false
	crate_day = day
	return true

func to_dict() -> Dictionary:
	return {"contest_day": contest_day, "score": score, "catches": catches, "crate_day": crate_day}

func from_dict(d: Dictionary) -> void:
	contest_day = int(d.get("contest_day", -1))
	score = int(d.get("score", 0))
	catches = int(d.get("catches", 0))
	crate_day = int(d.get("crate_day", -1))
