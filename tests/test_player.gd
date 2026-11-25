extends BaseTest

func test_diagonal_not_faster() -> void:
	var v := PlayerMath.velocity(Vector2(1, 1))
	check(absf(v.length() - PlayerMath.SPEED) < 0.01, "diag speed")
	check(PlayerMath.velocity(Vector2.ZERO) == Vector2.ZERO, "idle")
	check(absf(PlayerMath.velocity(Vector2(1, 0)).x - PlayerMath.SPEED) < 0.01, "straight")

func test_facing() -> void:
	check(PlayerMath.facing_for(Vector2(1, 0.2), 0) == PlayerMath.Facing.RIGHT, "right")
	check(PlayerMath.facing_for(Vector2(-1, 0), 0) == PlayerMath.Facing.LEFT, "left")
	check(PlayerMath.facing_for(Vector2(0, -1), 0) == PlayerMath.Facing.UP, "up")
	check(PlayerMath.facing_for(Vector2(0, 1), 2) == PlayerMath.Facing.DOWN, "down")
	check(PlayerMath.facing_for(Vector2.ZERO, 2) == 2, "keeps")
	check(PlayerMath.facing_for(Vector2(1, 1), 1) == 1, "diag keeps")

func test_walk_frame_and_tile() -> void:
	check(PlayerMath.walk_frame(1.0, false) == 0, "idle frame")
	check(PlayerMath.walk_frame(0.0, true) == 1, "step frame")
	check(PlayerMath.facing_tile(Vector2(40, 40), PlayerMath.Facing.RIGHT) == Vector2i(2, 1), "facing tile")
	check(PlayerMath.facing_tile(Vector2(40, 40), PlayerMath.Facing.UP) == Vector2i(1, 0), "facing up")

func test_accel_and_friction() -> void:
	var v := Vector2.ZERO
	v = PlayerMath.accelerate(v, Vector2(1, 0), 1.0 / 60.0)
	check(v.x > 0.0 and v.x < PlayerMath.SPEED, "ramps up, not instant")
	for i in 12:
		v = PlayerMath.accelerate(v, Vector2(1, 0), 1.0 / 60.0)
	check(absf(v.x - PlayerMath.SPEED) < 0.01, "reaches full speed within ~0.2s")
	for i in 6:
		v = PlayerMath.accelerate(v, Vector2.ZERO, 1.0 / 60.0)
	check(v == Vector2.ZERO, "stops quickly with friction")
	var d := PlayerMath.accelerate(Vector2.ZERO, Vector2(1, 1), 10.0)
	check(absf(d.length() - PlayerMath.SPEED) < 0.01, "diagonal capped")

func test_walk_frame_hd() -> void:
	check_eq(PlayerMath.walk_frame_hd(3.0, false), 0)
	var seen := {}
	for i in 12:
		seen[PlayerMath.walk_frame_hd(i * 0.1, true)] = true
	check_eq(seen.size(), 6, "all six walk frames used")
	check(not seen.has(0) and not seen.has(7), "walk never shows idle/tool frames")

func test_slide_dust() -> void:
	var sprint := PlayerMath.SPEED * PlayerMath.SPRINT_MULT
	check(PlayerMath.slide_dust_amount(sprint, 0.0) >= 1)
	check_eq(PlayerMath.slide_dust_amount(sprint, 1.0), 0, "still pushing: no slide")
	check_eq(PlayerMath.slide_dust_amount(PlayerMath.SPEED, 0.0), 0, "walking pace stops cleanly")
	check(PlayerMath.slide_dust_amount(sprint, 0.0) >= PlayerMath.slide_dust_amount(PlayerMath.SPEED * 1.3, 0.0))
