extends BaseTest

func test_speed_scales_and_escapable() -> void:
	check(PoliceModel.speed(1) < 100.0)
	check(PoliceModel.speed(5) > PoliceModel.speed(1))

func test_step_and_arrest() -> void:
	var p := PoliceModel.step(Vector2.ZERO, Vector2(100, 0), 1, 1.0)
	check_eq(p, Vector2(PoliceModel.speed(1), 0))
	check(PoliceModel.arrests(Vector2(5, 0), Vector2.ZERO))
	check(not PoliceModel.arrests(Vector2(50, 0), Vector2.ZERO))

func test_spawn_ring_and_sight() -> void:
	var pts := PoliceModel.spawn_positions(Vector2(100, 100), 4)
	check_eq(pts.size(), 4)
	for q in pts:
		check_eq(snappedf((q - Vector2(100, 100)).length(), 0.01), PoliceModel.SPAWN_RING)
	check(not PoliceModel.sees(Vector2(1000, 0), Vector2.ZERO))
	check(PoliceModel.witnessed([Vector2(50, 0)], Vector2.ZERO))
	check(not PoliceModel.witnessed([], Vector2.ZERO))
