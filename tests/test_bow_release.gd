extends BaseTest

func test_perfect_window_opens_at_full_draw_and_closes() -> void:
	check(not BowMath.is_perfect(BowMath.DRAW_TIME - 0.05))
	check(BowMath.is_perfect(BowMath.DRAW_TIME))
	check(BowMath.is_perfect(BowMath.DRAW_TIME + BowMath.PERFECT_WINDOW - 0.01))
	check(not BowMath.is_perfect(BowMath.DRAW_TIME + BowMath.PERFECT_WINDOW + 0.05))

func test_perfect_arrow_hits_harder_flies_faster_and_drifts_less() -> void:
	var plain := BowMath.launch(Vector2.ZERO, Vector2.RIGHT, 1.0)
	var gold := BowMath.perfect(plain)
	check(float(gold["dmg"]) > float(plain["dmg"]) * 1.3)
	check((gold["vel"] as Vector2).x > (plain["vel"] as Vector2).x)
	check(not plain.has("perfect"), "input untouched")
	var wind := Vector2(0, 110)
	var a := BowMath.step(plain, wind, 0.2)
	var b := BowMath.step(gold, wind, 0.2)
	check((b["pos"] as Vector2).y < (a["pos"] as Vector2).y * 0.5)

func test_arm_only_shakes_after_holding_long() -> void:
	check_eq(BowMath.sway(1.0), 0.0)
	check_eq(BowMath.sway(BowMath.TIRE_AFTER), 0.0)
	var worst := 0.0
	var early := 0.0
	for i in 300:
		worst = maxf(worst, absf(BowMath.sway(BowMath.TIRE_FULL + i * 0.01)))
		early = maxf(early, absf(BowMath.sway(BowMath.TIRE_AFTER + i * 0.001)))
	check(worst > 0.08 and worst <= BowMath.SWAY_MAX + 0.0001)
	check(early < worst * 0.5)

func test_impact_styles_differ() -> void:
	check(ImpactFx.style("game")["color"] != ImpactFx.style("wood")["color"])
	check(int(ImpactFx.style("ground")["n"]) < int(ImpactFx.style("wood")["n"]))
