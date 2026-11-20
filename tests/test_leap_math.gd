extends BaseTest

func test_arc_ends_and_peak() -> void:
	var a := Vector2(0, 0)
	var b := Vector2(100, 0)
	check_eq(LeapMath.pos(a, b, 0.0), a)
	check_eq(LeapMath.pos(a, b, 1.0), b)
	var mid := LeapMath.pos(a, b, 0.5)
	check(is_equal_approx(mid.x, 50.0) and is_equal_approx(mid.y, -LeapMath.HEIGHT), "peak above the middle")
	check(LeapMath.pos(a, b, 0.25).y > mid.y, "rises then falls")
	check_eq(LeapMath.pos(a, b, 2.0), b, "clamped")

func test_duration_scales_with_distance() -> void:
	check(LeapMath.duration(Vector2.ZERO, Vector2(40, 0)) < LeapMath.duration(Vector2.ZERO, Vector2(200, 0)))
	check(LeapMath.duration(Vector2.ZERO, Vector2(9999, 0)) <= LeapMath.MAX_T)
	check(LeapMath.duration(Vector2.ZERO, Vector2.ZERO) >= LeapMath.MIN_T)

func test_spin_and_squash() -> void:
	check(LeapMath.spin(1.0, 1.0) > 0.0 and LeapMath.spin(1.0, -1.0) < 0.0)
	check(is_equal_approx(LeapMath.spin(1.0, 1.0), TAU * 1.5))
	var sq := LeapMath.landing_squash(0.0)
	check(sq.x > 1.0 and sq.y < 1.0, "flat on impact")
	check_eq(LeapMath.landing_squash(1.0), Vector2.ONE, "settled")
