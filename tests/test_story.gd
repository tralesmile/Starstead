extends BaseTest

func _m() -> StoryModel:
	return StoryModel.new(DataDB.load_json("story"))

func test_data_shape() -> void:
	var m := _m()
	check(m.quests.size() >= 3)
	var ids := {}
	for q in m.quests:
		for s in q["steps"]:
			check(not ids.has(s["id"]), "unique " + str(s["id"]))
			ids[s["id"]] = true
			check(s.has("text") and s.has("trigger") and s.has("say"), str(s["id"]))
	check_eq(m.total_steps(), ids.size())

func test_event_order() -> void:
	var m := _m()
	check_eq(m.active()["step"]["id"], "read_letter")
	check_eq(m.notify("ledger").size(), 0, "wrong event ignored")
	check_eq(m.notify("enter_farmhouse").size(), 1)
	check_eq(m.active()["step"]["id"], "first_crop")

func test_poll_chain() -> void:
	var m := _m()
	m.notify("enter_farmhouse")
	check_eq(m.poll({"day": 1, "money": 100, "planted": 0}).size(), 0)
	var got := m.poll({"day": 1, "money": 900, "planted": 2})
	check_eq(got.size(), 2, "crop then profit in one poll")
	check_eq(m.active()["step"]["id"], "vance_car")
	check_eq(m.poll({"day": 2, "money": 900}).size(), 0)
	check_eq(m.poll({"day": 3, "money": 900}).size(), 1)
	check_eq(m.active()["step"]["id"], "see_ledger")

func test_debt_payment() -> void:
	var m := _m()
	var r := m.pay_debt(1000, 0)
	check_eq(r["moved"], 250); check_eq(r["cash"], 750); check_eq(r["paid"], 250)
	r = m.pay_debt(100, 250)
	check_eq(r["moved"], 100, "limited by cash")
	r = m.pay_debt(5000, 0, true)
	check_eq(r["moved"], 2000, "pay all")
	r = m.pay_debt(5000, 2000, true)
	check_eq(r["moved"], 0, "nothing left")
	check_eq(m.debt_left(2300), 0)

func test_full_run_and_save() -> void:
	var m := _m()
	var ctx := {"day": 9, "money": 5000, "planted": 3, "debt_paid": 2000}
	m.notify("enter_farmhouse")
	m.poll(ctx)
	m.notify("ledger")
	m.poll(ctx)
	m.notify("enter_cave")
	m.notify("notice")
	m.poll(ctx)
	check(m.done.has("debt_free"), "act 1 done")
	check_eq(m.active()["step"]["id"], "visit_vance", "act 2 follows")
	m.notify("region_vance")
	m.notify("vance_talk")
	ctx["rep_honest"] = 12
	m.poll(ctx)
	check_eq(m.active()["step"]["id"], "first_win", "city ties follow the road choice")
	ctx["stats"] = {"race_wins": 1, "contests": 1, "promotions": 1, "bouts": 1}
	ctx["rep_honest"] = 30
	m.poll(ctx)   # stats + reputation + $5000 ticket finish Act 2 in one poll
	check(m.finished(), "acts 1 and 2 done")
	check_eq(m.goal_text(), "")
	var m2 := _m()
	m2.from_array(m.to_array())
	check(m2.finished())
	check_eq(m2.steps_done(), m.total_steps())
	check(m2.log_lines(2000).size() > 8)

func test_goal_uses_story() -> void:
	check(GoalText.current(3, 2, 5, 300, false, 0, "Story: do it").contains("Story: do it"))
	check(GoalText.current(0, 0, 1, 500, false, 0, "Story: x").contains("hoe"), "day 1 keeps the tutorial")

func test_late_fees() -> void:
	var m := _m()
	m.day = 28
	check_eq(m.late_fee(), 0, "on time")
	m.day = 29
	check_eq(m.late_fee(), 100, "first late week")
	m.day = 36
	check_eq(m.late_fee(), 200)
	m.day = 400
	check_eq(m.late_fee(), 500, "capped")
	check_eq(m.debt_left(0), 2500)
	m.done["debt_free"] = true
	check_eq(m.late_fee(), 0, "no fees after clearing")
	check_eq(m.debt_left(0), 0)

