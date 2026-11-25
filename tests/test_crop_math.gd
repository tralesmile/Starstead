extends BaseTest

func test_seed_does_not_sway() -> void:
	check_eq(CropMath.sway(Vector2i(3, 4), 5.0, 0), 0.0)

func test_bounded_everywhere() -> void:
	for st in 5:
		for i in 200:
			var s := CropMath.sway(Vector2i(i % 17, i % 5), float(i) * 0.37, st, 3.0)
			check(absf(s) <= CropMath.MAX_SKEW + 0.0001)

func test_taller_sways_more() -> void:
	var lo := 0.0
	var hi := 0.0
	for i in 300:
		lo = maxf(lo, absf(CropMath.sway(Vector2i(2, 2), float(i) * 0.1, 1)))
		hi = maxf(hi, absf(CropMath.sway(Vector2i(2, 2), float(i) * 0.1, 4)))
	check(hi > lo * 2.0)

func test_neighbours_out_of_phase() -> void:
	var diff := 0
	for i in 50:
		if absf(CropMath.sway(Vector2i(0, 0), float(i) * 0.3, 4) - CropMath.sway(Vector2i(5, 0), float(i) * 0.3, 4)) > 0.01:
			diff += 1
	check(diff > 20)

func test_calm_wind_is_still() -> void:
	check_eq(CropMath.sway(Vector2i(1, 1), 3.3, 4, 0.0), 0.0)

func test_glint_inside_tile_and_flashes_briefly() -> void:
	var lit := 0
	for i in 400:
		var g := CropMath.glint(Vector2i(7, 3), 0, float(i) * 0.1)
		check(g["x"] >= 4.0 and g["x"] < 28.0 and g["y"] >= 4.0 and g["y"] < 28.0)
		check(g["a"] >= 0.0 and g["a"] <= 1.0)
		if g["a"] > 0.5:
			lit += 1
	check(lit > 10 and lit < 200)

func test_brush_bends_away() -> void:
	var plant := Vector2(100, 100)
	check_eq(CropMath.brush(plant, Vector2(300, 100), 3), 0.0, "far away: no bend")
	check_eq(CropMath.brush(plant, plant, 0), 0.0, "seeds do not bend")
	var right := CropMath.brush(plant, Vector2(90, 100), 3)   # player left of plant: plant leans right
	var left := CropMath.brush(plant, Vector2(110, 100), 3)
	check(right > 0.1 and left < -0.1)
	check(absf(CropMath.brush(plant, Vector2(80, 100), 3)) < absf(right), "falls off with distance")
	check(absf(CropMath.brush(plant, Vector2(90, 100), 4)) <= CropMath.BRUSH_LEAN)

func test_rain_darkens_dry_soil_more() -> void:
	check_eq(CropMath.rain_darken(0.0, false), 1.0)
	check(CropMath.rain_darken(1.0, false) < CropMath.rain_darken(1.0, true))
	check(CropMath.rain_darken(1.0, true) > 0.85 and CropMath.rain_darken(2.0, false) >= 0.7)
