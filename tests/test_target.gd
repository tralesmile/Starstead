extends BaseTest

func test_cell_and_reach() -> void:
	check_eq(TargetMath.cell_of(Vector2(65, -1)), Vector2i(2, -1))
	var p := Vector2(100, 100)
	check(TargetMath.in_reach(p, Vector2i(3, 3)))
	check(not TargetMath.in_reach(p, Vector2i(10, 3)))

func test_facing_toward() -> void:
	var p := Vector2(16 + 32 * 5, 16 + 32 * 5 + 8)  # chest is the centre of tile (5,5)
	check_eq(TargetMath.facing_toward(p, Vector2i(8, 5), PlayerMath.Facing.DOWN), PlayerMath.Facing.RIGHT)
	check_eq(TargetMath.facing_toward(p, Vector2i(2, 5), PlayerMath.Facing.DOWN), PlayerMath.Facing.LEFT)
	check_eq(TargetMath.facing_toward(p, Vector2i(5, 2), PlayerMath.Facing.DOWN), PlayerMath.Facing.UP)
	check_eq(TargetMath.facing_toward(p, Vector2i(5, 8), PlayerMath.Facing.UP), PlayerMath.Facing.DOWN)
	check_eq(TargetMath.facing_toward(p, Vector2i(5, 5), PlayerMath.Facing.UP), PlayerMath.Facing.UP)

func test_cycle_and_zoom() -> void:
	check_eq(TargetMath.cycle(0, -1, 8), 7)
	check_eq(TargetMath.cycle(7, 1, 8), 0)
	check_eq(TargetMath.effective_zoom(2, -1), 1)
	check_eq(TargetMath.effective_zoom(1, -1), 1)
	check_eq(TargetMath.effective_zoom(3, 0), 3)
	check_eq(TargetMath.zoom_step(4, 1), 4)
	check_eq(TargetMath.zoom_value(TargetMath.DEFAULT_STEP), 1.5, "default view is zoomed out from 2x")
	check_eq(TargetMath.step_for_zoom(3.0), 4)
	check_eq(TargetMath.step_for_zoom(1.0), 1)
	check_eq(TargetMath.zoom_step(1, -1), 1)

func test_hotbar_number_keys() -> void:
	check_eq(TargetMath.key_slot(KEY_1), 0)
	check_eq(TargetMath.key_slot(KEY_9), 8)
	check_eq(TargetMath.key_slot(KEY_0), 9)
	check_eq(TargetMath.key_slot(KEY_A), -1)
