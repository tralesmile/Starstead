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
	check(m.finished(), "act 1 done")
	check_eq(m.goal_text(), "")
	var m2 := _m()
	m2.from_array(m.to_array())
	check(m2.finished())
	check_eq(m2.steps_done(), m.total_steps())
	check(m2.log_lines(2000).size() > 8)

func test_goal_uses_story() -> void:
	check(GoalText.current(3, 2, 5, 300, false, 0, "Story: do it").contains("Story: do it"))
	check(GoalText.current(0, 0, 1, 500, false, 0, "Story: x").contains("hoe"), "day 1 keeps the tutorial")
