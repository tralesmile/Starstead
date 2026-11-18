extends BaseTest

func test_no_points_without_drift() -> void:
	var d := DriftScore.new()
	for i in 60:
		check_eq(d.step(10.0, 200.0, 0.016), 0)
	check_eq(d.score, 0.0)

func test_drift_banks_on_exit() -> void:
	var d := DriftScore.new()
	for i in 100:
		d.step(120.0, 220.0, 0.016)
	check(d.score > 20.0, "score builds")
	var banked := d.step(5.0, 220.0, 0.016)
	check(banked > 20, "banks")
	check_eq(d.score, 0.0)

func test_short_drift_banks_nothing_and_crash_resets() -> void:
	var d := DriftScore.new()
	for i in 20:
		d.step(120.0, 220.0, 0.016)
	check_eq(d.step(0.0, 220.0, 0.016), 0, "0.3s twitch is not a drift")
	for i in 100:
		d.step(120.0, 220.0, 0.016)
	d.crash()
	check_eq(d.step(0.0, 0.0, 0.016), 0)

func test_multiplier_and_slow_speed() -> void:
	check(DriftScore.multiplier(4.0) > DriftScore.multiplier(1.0))
	check_eq(DriftScore.multiplier(10.0), DriftScore.multiplier(4.0), "capped")
	check(not DriftScore.new().drifting(200.0, 40.0), "too slow")

func test_pit_cap() -> void:
	check(DriftScore.pit_cap(true) < 0.5)
	check_eq(DriftScore.pit_cap(false), 1.0)
