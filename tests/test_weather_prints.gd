extends BaseTest

func test_rain_deterministic_and_bounded() -> void:
	var rainy := 0
	for d in 200:
		var r := WeatherMath.rain_for_day(7, d, 0)
		check(r == WeatherMath.rain_for_day(7, d, 0))
		check(r == 0.0 or (r >= 0.3 and r <= 1.0))
		if r > 0.0:
			rainy += 1
	check(rainy > 30 and rainy < 90, "rainy=%d" % rainy)

func test_rain_window_and_darken() -> void:
	check(WeatherMath.rain_now(1.0, 0.0) == 0.0)
	check(WeatherMath.rain_now(1.0, 400.0) == 1.0)
	check(WeatherMath.rain_now(1.0, 740.0) == 0.0)
	check(WeatherMath.rain_now(0.0, 400.0) == 0.0)
	check(WeatherMath.darken(1.0).r < WeatherMath.darken(0.0).r)
	check(WeatherMath.darken(0.0) == Color(1, 1, 1))

func test_drop_in_box() -> void:
	for i in 50:
		var p := WeatherMath.drop_pos(i, 3.3)
		check(p.x >= 0.0 and p.x < 360.0 and p.y >= 0.0 and p.y < 280.0)

func test_footprints() -> void:
	check(not FootprintMath.due(3.0) and FootprintMath.due(9.0))
	var a := FootprintMath.print_pos(Vector2(100, 100), Vector2.RIGHT, 0)
	var b := FootprintMath.print_pos(Vector2(100, 100), Vector2.RIGHT, 1)
	check(a.y != b.y and a.x == b.x)
	check(FootprintMath.alpha(0.0) > FootprintMath.alpha(6.0))
	check(FootprintMath.alpha(99.0) == 0.0)

func test_ripple_grows_and_fades() -> void:
	check(WeatherMath.ripple_radius(0.9) > WeatherMath.ripple_radius(0.1))
	check(WeatherMath.ripple_alpha(0.9) < WeatherMath.ripple_alpha(0.1))
	check_eq(WeatherMath.ripple_alpha(1.0), 0.0)

func test_ripple_in_box_and_respawns() -> void:
	for i in 20:
		var r := WeatherMath.ripple(i, 3.3)
		check(r.pos.x >= 0.0 and r.pos.x <= 360.0 and r.pos.y >= 0.0 and r.pos.y <= 280.0)
		check(r.age >= 0.0 and r.age < 1.0)
	check(WeatherMath.ripple(3, 0.1).pos != WeatherMath.ripple(3, 0.1 + 1.1).pos)

func test_fog_rules() -> void:
	check_eq(WeatherMath.fog_for_day(1, 5, 2, 0.5), 0.0)
	check_eq(WeatherMath.fog_now(0.6, 0.0), 0.6)
	check_eq(WeatherMath.fog_now(0.6, 240.0), 0.0)
	var any := false
	for d in 60:
		var f := WeatherMath.fog_for_day(1, d, 2, 0.0)
		check(f >= 0.0 and f <= 0.7)
		if f > 0.0:
			any = true
	check(any, "autumn should have some fog days")

func test_rain_slant_follows_wind() -> void:
	check_eq(WeatherMath.slant(0.4, 0.0), 0.18, "calm rain keeps the default lean")
	check(WeatherMath.slant(1.0, 0.0) < 0.0, "east wind leans streaks right")
	check(WeatherMath.slant(1.0, PI) > 0.5, "west wind leans streaks left")
	check(WeatherMath.streak(WeatherMath.slant(1.0, 0.0)).x > 0.0)
	check_eq(WeatherMath.streak(0.18).x, -2.0)
	var a := WeatherMath.drop_pos(5, 1.0)
	var b := WeatherMath.drop_pos(5, 1.0, 260.0, 0.18)
	check_eq(a, b)
