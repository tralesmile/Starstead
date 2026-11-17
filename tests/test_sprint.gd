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
