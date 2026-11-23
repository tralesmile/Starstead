extends BaseTest

func test_only_winter_changes_movement() -> void:
	for s in [0, 1, 2]:
		check_eq(PlayerMath.snow_speed(s, false), 1.0)
		check_eq(PlayerMath.snow_grip(s, true), 1.0)

func test_winter_drags_grass_more_than_path() -> void:
	check(PlayerMath.snow_speed(3, false) < PlayerMath.snow_speed(3, true))
	check(PlayerMath.snow_speed(3, true) < 1.0)

func test_winter_paths_are_icy() -> void:
	check(PlayerMath.snow_grip(3, true) < PlayerMath.snow_grip(3, false))
	check(PlayerMath.snow_grip(3, false) < 1.0)

func test_season_wraps_each_year() -> void:
	check_eq(PlayerMath.snow_speed(7, false), PlayerMath.snow_speed(3, false))

func test_winter_never_stalls_the_player() -> void:
	var v := Vector2.ZERO
	for i in 60:
		v = PlayerMath.accelerate(v, Vector2.RIGHT, 1.0 / 60.0, PlayerMath.SPEED * PlayerMath.snow_speed(3, true), PlayerMath.snow_grip(3, true) * PlayerMath.wet_grip(1.0, true))
	check(v.length() > PlayerMath.SPEED * 0.5)