func test_debt_clear_trigger_counts_fees() -> void:
	var m := _m()
	check(m.cond_ok({"debt_clear": true}, {"debt_paid": 2000}))
	m.day = 30
	check(not m.cond_ok({"debt_clear": true}, {"debt_paid": 2000}), "late fee still owed")
	check(m.cond_ok({"debt_clear": true}, {"debt_paid": 2100}))

func test_act2_branches() -> void:
	var m := _m()
	for s in ["read_letter", "first_crop", "first_profit", "vance_car", "see_ledger", "first_instalment", "cave_note", "read_notice", "debt_free"]:
		m.done[s] = true
	check_eq(m.active()["step"]["id"], "visit_vance")
	check_eq(m.notify("region_vance").size(), 1)
	check_eq(m.notify("vance_talk").size(), 1)
	check_eq(m.poll({"rep_honest": 4, "rep_street": 9}).size(), 0)
	check_eq(m.poll({"rep_honest": 4, "rep_street": 10, "money": 100}).size(), 1, "street road")
	for q in m.quests:
		if q["id"] == "city_ties":
			for st in q["steps"]:
				m.done[st["id"]] = true
	check_eq(m.active()["step"]["id"], "rocket_seat")
	var street := m.notify("keycard")
	check_eq(street.size(), 1, "keycard opens the pad")
	check(m.finished())

func test_act2_honest_ticket() -> void:
	var m := _m()
	for q in m.quests:
		for s in q["steps"]:
			if s["id"] != "rocket_seat":
				m.done[s["id"]] = true
	check_eq(m.poll({"money": 4999}).size(), 0)
	check_eq(m.poll({"money": 5000}).size(), 1)

func test_side_and_events() -> void:
	check_eq(StoryModel.side(3, 5), "street")
	check_eq(StoryModel.side(5, 5), "honest")
	check_eq(StoryModel.trigger_events({"any": [{"money_min": 1}, {"event": "k"}]}), ["k"])

func test_current_act() -> void:
	var m := _m()
	check_eq(m.current_act(), "Act 1: Earth Homestead")
	m.done["debt_free"] = true
	check_eq(m.current_act(), "Act 2: Earth City")

func test_city_ties_stats_and_side() -> void:
	var m := _m()
	var t := {"stat_min": {"race_wins": 2, "bouts": 1}}
	check(not m.cond_ok(t, {"stats": {"race_wins": 2}}), "needs every stat")
	check(m.cond_ok(t, {"stats": {"race_wins": 3, "bouts": 1}}))
	var step := {"say": "a", "say_street": "b"}
	check_eq(StoryModel.say_for(step, "honest"), "a")
	check_eq(StoryModel.say_for(step, "street"), "b")
	check_eq(StoryModel.say_for({"say": "a"}, "street"), "a", "falls back")

func test_stats_saved() -> void:
	var gs = load("res://scripts/game_state.gd").new()
	gs.bump("race_wins"); gs.bump("race_wins")
	var d: Dictionary = gs.to_dict()
	var h = load("res://scripts/game_state.gd").new()
	h.from_dict(JSON.parse_string(JSON.stringify(d)))
	check_eq(int(h.stats.get("race_wins", 0)), 2)
	gs.free(); h.free()

func test_progress_text() -> void:
	var m := _m()
	var st := {"trigger": {"stat_min": {"race_wins": 3}}}
	check_eq(m.progress_text(st, {"race_wins": 1}), " (1/3)")
	check_eq(m.progress_text(st, {"race_wins": 9}), " (3/3)")
	check_eq(m.progress_text({"trigger": {"stat_min": {"bouts": 1}}}, {}), "", "single steps stay plain")
	check_eq(m.progress_text({"trigger": {"day_min": 3}}, {}), "")
