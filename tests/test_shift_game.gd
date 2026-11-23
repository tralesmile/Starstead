extends BaseTest

func test_triangle_wave_and_timing_score() -> void:
	check(is_equal_approx(ShiftGame.tri(0.0), 0.0) and is_equal_approx(ShiftGame.tri(1.0), 1.0) and is_equal_approx(ShiftGame.tri(1.5), 0.5) and is_equal_approx(ShiftGame.tri(2.0), 0.0), "triangle")
	check(ShiftGame.timing_score(0.5, 0.5, 0.15) == 1.0, "centre")
	check(ShiftGame.timing_score(0.6, 0.5, 0.15) == 0.6, "edge")
	check(ShiftGame.timing_score(0.9, 0.5, 0.15) == 0.0, "miss")

func test_multiplier_and_grades() -> void:
	check(is_equal_approx(ShiftGame.multiplier(0.0), 0.7) and is_equal_approx(ShiftGame.multiplier(1.0), 1.3), "range")
	check(ShiftGame.multiplier(5.0) == 1.3 and ShiftGame.multiplier(-1.0) == 0.7, "clamped")
	check(ShiftGame.grade_of(0.95) == "Perfect!" and ShiftGame.grade_of(0.1) == "Sloppy", "grades")

func test_timing_perfect_run_when_pressed_in_the_zone() -> void:
	var g := ShiftGame.new("timing", 0, 3)
	var guard := 0
	while not g.done and guard < 4000:
		guard += 1
		if absf(g.marker() - g.center) < 0.01:
			g.press_action()
		g.step(0.005)
	check(g.done and g.scores.size() == ShiftGame.TIMING_ROUNDS, "five rounds")
	check(g.score() >= 0.9, "centred presses score high: %f" % g.score())
	check(bool(g.result()["perfect"]) and int(g.result()["bonus_xp"]) == 5, "perfect bonus")

func test_timing_idle_scores_zero_and_wider_zone_for_rank() -> void:
	var g := ShiftGame.new("timing", 0, 3)
	for i in 3400:
		g.step(0.01)
	check(g.done and g.score() == 0.0, "never pressing pays the floor")
	check(is_equal_approx(float(g.result()["mult"]), 0.7), "x0.7")
	check(ShiftGame.new("timing", 2, 1).half > ShiftGame.new("timing", 0, 1).half, "rank widens the zone")

func test_sequence_correct_and_wrong() -> void:
	var g := ShiftGame.new("sequence", 1, 5)
	for r in ShiftGame.SEQ_ROUNDS:
		var n := g.seq.size()
		check(n == ShiftGame.seq_length(1, r), "length grows")
		for d in g.seq.duplicate():
			g.press_dir(d)
		g.step(0.001)
	check(g.done and g.score() > 0.9, "all right = near full %f" % g.score())
	var b := ShiftGame.new("sequence", 0, 5)
	var wrong := (b.seq[0] + 1) % 4
	b.press_dir(wrong)
	check(b.scores.size() == 1 and b.scores[0] == 0.0, "wrong first key ends the round at 0")

func test_sequence_timeout_gives_partial() -> void:
	var g := ShiftGame.new("sequence", 0, 2)
	g.press_dir(g.seq[0])
	g.step(g.seq_limit + 0.1)
	check(g.scores.size() == 1 and g.scores[0] > 0.0 and g.scores[0] < 0.5, "partial credit")

func test_balance_physics() -> void:
	var r := ShiftGame.balance_step(0.0, 0.0, 1.0, 0.0, 0.1)
	check(r["vel"] > 0.0 and r["needle"] > 0.0, "right input pushes right")
	var w := ShiftGame.balance_step(0.99, 5.0, 1.0, 0.0, 0.1)
	check(w["needle"] == 1.0 and w["vel"] == 0.0, "wall stops it")
	check(ShiftGame.drift_at(1.0, 4) != ShiftGame.drift_at(1.0, 5), "drift depends on seed")

func test_balance_controller_beats_doing_nothing() -> void:
	var good := ShiftGame.new("balance", 0, 11)
	var idle := ShiftGame.new("balance", 0, 11)
	for i in 900:
		var inp := 0.0
		if good.needle > 0.08:
			inp = -1.0
		elif good.needle < -0.08:
			inp = 1.0
		good.step(0.01, inp)
		idle.step(0.01, 0.0)
	check(good.done and idle.done, "both finished")
	check(good.score() > idle.score() and good.score() > 0.7, "steering holds the zone %f vs %f" % [good.score(), idle.score()])

func test_every_job_has_a_known_game() -> void:
	var jobs: Dictionary = DataDB.load_json("jobs")
	for id in jobs:
		check(String(jobs[id].get("game", "")) in ["timing", "sequence", "balance"], id + " has a game")
		check(ShiftGame.title_for(id, String(jobs[id]["game"])) != "", id + " has a title")

func test_tired_drag_and_perching_crows() -> void:
	check(PlayerMath.tired_mult(100.0) == 1.0 and PlayerMath.tired_mult(25.0) == 1.0, "no drag when rested")
	check(is_equal_approx(PlayerMath.tired_mult(0.0), 0.8) and PlayerMath.tired_mult(12.5) < 1.0 and PlayerMath.tired_mult(12.5) > 0.8, "eases down to 0.8")
	check(CrowMath.perch_window(120.0) and not CrowMath.perch_window(30.0) and not CrowMath.perch_window(700.0), "daytime only")
	var ripe: Array = []
	for i in 10:
		ripe.append(Vector2i(i, 2))
	var a := CrowMath.perch_cells(ripe, 4)
	check(a.size() == CrowMath.PERCH_MAX and a == CrowMath.perch_cells(ripe, 4), "max three, deterministic")
	check(CrowMath.perch_cells([Vector2i(1, 1)], 2).size() == 1, "fewer ripe than max")
	check(CrowMath.startled(Vector2.ZERO, Vector2(40, 0)) and not CrowMath.startled(Vector2.ZERO, Vector2(120, 0)), "scare distance")
	var f1 := CrowMath.flee_offset(1, 0.5, Vector2.RIGHT)
	check(f1.x > 40.0 and f1.y < -20.0, "flees up and away")
	check(CrowMath.flee_alpha(0.0) == 1.0 and CrowMath.flee_alpha(CrowMath.FLEE_TIME) == 0.0, "fades out")
	check(CrowMath.peck(0, 0.0) >= 0.0 and CrowMath.peck(0, 0.5) == 0.0, "peck is brief")

func test_minigame_pay_range_keeps_the_rank_ladder_sane() -> void:
	var m := JobModel.new(DataDB.load_json("jobs"))
	for id in m.ids():
		var base := float(m.shift_pay(id, 0))
		var top_rank_xp := int(m.jobs[id]["ranks"][2]["xp"])
		var worst_top := float(m.shift_pay(id, top_rank_xp)) * ShiftGame.PAY_MIN
		var best_entry := base * ShiftGame.PAY_MAX
		check(worst_top > base * 0.95, id + ": a sloppy top-rank shift still pays about the entry wage")
		check(best_entry < float(m.shift_pay(id, top_rank_xp)) * 1.0, id + ": perfect entry shift stays under a normal top-rank shift")
