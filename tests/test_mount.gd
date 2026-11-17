extends BaseTest

func test_gallop_drains_rest_regens() -> void:
	var s := 1.0
	for i in 20:
		s = MountMath.step(s, 150.0, 0.5)
	check_eq(s, 0.0)
	for i in 20:
		s = MountMath.step(s, 0.0, 0.5)
	check_eq(s, 1.0)

func test_winded_hysteresis() -> void:
	check(MountMath.winded(0.0, false))
	check(MountMath.winded(0.2, true))
	check(not MountMath.winded(0.5, true))
	check(not MountMath.winded(0.2, false))

func test_winded_slows_to_trot() -> void:
	check_eq(MountMath.speed_scale(true, 2.0), 1.1)
	check_eq(MountMath.speed_scale(false, 2.0), 2.0)
	check_eq(MountMath.speed_scale(true, 1.0), 1.0)
