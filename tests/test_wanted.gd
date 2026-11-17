extends BaseTest

func test_stars_from_heat() -> void:
	check_eq(WantedMath.stars(0.0), 0)
	check_eq(WantedMath.stars(1.0), 1)
	check_eq(WantedMath.stars(20.0), 1)
	check_eq(WantedMath.stars(20.1), 2)
	check_eq(WantedMath.stars(100.0), 5)

func test_witnessed_adds_more_and_caps() -> void:
	check(WantedMath.add(0.0, "robbery", true) > WantedMath.add(0.0, "robbery", false))
	check_eq(WantedMath.add(90.0, "robbery", true), WantedMath.MAX_HEAT)
	check(WantedMath.add(0.0, "unknown", true) > 0.0)

func test_decay_faster_when_hidden() -> void:
	check(WantedMath.decay(50.0, 1.0, false) < WantedMath.decay(50.0, 1.0, true))
	check_eq(WantedMath.decay(1.0, 5.0, false), 0.0)

func test_police_and_fine_scale() -> void:
	check_eq(WantedMath.police_count(0), 0)
	check(WantedMath.police_count(5) > WantedMath.police_count(2))
	check_eq(WantedMath.fine(0), 0)
	check(WantedMath.fine(3) > WantedMath.fine(2))
