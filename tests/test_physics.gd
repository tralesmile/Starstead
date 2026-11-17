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
