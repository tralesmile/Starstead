extends BaseTest

func test_level_range() -> void:
	check_eq(CameraMath.sprint_level(1.0, PlayerMath.SPRINT_MULT), 0.0)
	check(is_equal_approx(CameraMath.sprint_level(PlayerMath.SPRINT_MULT, PlayerMath.SPRINT_MULT), 1.0))
	check(CameraMath.sprint_level(5.0, PlayerMath.SPRINT_MULT) == 1.0, "clamped")
	check_eq(CameraMath.sprint_level(1.2, 1.0), 0.0, "no sprint configured")

func test_zoom_out_only() -> void:
	check_eq(CameraMath.sprint_zoom(0.0, 0.0), 1.0, "walking = no change")
	var run := CameraMath.sprint_zoom(1.0, 0.0)
	check(run < 1.0 and run > 0.9, "slight zoom out while sprinting")
	check(CameraMath.sprint_zoom(1.0, 1.0) < run, "punch adds a kick")
	check(CameraMath.sprint_zoom(-3.0, -3.0) <= 1.0, "never zooms in")
	check(CameraMath.sprint_zoom(9.0, 9.0) >= 0.9, "bounded")

func test_punch_triggers_once_and_decays() -> void:
	check(CameraMath.sprint_starts(0.0, 0.3))
	check(not CameraMath.sprint_starts(0.3, 0.6), "already sprinting")
	var p := 1.0
	for i in 30:
		p = CameraMath.punch_decay(p, 1.0 / 60.0)
	check(p < 0.02, "gone in half a second")
	check(p > 0.0)
