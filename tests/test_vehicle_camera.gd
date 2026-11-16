extends BaseTest

func _drive(throttle: float, steer: float, hb: bool, secs: float, v := Vector2.ZERO, h := 0.0) -> Dictionary:
	var st := {"vel": v, "heading": h}
	for i in int(secs / 0.016):
		st = VehicleMath.step(st.vel, st.heading, throttle, steer, hb, 0.016)
	return st

func test_accelerates_forward_and_caps() -> void:
	var st := _drive(1.0, 0.0, false, 10.0)
	check(st.vel.x > 100.0 and st.vel.x <= VehicleMath.MAX_SPEED + 0.01, "got %s" % st.vel)
	check(absf(st.vel.y) < 0.01)

func test_no_steer_when_stopped() -> void:
	var st := _drive(0.0, 1.0, false, 1.0)
	check_eq(st.heading, 0.0)

func test_steering_turns_when_moving() -> void:
	var st := _drive(1.0, 1.0, false, 0.6)
	check(st.heading > 0.3, "heading %f" % st.heading)

func test_grip_kills_sideways_velocity() -> void:
	var st := _drive(0.0, 0.0, false, 1.0, Vector2(0, 100.0))  # pure sideways slide
	check(absf(VehicleMath.slip(st.vel, st.heading)) < 5.0)

func test_handbrake_keeps_slide_longer() -> void:
	var grip := _drive(0.0, 0.0, false, 0.3, Vector2(0, 100.0))
	var drift := _drive(0.0, 0.0, true, 0.3, Vector2(0, 100.0))
	check(absf(drift.vel.y) > absf(grip.vel.y) + 10.0, "drift %s grip %s" % [drift.vel, grip.vel])

func test_brake_then_reverse_capped() -> void:
	var st := _drive(-1.0, 0.0, false, 10.0, Vector2(200, 0))
	check(st.vel.x < 0.0 and st.vel.x >= -VehicleMath.REVERSE_MAX - 0.01)

func test_camera_look_ahead_whole_pixels() -> void:
	check_eq(CameraMath.look_target(Vector2(90, 0), 90.0), Vector2(CameraMath.LOOK, 0))
	check_eq(CameraMath.look_target(Vector2(900, 0), 90.0).length(), CameraMath.LOOK)
	check_eq(CameraMath.look_target(Vector2.ZERO, 90.0), Vector2.ZERO)
	check_eq(CameraMath.snap(Vector2(3.6, -2.4)), Vector2(4, -2))
	var o := CameraMath.ease_offset(Vector2.ZERO, Vector2(14, 0), 0.1)
	check(o.x > 0.0 and o.x < 14.0)

func test_camera_clamp() -> void:
	var w := Vector2(2048, 2048)
	check_eq(CameraMath.clamp_to_world(Vector2(10, 10), Vector2(160, 90), w), Vector2(160, 90))
	check_eq(CameraMath.clamp_to_world(Vector2(1000, 1000), Vector2(160, 90), w), Vector2(1000, 1000))
	check_eq(CameraMath.clamp_to_world(Vector2(5, 5), Vector2(2000, 2000), w), Vector2(1024, 1024))
