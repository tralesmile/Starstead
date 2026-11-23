extends BaseTest

func test_puffs_grow_with_sprint_and_snow() -> void:
	check_eq(AmbientMath.step_puffs(1, false), 3)
	check(AmbientMath.step_puffs(1, true) > AmbientMath.step_puffs(1, false))
	check(AmbientMath.step_puffs(3, false) > AmbientMath.step_puffs(1, false))
	check_eq(AmbientMath.step_puffs(7, true), 8)
