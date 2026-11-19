extends BaseTest

func test_swing_slow() -> void:
	check_eq(PlayerMath.swing_slow(0.0), 1.0)
	check_eq(PlayerMath.swing_slow(-0.1), 1.0)
	check(absf(PlayerMath.swing_slow(0.18) - 0.35) < 0.001, "planted feet during the swing")
	var mid := PlayerMath.swing_slow(0.03)
	check(mid > 0.35 and mid < 1.0, "eases back")

func test_tool_plant() -> void:
	check(PlayerMath.tool_plant("axe") < PlayerMath.tool_plant("hoe"), "axe plants harder than the hoe")
	check(PlayerMath.tool_plant("hoe") < PlayerMath.tool_plant("rod"), "hoe plants harder than the rod")
	check(PlayerMath.tool_plant("axe_copper") == 0.35, "tiered axes are heavy")
	check(PlayerMath.tool_plant("pickaxe_iron") == 0.35, "tiered pickaxes are heavy")
	check(absf(PlayerMath.swing_slow(0.18, PlayerMath.tool_plant("rod")) - 0.85) < 0.001, "rod swing barely slows")
	check_eq(PlayerMath.swing_slow(0.0, 0.1), 1.0)
