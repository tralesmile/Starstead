extends BaseTest

func test_mud_builds_on_wet_grass_and_caps() -> void:
	var m := 0.0
	for i in 600:
		m = PlayerMath.mud_load(m, 1.0, false, true, 0.1)
	check_eq(m, 1.0)
	check(is_equal_approx(PlayerMath.mud_speed(m), 0.93), "7% slower when caked")

func test_no_build_when_dry_or_standing_or_on_path() -> void:
	check_eq(PlayerMath.mud_load(0.0, 0.1, false, true, 5.0), 0.0)
	check_eq(PlayerMath.mud_load(0.0, 1.0, false, false, 5.0), 0.0)
	check_eq(PlayerMath.mud_load(0.0, 1.0, true, true, 5.0), 0.0)

func test_path_sheds_faster_than_grass() -> void:
	var on_path := PlayerMath.mud_load(1.0, 0.0, true, true, 2.0)
	var on_grass := PlayerMath.mud_load(1.0, 0.0, false, true, 2.0)
	check(on_path < on_grass, "paths clean boots faster")
	check(PlayerMath.mud_load(1.0, 0.0, true, true, 20.0) == 0.0, "gone after 8 s of path")

func test_light_rain_builds_slowly() -> void:
	var heavy := PlayerMath.mud_load(0.0, 1.0, false, true, 5.0)
	var light := PlayerMath.mud_load(0.0, 0.5, false, true, 5.0)
	check(light > 0.0 and light < heavy)
