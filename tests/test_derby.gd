extends BaseTest

func test_gallop_faster_but_drains() -> void:
	var a := DerbyModel.runner()
	var b := DerbyModel.runner()
	for i in 20:
		DerbyModel.step(a, true, 0.1)
		DerbyModel.step(b, false, 0.1)
	check(float(a["pos"]) > float(b["pos"]))
	check(float(a["stamina"]) < 1.0)
	check_eq(float(b["stamina"]), 1.0)

func test_winded_then_recovers() -> void:
	var r := DerbyModel.runner()
	for i in 60:
		DerbyModel.step(r, true, 0.1)
	check(r["winded"])
	check(DerbyModel.speed(r, true) < DerbyModel.TROT)
	for i in 60:
		DerbyModel.step(r, false, 0.1)
	check(not r["winded"])

func test_constant_gallop_loses_to_pacing() -> void:
	var a := DerbyModel.runner()
	var b := DerbyModel.runner()
	var t := 0.0
	while not DerbyModel.finished(a) or not DerbyModel.finished(b):
		if not DerbyModel.finished(a):
			DerbyModel.step(a, true, 0.05)
		if not DerbyModel.finished(b):
			DerbyModel.step(b, DerbyModel.rival_gallops(b, 0.6), 0.05)
		t += 0.05
		if t > 60.0:
			break
	check(t < 60.0)

func test_place_and_prize() -> void:
	var poss := [400.0, 400.0, 300.0, 120.0]
	var times := [8.0, 7.5, -1.0, -1.0]
	check_eq(DerbyModel.place(poss, times, 1), 0)
	check_eq(DerbyModel.place(poss, times, 0), 1)
	check_eq(DerbyModel.place(poss, times, 2), 2)
	check_eq(DerbyModel.place(poss, times, 3), 3)
	check_eq(DerbyModel.prize(0), 150)
	check_eq(DerbyModel.prize(9), 0)

func test_draft() -> void:
	check_eq(DerbyModel.draft_mult(1.0), 1.0)
	check_eq(DerbyModel.draft_mult(30.0), 1.0)
	check(DerbyModel.draft_mult(4.0) > DerbyModel.draft_mult(15.0))
	check(DerbyModel.draft_mult(4.0) <= 1.07)
	check_eq(DerbyModel.nearest_ahead_gap([10.0, 25.0, 14.0], 0), 4.0)
	check(DerbyModel.nearest_ahead_gap([50.0, 25.0], 0) > 1e8)

func test_bonus_capped() -> void:
	check_eq(DerbyModel.bonus_for(0), 0.0)
	check(DerbyModel.bonus_for(100, 0.5) <= 0.12)
	check(DerbyModel.bonus_for(100) > DerbyModel.bonus_for(10))
