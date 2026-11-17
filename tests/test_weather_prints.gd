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
