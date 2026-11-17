extends BaseTest

func test_ring_checkpoints_snap_to_ok_cells() -> void:
	var ok := func(c: Vector2i) -> bool: return c.x >= 0 and c.y >= 0 and (c.x + c.y) % 2 == 0
	var cps := RaceModel.ring_checkpoints(Vector2(640, 640), 200.0, 6, ok)
	check_eq(cps.size(), 6)
	for p in cps:
		check(ok.call(Vector2i(floori(p.x / 32.0), floori(p.y / 32.0))))

func test_ring_checkpoints_when_all_ok() -> void:
	var cps := RaceModel.ring_checkpoints(Vector2(640, 640), 160.0, 4, func(_c): return true)
	check(cps[0].distance_to(Vector2(800, 640)) < 32.0)

func test_ai_step_reaches_target() -> void:
	var p := Vector2.ZERO
	for i in 100:
		p = RaceModel.ai_step(p, Vector2(100, 0), 50.0, 0.1)
	check_eq(p, Vector2(100, 0))

func test_rival_and_player_ranking() -> void:
	var m := RaceModel.new([Vector2(0, 0), Vector2(100, 0)], 1, 10.0)
	m.add_racer("me")
	m.add_racer("rival")
	m.update("rival", Vector2(0, 0), 1.0)
	m.update("me", Vector2(500, 500), 1.0)
	check_eq(m.place("rival"), 1)
	check_eq(m.place("me"), 2)
	check_eq(m.payout_for_place(2), 100)
