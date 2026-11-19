extends BaseTest

func test_swing_slow() -> void:
	check_eq(PlayerMath.swing_slow(0.0), 1.0)
	check_eq(PlayerMath.swing_slow(-0.1), 1.0)
	check(absf(PlayerMath.swing_slow(0.18) - 0.35) < 0.001, "planted feet during the swing")
	var mid := PlayerMath.swing_slow(0.03)
	check(mid > 0.35 and mid < 1.0, "eases back")
