extends BaseTest

func test_steer_scale_understeers_at_speed() -> void:
	check_eq(VehicleMath.steer_scale(0.0), 1.0)
	check(absf(VehicleMath.steer_scale(VehicleMath.MAX_SPEED) - (1.0 - VehicleMath.STEER_LOSS)) < 0.001)
	check(VehicleMath.steer_scale(100.0) > VehicleMath.steer_scale(250.0))
	var slow := VehicleMath.step(Vector2(100, 0), 0.0, 0.0, 1.0, false, 0.1)
	var fast := VehicleMath.step(Vector2(290, 0), 0.0, 0.0, 1.0, false, 0.1)
	check(absf(float(slow["heading"])) > absf(float(fast["heading"])) * 0.9 and float(fast["heading"]) > 0.0)
