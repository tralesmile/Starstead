extends BaseTest

func test_knockback_direction_and_zero() -> void:
	var v := HitMath.knockback(Vector2(0, 0), Vector2(10, 0))
	check_eq(v, Vector2(HitMath.KNOCK_SPEED, 0))
	check(HitMath.knockback(Vector2.ONE, Vector2.ONE).is_finite(), "no NaN when overlapping")
	check_eq(HitMath.knockback(Vector2.ZERO, Vector2(5, 0), -3.0), Vector2.ZERO, "negative force clamps")

func test_decay_reaches_zero() -> void:
	var v := Vector2(200, 0)
	for i in 100:
		v = HitMath.decay(v, 0.016)
	check_eq(v, Vector2.ZERO)

func test_hitstop_scales_and_caps() -> void:
	check(HitMath.hitstop(2.0) > HitMath.hitstop(0.5))
	check(HitMath.hitstop(100.0) <= HitMath.HITSTOP_MAX)

func test_shake_fades() -> void:
	check_eq(HitMath.shake_offset(0.0, 0.2, 2.0, 1.0), Vector2.ZERO)
	var o := HitMath.shake_offset(0.1, 0.2, 2.0, 1.0)
	check(absf(o.x) <= 2.0 and absf(o.y) <= 2.0)
	check_eq(o, o.round(), "whole pixels")

func test_terrain_factor() -> void:
	check_eq(PlayerMath.terrain_factor(-0.5, false), 0.6)
	check_eq(PlayerMath.terrain_factor(0.4, true), PlayerMath.WET_BANK_FACTOR)
	check_eq(PlayerMath.terrain_factor(3.0, false), 1.0)
	check_eq(PlayerMath.terrain_factor(3.0, true), PlayerMath.PATH_FACTOR)

func test_footstep_frames() -> void:
	check(PlayerMath.footstep_due(1, 2))
	check(PlayerMath.footstep_due(4, 5))
	check(not PlayerMath.footstep_due(2, 2))
	check(not PlayerMath.footstep_due(2, 3))

func test_mud_slows_and_slides() -> void:
	check_eq(PlayerMath.wet_grip(0.0, true), 1.0)
	check(PlayerMath.wet_grip(1.0, true) < PlayerMath.wet_grip(1.0, false), "path muddier than grass")
	check(PlayerMath.wet_speed(1.0, true) < 1.0 and PlayerMath.wet_speed(1.0, true) > 0.8)
	# braking from full speed takes longer in the mud
	var v := Vector2(PlayerMath.SPEED, 0)
	var dry := PlayerMath.accelerate(v, Vector2.ZERO, 0.05, PlayerMath.SPEED, 1.0)
	var wet := PlayerMath.accelerate(v, Vector2.ZERO, 0.05, PlayerMath.SPEED, PlayerMath.wet_grip(1.0, true))
	check(wet.x > dry.x, "slides further")
	check(wet.x < v.x, "still brakes")
	check_eq(PlayerMath.accelerate(Vector2.ZERO, Vector2.RIGHT, 1.0).x, PlayerMath.SPEED)

func test_swing_angle_and_held_frames() -> void:
	check_eq(HitMath.swing_angle(0.0, 0.18), 0.0)
	check(HitMath.swing_angle(0.179, 0.18) < -0.9)   # starts raised
	check(HitMath.swing_angle(0.01, 0.18) > 0.5)     # ends in the strike
	check_eq(ToolUse.held_frame("axe"), 2)
	check_eq(ToolUse.held_frame("turnip_seed"), -1)
	for t in ["hoe", "watering_can", "axe", "pickaxe", "rod", "club"]:
		check(ToolUse.held_frame(t) >= 0, t)

func test_bobber_math() -> void:
	check(BobberMath.bob(0.5, true) >= 0.0)         # dips below rest when biting
	check(absf(BobberMath.bob(1.3, false)) <= 1.0)
	var a := Vector2(0, 0)
	var b := Vector2(100, 0)
	check_eq(BobberMath.line_point(a, b, 0.0, 8.0), a)
	check_eq(BobberMath.line_point(a, b, 1.0, 8.0), b)
	check(BobberMath.line_point(a, b, 0.5, 8.0).y > 3.0)   # sags in the middle
	check(BobberMath.splash(0.1).y > 0.0)
	check_eq(BobberMath.splash(0.7), Vector2.ZERO)
	check(BobberMath.splash(0.5).x > BobberMath.splash(0.1).x)

