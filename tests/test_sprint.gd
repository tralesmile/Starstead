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
