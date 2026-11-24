extends BaseTest

func test_moves_toward_target_not_past() -> void:
	var v := 1.0
	for i in 5:
		v = PlayerMath.surface_ease(v, 0.6, 1.0 / 60.0)
	check(v < 1.0 and v > 0.6)
	for i in 120:
		v = PlayerMath.surface_ease(v, 0.6, 1.0 / 60.0)
	check(absf(v - 0.6) < 0.01)

func test_zero_dt_is_stable() -> void:
	check_eq(PlayerMath.surface_ease(1.1, 0.8, 0.0), 1.1)

func test_settles_in_about_a_quarter_second() -> void:
	var v := 1.0
	for i in 15:   # 0.25 s at 60 fps
		v = PlayerMath.surface_ease(v, 0.8, 1.0 / 60.0)
	check(absf(v - 0.8) < 0.04)
