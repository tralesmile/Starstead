extends BaseTest

func test_sailings_are_hourly_and_end() -> void:
	check_eq(FerryModel.next_departure(0.0, true), 60)      # 06:00 -> 07:00
	check_eq(FerryModel.next_departure(60.0, true), 60)
	check_eq(FerryModel.next_departure(61.0, true), 120)
	check_eq(FerryModel.next_departure(780.0, true), 780)
	check_eq(FerryModel.next_departure(781.0, true), -1)
	check_eq(FerryModel.next_departure(781.0, false), 840)  # the way home runs later
	check_eq(FerryModel.next_departure(961.0, false), -1)
	check_eq(FerryModel.time_text(60), "07:00")

func test_return_is_free_and_always_affordable() -> void:
	var home := FerryModel.quote(600.0, 1.0, 0, false)
	check(home["ok"], "broke, in a storm, still gets home")
	check_eq(home["fare"], 0)
	check_eq(home["arrive"], 600 + FerryModel.CROSSING + FerryModel.ROUGH_EXTRA)

func test_outbound_needs_fare_calm_water_and_a_boat() -> void:
	check(FerryModel.quote(100.0, 0.0, FerryModel.FARE, true)["ok"])
	check(not FerryModel.quote(100.0, 0.0, FerryModel.FARE - 1, true)["ok"])
	check(not FerryModel.quote(100.0, 0.9, 999, true)["ok"])
	check(not FerryModel.quote(900.0, 0.0, 999, true)["ok"])

func test_hull_bob_grows_with_weather_and_stays_small() -> void:
	var calm := 0.0
	var storm := 0.0
	for i in 200:
		var t := i * 0.07
		calm = maxf(calm, absf(FerryModel.bob(t, 0.0)["y"]))
		storm = maxf(storm, absf(FerryModel.bob(t, 1.0)["y"]))
		check(absf(FerryModel.bob(t, 1.0)["roll"]) <= 0.061)
	check(storm > calm * 2.0)
	check(storm <= 4.0)

func test_sailing_eases_in_and_out() -> void:
	check_eq(FerryModel.sail_progress(0.0), 0.0)
	check_eq(FerryModel.sail_progress(1.0), 1.0)
	check(FerryModel.sail_progress(0.1) < 0.1)
	check(FerryModel.sail_speed(0.5) > FerryModel.sail_speed(0.1))
	check_eq(FerryModel.sail_speed(0.0), 0.0)

func test_lighthouse_dark_by_day_brighter_in_haze() -> void:
	check_eq(LighthouseMath.strength(0.0, 1.0), 0.0)
	check(LighthouseMath.strength(1.0, 1.0) > LighthouseMath.strength(1.0, 0.0))
	check(absf(LighthouseMath.angle(LighthouseMath.PERIOD * 0.25) - PI / 2.0) < 0.001)
	var pts := LighthouseMath.beam(0.0)
	check_eq(pts.size(), 3)
	check(pts[1].x > 200.0)
