extends BaseTest

func test_field_tiles_and_matches_texture() -> void:
	var a := PuddleMath.noise_at(Vector2(100, 60))
	var span := float(PuddleMath.TEXELS * PuddleMath.TEXEL_PX)
	check(is_equal_approx(a, PuddleMath.noise_at(Vector2(100 + span, 60 - span))), "repeats")
	var img := PuddleMath.texture().get_image()
	check(absf(img.get_pixel(25, 15).r - a) < 0.003, "shader texture holds the same value")

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
