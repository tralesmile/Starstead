extends BaseTest

func test_hysteresis_stops_flapping() -> void:
	check(not DoorMath.wants_open(48.0, false))
	check(DoorMath.wants_open(48.0, true))
	check(DoorMath.wants_open(30.0, false))
	check(not DoorMath.wants_open(60.0, true))

func test_swing_timing_and_clamp() -> void:
	var o := 0.0
	for i in 10:
		o = DoorMath.step(o, true, 1.0 / 60.0)
	check(is_equal_approx(o, 1.0), "open within a sixth of a second")
	for i in 10:
		o = DoorMath.step(o, false, 1.0 / 60.0)
	check(o > 0.4 and o < 0.6, "shuts slower than it opens, got %f" % o)
	check_eq(DoorMath.step(0.0, false, 1.0), 0.0)

func test_frames_cover_the_sheet() -> void:
	check_eq(DoorMath.frame(0.0), 0)
	check_eq(DoorMath.frame(1.0), DoorMath.FRAMES - 1)
	check_eq(DoorMath.frame(2.0), DoorMath.FRAMES - 1)
	var img: Texture2D = load("res://assets/sprites/build_door_anim.png")
	check_eq(img.get_width(), DoorMath.FRAMES * 32)
	check_eq(img.get_height(), 48)
