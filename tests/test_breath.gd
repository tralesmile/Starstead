extends BaseTest

func test_cold_by_season_and_time() -> void:
	check(AmbientMath.breath_cold(3, 300.0) > 0.6)             # winter noon
	check(AmbientMath.breath_cold(1, 300.0) == 0.0)            # summer never
	check(AmbientMath.breath_cold(2, 10.0) > AmbientMath.breath_cold(2, 300.0))   # autumn: mornings colder
	check(AmbientMath.breath_cold(0, 10.0) > 0.0 and AmbientMath.breath_cold(0, 400.0) == 0.0)
	for s in 4:
		for m in [0.0, 100.0, 400.0, 700.0, 840.0]:
			var v := AmbientMath.breath_cold(s, m)
			check(v >= 0.0 and v <= 1.0)

func test_breath_cycle() -> void:
	check(AmbientMath.breath_age(0.0) == 0.0)
	check(AmbientMath.breath_age(0.5) > 0.4 and AmbientMath.breath_age(0.5) < 0.6)
	check_eq(AmbientMath.breath_age(1.5), -1.0)
	check(AmbientMath.breath_age(AmbientMath.BREATH_PERIOD + 0.5) > 0.4)

func test_puffs_drift_and_grow() -> void:
	var a := AmbientMath.breath_puff(0.2, 0)
	var b := AmbientMath.breath_puff(0.9, 0)
	check(b.x > a.x and b.y < a.y and b.z > a.z)
	check(AmbientMath.breath_puff(0.0, 2).z >= 1.0)
