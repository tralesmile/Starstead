extends BaseTest

func test_power_ping_pongs() -> void:
	check_eq(CastMath.power(0.0), 0.0)
	check(absf(CastMath.power(CastMath.PERIOD * 0.5) - 0.5) < 0.001)
	check(absf(CastMath.power(CastMath.PERIOD) - 1.0) < 0.001)
	check(absf(CastMath.power(CastMath.PERIOD * 2.0)) < 0.001)
	for i in 50:
		var p := CastMath.power(float(i) * 0.17)
		check(p >= 0.0 and p <= 1.0)

func test_distance_range() -> void:
	check_eq(CastMath.distance_tiles(0.0), CastMath.MIN_TILES)
	check_eq(CastMath.distance_tiles(1.0), CastMath.MAX_TILES)
	check(CastMath.distance_tiles(0.5) > CastMath.MIN_TILES)

func test_choose_water_cell() -> void:
	var w := [false, false, true, true, true, false, false]   # water at distance 3..5
	check_eq(CastMath.choose(w, 7), 4)    # farthest water within reach
	check_eq(CastMath.choose(w, 4), 3)    # capped by the wanted distance
	check_eq(CastMath.choose(w, 2), 2)    # short throw falls back to the nearest water
	check_eq(CastMath.choose([false, false], 5), -1)
