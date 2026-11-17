extends BaseTest

func _m() -> JobModel:
	return JobModel.new(DataDB.load_json("jobs"))

func test_three_jobs_complete() -> void:
	var m := _m()
	check_eq(m.ids().size(), 3)
	for id in ["farmhand", "delivery_driver", "mechanic"]:
		check(m.jobs.has(id), id)
		check(m.jobs[id]["ranks"].size() >= 2, id)

func test_hours_window_and_wrap() -> void:
	var m := _m()
	check(m.in_hours("farmhand", 6.0))
	check(not m.in_hours("farmhand", 14.0))
	check(m.in_hours("mechanic", 23.0))
	check(m.in_hours("mechanic", 2.0))
	check(not m.in_hours("mechanic", 12.0))

func test_rep_requirement() -> void:
	var m := _m()
	check(m.meets_rep("farmhand", {"honest": 0, "street": 0}))
	check(not m.meets_rep("mechanic", {"honest": 99, "street": 5}))
	check(m.meets_rep("mechanic", {"honest": 0, "street": 10}))

func test_rank_and_pay() -> void:
	var m := _m()
	check_eq(m.rank_name("farmhand", 0), "Hired Hand")
	check_eq(m.rank_name("farmhand", 50), "Foreman")
	check_eq(m.shift_pay("farmhand", 0), 40)
	check_eq(m.shift_pay("farmhand", 50), 50)
	check_eq(m.xp_to_next("farmhand", 40), 10)
	check_eq(m.xp_to_next("farmhand", 999), -1)

func test_can_work_reasons() -> void:
	var m := _m()
	var rep := {"honest": 0, "street": 0}
	check_eq(m.can_work("farmhand", 8.0, rep, 100.0), "")
	check_eq(m.can_work("farmhand", 20.0, rep, 100.0), "hours")
	check_eq(m.can_work("mechanic", 22.0, rep, 100.0), "rep")
	check_eq(m.can_work("farmhand", 8.0, rep, 5.0), "energy")

func test_work_shift_promotes() -> void:
	var m := _m()
	var r := m.work_shift("farmhand", 8.0, {"honest": 0}, 100.0, 45)
	check(r["ok"])
	check_eq(r["pay"], 40)
	check_eq(r["xp"], 55)
	check(r["promoted"])
	check_eq(r["rank"], "Foreman")
	var bad := m.work_shift("farmhand", 3.0, {}, 100.0, 0)
	check(not bad["ok"])
	check_eq(bad["pay"], 0)

func test_shift_clock_and_places() -> void:
	var m := _m()
	for id in m.ids():
		check(m.place_of(id) != "", id)
	check_eq(m.minutes_after_shift("farmhand", 0.0), 240.0)
	check_eq(m.minutes_after_shift("farmhand", 1190.0), float(GameClock.DAY_LENGTH_MIN) - 1.0)
	check(JobModel.reason_text("rep", "Mechanic").contains("reputation"))
