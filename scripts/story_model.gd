class_name StoryModel
extends RefCounted
## Pure quest chain for the story acts (data/story.json): quests run in order, each has ordered steps.
## A step completes on an event (notify), or when a poll condition holds (day_min, money_min, planted_min, debt_paid_min).

var quests: Array = []
var done: Dictionary = {}       # step id -> true
var debt_total := 2000
var debt_step := 250
var act := ""
var acts: Array = []            # [{after: step id, name}] in order; the last reached one is the current act
var day := 1                    # last polled game day (late fees)
var due_day := 28
var late_fee_step := 100
var late_cap := 500

func _init(data: Dictionary = {}) -> void:
	quests = data.get("quests", [])
	debt_total = int(data.get("debt_total", 2000))
	debt_step = int(data.get("debt_step", 250))
	act = str(data.get("act", ""))
	acts = data.get("acts", [])
	due_day = int(data.get("debt_due_day", 28))
	late_fee_step = int(data.get("late_fee", 100))
	late_cap = int(data.get("late_cap", 500))

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
	if not a.is_empty() and event in trigger_events(a["step"]["trigger"]):
		_complete(a["step"], out)
	return out

static func trigger_events(t: Dictionary) -> Array:
	## Events that complete a trigger: its own "event" plus any listed under "any".
	var out := []
	if t.has("event"):
		out.append(str(t["event"]))
	for sub in t.get("any", []):
		out.append_array(trigger_events(sub))
	return out

func cond_ok(t: Dictionary, ctx: Dictionary) -> bool:
	## Poll conditions. "any" = one of several sub-triggers (events never hold in a poll).
	if t.has("any"):
		for sub in t["any"]:
			if not (sub as Dictionary).has("event") and cond_ok(sub, ctx):
				return true
		return false
	if t.has("day_min"):
		return int(ctx.get("day", 0)) >= int(t["day_min"])
	if t.has("money_min"):
		return int(ctx.get("money", 0)) >= int(t["money_min"])
	if t.has("planted_min"):
		return int(ctx.get("planted", 0)) >= int(t["planted_min"])
	if t.has("debt_paid_min"):
		return int(ctx.get("debt_paid", 0)) >= int(t["debt_paid_min"])
	if t.has("debt_clear"):
		return debt_left(int(ctx.get("debt_paid", 0))) == 0
	if t.has("stat_min"):
		var st: Dictionary = ctx.get("stats", {})
		for k in t["stat_min"]:
			if int(st.get(k, 0)) < int(t["stat_min"][k]):
				return false
		return true
	if t.has("rep_any_min"):
		return maxi(int(ctx.get("rep_honest", 0)), int(ctx.get("rep_street", 0))) >= int(t["rep_any_min"])
	return false

func current_act() -> String:
	var name := act
	for a in acts:
		var after := str(a.get("after", ""))
		if after == "" or done.has(after):
			name = str(a["name"])
	return name

func late_fee() -> int:
	## Vance adds a fee for every started week past the due day, up to the cap; nothing once the debt is cleared.
	if done.has("debt_free") or day <= due_day:
		return 0
	return mini(late_cap, ((day - due_day - 1) / 7 + 1) * late_fee_step)

static func say_for(step: Dictionary, side_name: String) -> String:
	## Beats can have a "say_street" variant for the street road.
	if side_name == "street" and step.has("say_street"):
		return str(step["say_street"])
	return str(step.get("say", ""))

static func side(rep_honest: int, rep_street: int) -> String:
	return "street" if rep_street > rep_honest else "honest"

func poll(ctx: Dictionary) -> Array:
	## ctx: {day, money, planted, debt_paid}. Completes consecutive condition steps (a chain can finish in one call).
	var out := []
	day = int(ctx.get("day", day))
	for _i in 8:
		var a := active()
		if a.is_empty():
			break
		if not cond_ok(a["step"]["trigger"], ctx):
			break
		_complete(a["step"], out)
	return out

func debt_left(paid: int) -> int:
	if done.has("debt_free"):
		return 0
	return maxi(0, debt_total + late_fee() - paid)

func pay_debt(cash: int, paid: int, all: bool = false) -> Dictionary:
	## One ledger payment: a slice (or everything affordable). Returns {cash, paid, moved}.
	var want := debt_left(paid) if all else mini(debt_step, debt_left(paid))
	var moved := mini(want, maxi(0, cash))
	return {"cash": cash - moved, "paid": paid + moved, "moved": moved}

func progress_text(step: Dictionary, stats: Dictionary) -> String:
	## " (1/2)" for stat steps that need more than one, so the log shows how far along you are.
	var t: Dictionary = step.get("trigger", {})
	if not t.has("stat_min"):
		return ""
	var have := 0
	var need := 0
	for k in t["stat_min"]:
		need += int(t["stat_min"][k])
		have += mini(int(stats.get(k, 0)), int(t["stat_min"][k]))
	return "" if need <= 1 else " (%d/%d)" % [have, need]

func log_lines(paid: int, stats: Dictionary = {}) -> PackedStringArray:
	## Quest log rows: "[x] step" / "[ ] step" per quest; debt line at the end.
	var out := PackedStringArray()
	var a := active()
	for q in quests:
		out.append(str(q["title"]))
		for s in q["steps"]:
			var mark := "[x] " if done.has(str(s["id"])) else ("[>] " if not a.is_empty() and a["step"] == s else "[ ] ")
			out.append("  " + mark + str(s["text"]) + (progress_text(s, stats) if not done.has(str(s["id"])) else ""))
	if done.has("debt_free"):
		out.append("Vance debt: cleared")
	else:
		var fee := late_fee()
		out.append("Vance debt: $%d of $%d paid, due day %d%s" % [paid, debt_total + fee, due_day, ("  (late fees $%d)" % fee) if fee > 0 else ""])
	return out

func to_array() -> Array:
	var a := done.keys()
	a.sort()
	return a

func from_array(a: Array) -> void:
	done.clear()  # same Dictionary object: World.gate_done points at it
	for k in a:
		done[str(k)] = true
