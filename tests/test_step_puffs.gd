extends BaseTest

func test_puffs_grow_with_sprint_and_snow() -> void:
	check_eq(AmbientMath.step_puffs(1, false), 3)
	check(AmbientMath.step_puffs(1, true) > AmbientMath.step_puffs(1, false))
	check(AmbientMath.step_puffs(3, false) > AmbientMath.step_puffs(1, false))
	check_eq(AmbientMath.step_puffs(7, true), 8)

func test_dust_colour_by_ground() -> void:
	var grass := AmbientMath.step_dust_color(0, 1)
	var dirt := AmbientMath.step_dust_color(3, 1)
	var asph := AmbientMath.step_dust_color(11, 1)
	check(grass.g > grass.r, "grass dust is green")
	check(dirt.r > dirt.b, "dirt dust is tan")
	check(absf(asph.r - asph.b) < 0.1, "asphalt dust is grey")
	check(AmbientMath.step_dust_color(0, 3).b > 0.9, "winter dust is white")

func test_load_mult() -> void:
	check_eq(PlayerMath.load_mult(0.5), 1.0)
	check_eq(PlayerMath.load_mult(0.8), 1.0)
	check(absf(PlayerMath.load_mult(1.0) - 0.9) < 0.001)
	check(PlayerMath.load_mult(0.9) < 1.0 and PlayerMath.load_mult(0.9) > 0.9)
