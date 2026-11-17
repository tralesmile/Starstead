extends BaseTest

func test_sparkles_rise_and_spread() -> void:
	var a := LevelFxMath.sparkle_pos(0, 10, 0.0)
	var b := LevelFxMath.sparkle_pos(0, 10, 1.0)
	check(b.y < a.y)  # floats up
	check(b.length() > a.length() - 30.0)
	check_eq(LevelFxMath.sparkle_pos(3, 10, 0.4) == LevelFxMath.sparkle_pos(4, 10, 0.4), false)

func test_alpha_envelope() -> void:
	check_eq(LevelFxMath.sparkle_alpha(0.0), 0.0)
	check_eq(LevelFxMath.sparkle_alpha(0.5), 1.0)
	check_eq(LevelFxMath.sparkle_alpha(1.0), 0.0)

func test_banner_rises_and_pops() -> void:
	check(LevelFxMath.banner_offset(1.0) < LevelFxMath.banner_offset(0.0))
	check_eq(LevelFxMath.banner_scale(0.0), 0.0)
	check(LevelFxMath.banner_scale(0.15) > 1.0)
	check_eq(LevelFxMath.banner_scale(0.9), 1.0)

func test_bar_fill() -> void:
	check_eq(LevelFxMath.bar_fill(0), 0.0)
	check(is_equal_approx(LevelFxMath.bar_fill(50), 0.5))
	check_eq(LevelFxMath.bar_fill(99999), 1.0)
	check(LevelFxMath.bar_fill(190) > 0.49 and LevelFxMath.bar_fill(190) < 0.51)

func test_skill_colors_distinct() -> void:
	check(LevelFxMath.skill_color("farming") != LevelFxMath.skill_color("fishing"))
