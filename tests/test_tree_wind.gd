extends BaseTest

func test_calm_has_no_lean() -> void:
	check_eq(WeatherMath.tree_wind(0.5, 0.0), Vector2.ZERO)

func test_storm_leans_downwind_like_the_rain() -> void:
	var east := WeatherMath.tree_wind(1.0, 0.0)
	var west := WeatherMath.tree_wind(1.0, PI)
	check(east.x > 1.0 and west.x < -1.0)
	check_eq(east.y, 1.0)
	check(WeatherMath.slant(1.0, 0.0) < 0.0, "rain drifts right too")

func test_gale_leaf_travels_downwind_inside_the_box() -> void:
	var a := AmbientMath.gale_leaf(2, 1.0, 0.0)
	var b := AmbientMath.gale_leaf(2, 1.05, 0.0)
	check(fposmod(b.x - a.x, 360.0) < 20.0 and b.x != a.x)
	for i in 30:
		var p := AmbientMath.gale_leaf(i, 7.3, 2.0)
		check(absf(p.x) <= 180.0 and p.y > -145.0 and p.y < 105.0)
