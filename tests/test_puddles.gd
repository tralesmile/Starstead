extends BaseTest

func test_field_tiles_and_matches_texture() -> void:
	var a := PuddleMath.noise_at(Vector2(100, 60))
	var span := float(PuddleMath.TEXELS * PuddleMath.TEXEL_PX)
	check(is_equal_approx(a, PuddleMath.noise_at(Vector2(100 + span, 60 - span))), "repeats")
	# the shader's filter_linear lookup at the pixel centre (100.5, 60.5), done by hand on the same texture
	var img := PuddleMath.texture().get_image()
	var u := 100.5 / 4.0 - 0.5
	var v := 60.5 / 4.0 - 0.5
	var top := lerpf(img.get_pixel(24, 14).r, img.get_pixel(25, 14).r, u - 24.0)
	var low := lerpf(img.get_pixel(24, 15).r, img.get_pixel(25, 15).r, u - 24.0)
	check(absf(lerpf(top, low, v - 14.0) - a) < 0.003, "shader texture gives the same value")

func test_outline_is_smooth_and_pixel_snapped() -> void:
	check(PuddleMath.noise_at(Vector2(101.0, 61.0)) == PuddleMath.noise_at(Vector2(101.9, 61.9)), "one value per art pixel")
	var worst := 0.0
	for x in 600:
		worst = maxf(worst, absf(PuddleMath.noise_at(Vector2(x + 1, 77)) - PuddleMath.noise_at(Vector2(x, 77))))
	check(worst < 0.2, "no 4px stair steps, worst jump %.3f" % worst)

func test_reflection_gloss() -> void:
	var water := PuddleMath.gloss(WorldGen.ASPHALT, 1.0, 1.0)
	var road := PuddleMath.gloss(WorldGen.ASPHALT, 0.0, 1.0)
	check(water > road and road > PuddleMath.gloss(WorldGen.PATH, 0.0, 1.0), "water mirrors best, then asphalt, then mud")
	check(PuddleMath.gloss(WorldGen.GRASS, 1.0, 1.0) == 0.0, "grass does not shine")
	check(PuddleMath.gloss(WorldGen.ASPHALT, 1.0, 0.0) == 0.0, "nor does dry ground")

func test_streak_shape() -> void:
	check(PuddleMath.streak_profile(0.0) == 0.0 and PuddleMath.streak_profile(1.0) == 0.0, "fades at both ends")
	check(PuddleMath.streak_profile(0.28) > 0.9 and PuddleMath.streak_profile(0.8) < 0.4, "bright near the lamp, long tail")
	check(PuddleMath.streak_length(44.0) > PuddleMath.streak_length(20.0), "taller lamps, longer streaks")
	check(PuddleMath.streak_length(500.0) <= 140.0, "capped")
	var moved := false
	for y in range(0, 100, 2):
		var w := PuddleMath.streak_wobble(float(y), 1.0, 0.0)
		check(w == roundf(w) and absf(w) <= 4.0, "wobble is whole pixels and small")
		moved = moved or w != PuddleMath.streak_wobble(float(y), 1.4, 0.0)
		var d := PuddleMath.streak_dash(float(y), 2.0, 1.0)
		check(d >= 0.0 and d <= 1.0, "dash in range")
	check(moved, "it wavers over time")

func test_puddles_cover_a_sensible_share_of_ground() -> void:
	var f := PuddleMath.field()
	var n := 0
	for v in f:
		if PuddleMath.mask_of(v, 1.0) >= PuddleMath.SEEN:
			n += 1
	var share := float(n) / f.size()
	check(share > 0.05 and share < 0.30, "share %.3f" % share)
	check(PuddleMath.mask_of(1.0, 0.0) == 0.0, "dry weather, no puddles")

func test_capable_ground() -> void:
	check(PuddleMath.capable(WorldGen.PATH) and PuddleMath.capable(WorldGen.ASPHALT), "path and asphalt")
	check(not PuddleMath.capable(WorldGen.GRASS) and not PuddleMath.capable(WorldGen.WATER_DEEP), "not grass or water")

func test_footfall_splash() -> void:
	check(PuddleMath.step_drops(120.0, 0.0) == 0, "dry")
	check(PuddleMath.step_drops(10.0, 1.0) == 0, "creeping")
	check(PuddleMath.step_drops(170.0, 1.0) > PuddleMath.step_drops(80.0, 1.0), "running throws more")

func test_wheels_drag_and_aquaplane() -> void:
	check(PuddleMath.wheel_drag(30.0, 1.0) == 0.0 and PuddleMath.wheel_drag(200.0, 0.0) == 0.0, "none slow or dry")
	check(PuddleMath.wheel_drag(220.0, 1.0) > PuddleMath.wheel_drag(100.0, 1.0), "faster drags more")
	check(exp(-PuddleMath.wheel_drag(300.0, 1.0)) > 0.7, "a puddle never stops the car")
	check(PuddleMath.aquaplane_grip(100.0, 1.0) == 1.0, "full grip when slow")
	check(is_equal_approx(PuddleMath.aquaplane_grip(300.0, 1.0), 0.6), "worst grip 60%")
	check(PuddleMath.spray_amount(20.0, 1.0) == 0 and PuddleMath.spray_amount(200.0, 1.0) > 0, "spray")

func test_ground_stays_wet_after_the_rain() -> void:
	check(WeatherMath.ground_wet(0.0, 960.0) == 0.0 and WeatherMath.ground_wet(1.0, 100.0) == 0.0, "clear day / before the rain")
	check(WeatherMath.ground_wet(1.0, 400.0) == 1.0, "soaked while raining")
	check(WeatherMath.rain_now(1.0, 960.0) == 0.0 and WeatherMath.ground_wet(1.0, 960.0) > 0.6, "22:00: dry sky, wet street")
	check(WeatherMath.ground_wet(1.0, 1200.0) < WeatherMath.ground_wet(1.0, 960.0), "slowly drying")
