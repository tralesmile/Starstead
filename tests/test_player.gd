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
