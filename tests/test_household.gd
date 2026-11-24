extends BaseTest

func test_routines() -> void:
	check_eq(Household.state_at("worker", 3.0), "sleep")
	check_eq(Household.state_at("worker", 12.0), "away")
	check_eq(Household.state_at("worker", 19.0), "home")
	check_eq(Household.state_at("nightowl", 21.0), "away")
	check_eq(Household.state_at("kid", 23.5), "sleep")

func test_presence() -> void:
	check_eq(Household.present("city_house1", 12.0).size(), 1)   # only the stay-home parent
	check(Household.present("city_house2", 12.0).size() == 1)
	check(Household.nobody_home("city_house3", 20.0) == false)
	check(Household.nobody_home("city_apt_b", 12.0) == false)   # homebody Odette is in
	check(Household.lights_on("city_house1", 19.0))
	check(not (Household.lights_on("city_house1", 23.0)))
	check(Household.members("nope").is_empty())

func test_wake_threshold() -> void:
	check_eq(Household.wake_threshold(60.0, "nope", 12.0), 60.0)
	check(Household.wake_threshold(60.0, "city_house1", 23.0) < 60.0)   # a kid sleeps lightly
	check(Household.wake_threshold(60.0, "city_house1", 19.0) < Household.wake_threshold(60.0, "city_house1", 23.0))   # awake hears more
	check(Household.wake_threshold(60.0, "city_house3", 13.0) > 60.0)

func test_empty_house_louder_needed() -> void:
	# Dev Rao away 8-17, Tamsin sleeps 3-11: at 13:00 Tamsin is up (home); at 21:00 both away.
	check(Household.nobody_home("city_house3", 12.0))
	check_eq(Household.wake_threshold(60.0, "city_house3", 12.0), 96.0)

func test_suspicion() -> void:
	check(Household.suspicion_rate(2.0, false) > 0.0)
	check(Household.suspicion_rate(9.0, false) < 0.0)
	check(Household.suspicion_rate(3.0, true) < 0.0)   # sneaking beyond 2.5 cells is unseen
	check(Household.suspicion_rate(2.0, true) < Household.suspicion_rate(2.0, false))
	check(Household.suspicion_rate(1.0, false) > Household.suspicion_rate(4.0, false))

func test_stand_pos() -> void:
	var l := InteriorModel.layout_for("city_house1")
	for m in Household.members("city_house1"):
		var p := Household.stand_pos(l, m, 19.0)
		check(p.x > 0.0 and p.x < float(l["w"]) * 32.0)
		check(Household.spot_cell(l, String(m["bed"])).x >= 0.0)

func test_shove() -> void:
	var r := Household.shove(30.0, 0.0, 0.1)
	check(r["hit"] and r["cooldown"] == Household.SHOVE_EVERY)
	check(not Household.shove(30.0, r["cooldown"], 0.1)["hit"])   # cooling down
	check(not Household.shove(80.0, 0.0, 0.1)["hit"])             # out of reach
	check(Household.shove(30.0, 0.15, 0.2)["hit"])                # cooldown elapsed

func test_window_lit() -> void:
	check(Household.window_lit("city_house2", 0, 2, 19.0))
	check(not Household.window_lit("city_house2", 0, 2, 23.0))
	check(Household.window_lit("nobody_lives_here", 0, 2, 23.0))   # public buildings keep their lights
	check(Household.window_lit("city_apt_a", 0, 4, 18.0) and not Household.window_lit("city_apt_a", 3, 4, 18.0) or Household.window_lit("city_apt_a", 3, 4, 18.0))

func test_greeting() -> void:
	check(Household.greeting("Mrs. Lindqvist", true, 12.0).contains("police"))
	check(Household.greeting("Dev", false, 8.0).contains("Morning"))
	check(Household.greeting("Dev", false, 22.0).contains("late"))
	check(Household.greeting("Dev", false, 14.0).contains("hello"))
