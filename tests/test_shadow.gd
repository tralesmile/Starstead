extends BaseTest

func test_noon_is_short_and_centred() -> void:
	var noon := 390.0
	check_eq(ShadowMath.offset_x(noon), 0.0)
	check(ShadowMath.length_factor(noon) < 1.05)
	check(is_equal_approx(ShadowMath.stretch(noon), 1.0) or ShadowMath.stretch(noon) < 1.05)

func test_morning_west_evening_east() -> void:
	check(ShadowMath.offset_x(20.0) < 0.0)
	check(ShadowMath.offset_x(760.0) > 0.0)
	check(ShadowMath.length_factor(20.0) > ShadowMath.length_factor(200.0))
	check(ShadowMath.length_factor(0.0) <= 3.0)

func test_stretch_and_night_fade() -> void:
	check(ShadowMath.stretch(30.0) > ShadowMath.stretch(390.0))
	check(ShadowMath.stretch(30.0) <= 1.7)
	check_eq(ShadowMath.strength(300.0), 1.0)
	check(ShadowMath.strength(900.0) < 0.5)
	check_eq(ShadowMath.strength(1200.0), 0.25)
