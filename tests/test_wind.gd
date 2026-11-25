extends BaseTest

func test_no_wind_without_a_storm() -> void:
	check_eq(PlayerMath.wind_mult(0.5, 0.0, Vector2.RIGHT), 1.0)
	check_eq(PlayerMath.wind_mult(0.0, 1.0, Vector2.LEFT), 1.0)

func test_standing_still_is_not_pushed() -> void:
	check_eq(PlayerMath.wind_mult(1.0, 0.0, Vector2.ZERO), 1.0)

func test_headwind_slows_tailwind_helps() -> void:
	var head := PlayerMath.wind_mult(1.0, 0.0, Vector2.LEFT)
	var tail := PlayerMath.wind_mult(1.0, 0.0, Vector2.RIGHT)
	check(absf(head - 0.94) < 0.001)
	check(absf(tail - 1.03) < 0.001)
	check_eq(PlayerMath.wind_mult(1.0, 0.0, Vector2.DOWN), 1.0)

func test_storm_strength_scales() -> void:
	var half := PlayerMath.wind_mult(0.8, 0.0, Vector2.LEFT)
	check(half > 0.94 and half < 1.0)

func test_wind_angle_changes_by_day_and_stays_in_range() -> void:
	check(PlayerMath.wind_angle(1) != PlayerMath.wind_angle(2))
	for d in 60:
		var a := PlayerMath.wind_angle(d)
		check(a >= 0.0 and a < TAU)
