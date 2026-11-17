extends BaseTest

func test_walking_look_unchanged() -> void:
	check_eq(CameraMath.look_for_speed(PlayerMath.SPEED), CameraMath.LOOK)
	check_eq(CameraMath.look_for_speed(0.0), 0.0)

func test_car_looks_further_but_capped() -> void:
	check(CameraMath.look_for_speed(200.0) > CameraMath.LOOK)
	check_eq(CameraMath.look_for_speed(300.0), CameraMath.FAST_LOOK_MAX)
	check_eq(CameraMath.look_for_speed(900.0), CameraMath.FAST_LOOK_MAX)

func test_box_shrinks_with_speed() -> void:
	check_eq(CameraMath.box_for_speed(80.0), Vector2(10, 7))
	check_eq(CameraMath.box_for_speed(300.0), Vector2(2, 1))
	check(CameraMath.box_for_speed(160.0).x < 10.0)

func test_look_vec_points_along_velocity() -> void:
	var v := CameraMath.look_vec(Vector2(0, -300))
	check_eq(v, Vector2(0, -CameraMath.FAST_LOOK_MAX))
	check_eq(CameraMath.look_vec(Vector2.ZERO), Vector2.ZERO)
