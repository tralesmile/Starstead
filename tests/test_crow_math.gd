extends BaseTest

func test_flock_window() -> void:
	check(CrowMath.age(-5.0) < 0.0, "none before the day")
	check(CrowMath.age(CrowMath.WINDOW) < 0.0, "none after the window")
	check(absf(CrowMath.age(CrowMath.WINDOW * 0.5) - 0.5) < 0.001)

func test_birds_climb_and_spread() -> void:
	for i in CrowMath.COUNT:
		check(CrowMath.pos(i, 0.8).y < CrowMath.pos(i, 0.1).y, "bird %d climbs" % i)
		check(CrowMath.pos(i, 0.8).x > CrowMath.pos(i, 0.1).x, "bird %d flies right" % i)
	check(absf(CrowMath.pos(0, 0.6).y - CrowMath.pos(4, 0.6).y) > 10.0, "lanes spread")

func test_alpha_and_frames() -> void:
	check(absf(CrowMath.alpha(0.5) - 1.0) < 0.001)
	check(absf(CrowMath.alpha(1.0)) < 0.001)
	for i in CrowMath.COUNT:
		var f := CrowMath.frame(i, 3.3)
		check(f >= 0 and f < 4, "frame range")

func test_crash_dust() -> void:
	check_eq(VehicleMath.crash_dust(Vector2(0, 30), Vector2(0, -1)), 0, "graze")
	check_eq(VehicleMath.crash_dust(Vector2(200, 0), Vector2(1, 0)), 0, "moving away")
	check(VehicleMath.crash_dust(Vector2(0, -150), Vector2(0, 1)) > 0, "hit")
	check_eq(VehicleMath.crash_dust(Vector2(0, -900), Vector2(0, 1)), 14, "capped")
