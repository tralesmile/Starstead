extends BaseTest

func test_snow_only_in_winter_off_pavement() -> void:
	check(PrintMath.snow(3, false))
	check(not PrintMath.snow(3, true))
	check(not PrintMath.snow(0, false))
	check(PrintMath.snow(7, false))

func test_snow_alpha_fades_and_ends() -> void:
	check(PrintMath.snow_alpha(0.0) > 0.5)
	check(PrintMath.snow_alpha(0.0) >= PrintMath.snow_alpha(10.0))
	check(PrintMath.snow_alpha(10.0) > PrintMath.snow_alpha(20.0))
	check_eq(PrintMath.snow_alpha(PrintMath.SNOW_LIFE), 0.0)

func test_prune_keeps_snow_prints_longer() -> void:
	var a: Array = [{"pos": Vector2.ZERO, "age": 0.0, "life": PrintMath.SNOW_LIFE}, {"pos": Vector2.ZERO, "age": 0.0}]
	a = PrintMath.prune(a, 10.0)
	check_eq(a.size(), 1)
	check(a[0].has("life"))
	a = PrintMath.prune(a, 13.0)
	check_eq(a.size(), 0)
