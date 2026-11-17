extends BaseTest

func test_hour_of() -> void:
	check(is_equal_approx(NpcSchedule.hour_of(0.0), 6.0))
	check(is_equal_approx(NpcSchedule.hour_of(18.0 * 60.0), 0.0))

func test_facing_of() -> void:
	check(NpcSchedule.facing_of(Vector2(5, 1), 0) == 3)
	check(NpcSchedule.facing_of(Vector2(-5, 1), 0) == 1)
	check(NpcSchedule.facing_of(Vector2(0, -3), 0) == 2)
	check(NpcSchedule.facing_of(Vector2.ZERO, 2) == 2)

func test_safe_step_slides() -> void:
	var land := func(p: Vector2) -> bool: return p.x < 10.0 # wall at x=10
	var p := NpcSchedule.safe_step(Vector2(9, 0), Vector2(20, 20), 100.0, 0.1, land)
	check(p.x < 10.0)
	check(p.y > 0.0)

func test_snap_to_land() -> void:
	var land := func(c: Vector2i) -> bool: return c.x >= 3
	check(NpcSchedule.snap_to_land(Vector2i(0, 0), land) == Vector2i(3, -3) or NpcSchedule.snap_to_land(Vector2i(0, 0), land).x == 3)
	check(NpcSchedule.snap_to_land(Vector2i(5, 5), land) == Vector2i(5, 5))
