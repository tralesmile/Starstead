extends BaseTest

func test_no_slide_at_walking_pace() -> void:
	check_eq(PlayerMath.brake_slide(0.0), 1.0)
	check_eq(PlayerMath.brake_slide(PlayerMath.SPEED), 1.0)

func test_full_slide_at_sprint() -> void:
	check(absf(PlayerMath.brake_slide(PlayerMath.SPEED * PlayerMath.SPRINT_MULT) - PlayerMath.SLIDE_MIN_FRICTION) < 0.001)
	check(absf(PlayerMath.brake_slide(9999.0) - PlayerMath.SLIDE_MIN_FRICTION) < 0.001)

func test_monotonic() -> void:
	var prev := 2.0
	for i in 40:
		var f := PlayerMath.brake_slide(float(i) * 4.0)
		check(f <= prev + 0.0001)
		prev = f

func _stop_distance(v0: float) -> float:
	var v := Vector2(v0, 0)
	var d := 0.0
	var dt := 1.0 / 60.0
	while v.length() > 0.1:
		v = PlayerMath.accelerate(v, Vector2.ZERO, dt)
		d += v.length() * dt
	return d

func test_sprint_stop_slides_but_stays_short() -> void:
	var walk := _stop_distance(PlayerMath.SPEED)
	var sprint := _stop_distance(PlayerMath.SPEED * PlayerMath.SPRINT_MULT)
	check(sprint > walk * 2.0)   # a visible slide
	check(sprint < 24.0)         # still under a cell: no ice-skating, collision unaffected
