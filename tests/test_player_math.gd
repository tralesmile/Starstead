extends BaseTest

func test_bump_impact_head_on_only() -> void:
	var sprint := Vector2(PlayerMath.SPEED * 1.8, 0)
	check_eq(PlayerMath.bump_impact(sprint, Vector2.ZERO), sprint.length())
	check_eq(PlayerMath.bump_impact(sprint, Vector2(sprint.x * 0.8, 20)), 0.0)   # glancing slide
	check_eq(PlayerMath.bump_impact(Vector2(PlayerMath.SPEED, 0), Vector2.ZERO), 0.0)   # walking never stumbles

func test_stumble_scales_and_eases() -> void:
	check_eq(PlayerMath.stumble(0.0)["stagger"], 0.0)
	var a := PlayerMath.stumble(80.0)
	var b := PlayerMath.stumble(160.0)
	check(float(b["stagger"]) > float(a["stagger"]))
	check(float(b["shake"]) > float(a["shake"]))
	check(int(b["dust"]) >= int(a["dust"]))
	check_eq(PlayerMath.stagger_mult(0.0, 0.4), 1.0)
	check_eq(PlayerMath.stagger_mult(0.4, 0.4), 0.55)
	var mid := PlayerMath.stagger_mult(0.2, 0.4)
	check(mid > 0.55 and mid < 1.0)
