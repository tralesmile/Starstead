extends BaseTest

func test_rod_pose() -> void:
	check(RodMath.charge_deg(0.0) < RodMath.charge_deg(1.0), "charging leans the rod further back")
	check(is_equal_approx(RodMath.charge_deg(2.0), RodMath.BACK_DEG), "power is clamped")
	check(RodMath.swing_deg(0.0) > 140.0, "swing starts from the back-swing")
	check(absf(RodMath.swing_deg(RodMath.SWING_TIME) - RodMath.WAIT_DEG) < 0.5, "swing settles on the waiting angle")
	check(RodMath.hold_deg(0.3, true, false) < RodMath.WAIT_DEG - 5.0, "a bite dips the tip")
	var g := Vector2(10, 0)
	var t := RodMath.tip(g, 1.0, 90.0)
	check(absf(t.x - 10.0) < 0.01 and absf(t.y + RodMath.LEN) < 0.01, "90 degrees points straight up")
	check(RodMath.tip(g, -1.0, 0.0).x < g.x, "left side mirrors the rod")
	check(RodMath.side_for(true, 50.0) == -1.0, "facing left fishes left")
	check(RodMath.side_for(false, -30.0) == -1.0 and RodMath.side_for(false, 0.0) == 1.0, "side follows the target")
