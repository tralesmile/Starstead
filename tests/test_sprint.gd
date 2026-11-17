extends BaseTest

func test_sprint_rules() -> void:
	check_eq(PlayerMath.sprint_mult(true, true, 50.0), PlayerMath.SPRINT_MULT)
	check_eq(PlayerMath.sprint_mult(true, false, 50.0), 1.0)
	check_eq(PlayerMath.sprint_mult(true, true, 0.5), 1.0)
	check_eq(PlayerMath.sprint_mult(false, true, 50.0), 1.0)
	check(PlayerMath.sprint_cost(1.0) > 0.0)

func test_cops_catch_walker_not_sprinter() -> void:
	check(PoliceModel.speed(5) > PlayerMath.SPEED)
	check(PoliceModel.speed(5) < PlayerMath.SPEED * PlayerMath.SPRINT_MULT)
	check(PoliceModel.speed(1) < PlayerMath.SPEED)

func test_ride_grip() -> void:
	check_eq(PlayerMath.ride_grip(1.0), 1.0)
	check(PlayerMath.ride_grip(1.8) < 0.7)
	check(PlayerMath.ride_grip(9.0) >= 0.45)
	# slippery riding still reaches speed but takes longer to stop
	var v := Vector2(100, 0)
	var on_foot := PlayerMath.accelerate(v, Vector2.ZERO, 0.1, PlayerMath.SPEED, 1.0)
	var riding := PlayerMath.accelerate(v, Vector2.ZERO, 0.1, PlayerMath.SPEED, PlayerMath.ride_grip(1.8))
	check(riding.x > on_foot.x)

func test_sprint_ease_ramps() -> void:
	var m := 1.0
	m = PlayerMath.sprint_ease(m, PlayerMath.SPRINT_MULT, 0.05)
	check(m > 1.0 and m < PlayerMath.SPRINT_MULT)
	for i in 20:
		m = PlayerMath.sprint_ease(m, PlayerMath.SPRINT_MULT, 0.05)
	check_eq(m, PlayerMath.SPRINT_MULT)
	check(PlayerMath.sprint_ease(PlayerMath.SPRINT_MULT, 1.0, 0.05) < PlayerMath.SPRINT_MULT)
	check_eq(PlayerMath.sprint_ease(1.0, 1.0, 0.1), 1.0)

func test_skid_detection() -> void:
	check(PlayerMath.is_skid(Vector2(90, 0), Vector2(-1, 0)))
	check(not PlayerMath.is_skid(Vector2(90, 0), Vector2(1, 0)))
	check(not PlayerMath.is_skid(Vector2(90, 0), Vector2(0, 1)))  # sideways turn is not a skid
	check(not PlayerMath.is_skid(Vector2(20, 0), Vector2(-1, 0)))  # too slow
	check(not PlayerMath.is_skid(Vector2(90, 0), Vector2.ZERO))
	check(PlayerMath.skid_dust_amount(130.0) > PlayerMath.skid_dust_amount(60.0))
	check(PlayerMath.skid_dust_amount(1000.0) <= 8)
