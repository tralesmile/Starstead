class_name StoryModel
extends RefCounted
## Pure quest chain for the story acts (data/story.json): quests run in order, each has ordered steps.
## A step completes on an event (notify), or when a poll condition holds (day_min, money_min, planted_min, debt_paid_min).

var quests: Array = []
var done: Dictionary = {}       # step id -> true
var debt_total := 2000
var debt_step := 250
var act := ""

func _init(data: Dictionary = {}) -> void:
	quests = data.get("quests", [])
	debt_total = int(data.get("debt_total", 2000))
	debt_step = int(data.get("debt_step", 250))
	act = str(data.get("act", ""))

func active() -> Dictionary:
	## {quest, step, index, total} of the first unfinished step, or {} when the act is complete.
	var idx := 0
	for q in quests:
		for s in q["steps"]:
			if not done.has(str(s["id"])):
				return {"quest": q, "step": s, "index": idx, "total": total_steps()}
			idx += 1
	return {}

func total_steps() -> int:
	var n := 0
	for q in quests:
		n += q["steps"].size()
	return n

func finished() -> bool:
	return active().is_empty()

func steps_done() -> int:
	return done.size()

func goal_text() -> String:
	var a := active()
	return "" if a.is_empty() else "Story: " + str(a["step"]["text"])

func _complete(step: Dictionary, out: Array) -> void:
	done[str(step["id"])] = true
	out.append(step)

func notify(event: String) -> Array:
	## An in-game event happened. Returns the steps completed (the caller shows "say" and pays "reward").
	var out := []
	var a := active()
	if not a.is_empty() and str(a["step"]["trigger"].get("event", "")) == event:
		_complete(a["step"], out)
	return out

func poll(ctx: Dictionary) -> Array:
	## ctx: {day, money, planted, debt_paid}. Completes consecutive condition steps (a chain can finish in one call).
	var out := []
	for _i in 8:
		var a := active()
		if a.is_empty():
			break
		var t: Dictionary = a["step"]["trigger"]
		var ok := false
		if t.has("day_min"):
			ok = int(ctx.get("day", 0)) >= int(t["day_min"])
		elif t.has("money_min"):
			ok = int(ctx.get("money", 0)) >= int(t["money_min"])
		elif t.has("planted_min"):
			ok = int(ctx.get("planted", 0)) >= int(t["planted_min"])
		elif t.has("debt_paid_min"):
			ok = int(ctx.get("debt_paid", 0)) >= int(t["debt_paid_min"])
		if not ok:
			break
		_complete(a["step"], out)
	return out

func debt_left(paid: int) -> int:
	return maxi(0, debt_total - paid)

func pay_debt(cash: int, paid: int, all: bool = false) -> Dictionary:
	## One ledger payment: a slice (or everything affordable). Returns {cash, paid, moved}.
	var want := debt_left(paid) if all else mini(debt_step, debt_left(paid))
	var moved := mini(want, maxi(0, cash))
	return {"cash": cash - moved, "paid": paid + moved, "moved": moved}

func log_lines(paid: int) -> PackedStringArray:
	## Quest log rows: "[x] step" / "[ ] step" per quest; debt line at the end.
	var out := PackedStringArray()
	var a := active()
	for q in quests:
		out.append(str(q["title"]))
		for s in q["steps"]:
			var mark := "[x] " if done.has(str(s["id"])) else ("[>] " if not a.is_empty() and a["step"] == s else "[ ] ")
			out.append("  " + mark + str(s["text"]))
	out.append("Vance debt: $%d of $%d paid" % [paid, debt_total])
	return out

func to_array() -> Array:
	var a := done.keys()
	a.sort()
	return a

func from_array(a: Array) -> void:
	done.clear()  # same Dictionary object: World.gate_done points at it
	for k in a:
		done[str(k)] = true