func test_car_surface_cap() -> void:
	check_eq(VehicleMath.surface_cap(true, 3.0), 1.0)
	check(VehicleMath.surface_cap(false, 3.0) < 1.0, "grass slower than road")
	check(VehicleMath.surface_cap(false, 3.0, 1.0) < VehicleMath.surface_cap(false, 3.0), "rain slows grass")
	check(VehicleMath.surface_cap(true, 0.3) < VehicleMath.surface_cap(false, 3.0), "wet bank slowest")

func test_car_sidewalk_cap() -> void:
	check_eq(VehicleMath.surface_cap(true, 3.0, 0.0, true), VehicleMath.SIDEWALK_CAP)
	check(VehicleMath.SIDEWALK_CAP < VehicleMath.surface_cap(false, 3.0), "slower than grass")
	check_eq(VehicleMath.surface_cap(true, 3.0, 0.0, false), 1.0)
	check(CityModel.is_sidewalk(Vector2i(190, 10)), "avenue sidewalk")
	check(not CityModel.is_asphalt(Vector2i(190, 10)))

func test_kerb_bump_and_skid_alpha() -> void:
	var slow := VehicleMath.kerb_bump(40.0, 1.0, VehicleMath.SIDEWALK_CAP)
	check_eq(slow["factor"], 1.0, "slow rolls over the kerb")
	var fast := VehicleMath.kerb_bump(260.0, 1.0, VehicleMath.SIDEWALK_CAP)
	check_eq(fast["factor"], 0.75, "fast hit loses a quarter")
	check(float(fast["shake"]) > 1.5, "jolt")
	check_eq(VehicleMath.kerb_bump(260.0, 1.0, 1.0)["factor"], 1.0, "no change on the road")
	check_eq(VehicleMath.kerb_bump(260.0, VehicleMath.SIDEWALK_CAP, VehicleMath.SIDEWALK_CAP)["factor"], 1.0, "already on the sidewalk")
	check(VehicleMath.skid_alpha(WorldGen.ASPHALT, 5.0) > VehicleMath.skid_alpha(WorldGen.PATH, 5.0), "asphalt marks darker")
	check(VehicleMath.skid_alpha(WorldGen.PATH, 5.0) > VehicleMath.skid_alpha(WorldGen.GRASS, 5.0), "grass faintest")
	check(VehicleMath.skid_alpha(WorldGen.ASPHALT, 5.0, 1.0) < VehicleMath.skid_alpha(WorldGen.ASPHALT, 5.0), "rain washes marks")
	check_eq(VehicleMath.skid_alpha(WorldGen.ASPHALT, 0.0), 0.0, "none on the wet bank")

func test_kerb_rumble() -> void:
	check(VehicleMath.rumble(300.0, false)["shake"] == 0.0, "off kerb quiet")
	check(VehicleMath.rumble(40.0, true)["shake"] == 0.0, "slow kerb quiet")
	var r := VehicleMath.rumble(260.0, true)
	check(r["grip"] < 1.0 and r["grip"] >= 0.92 and r["shake"] > 0.5, "fast kerb rattles")
	check(VehicleMath.rumble(260.0, true)["shake"] > VehicleMath.rumble(120.0, true)["shake"], "faster, stronger")

func test_slipstream() -> void:
	check(VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(60, 0), 0.0) > 1.03, "close behind a car")
	check(VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(60, 0), 0.0) > VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(120, 0), 0.0), "closer is better")
	check(VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(200, 0), 0.0) == 1.0, "too far")
	check(VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(-60, 0), 0.0) == 1.0, "car behind you")
	check(VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(60, 0), PI) == 1.0, "oncoming")
	check(VehicleMath.slipstream(Vector2.ZERO, 0.0, Vector2(60, 60), 0.0) == 1.0, "beside, not behind")
