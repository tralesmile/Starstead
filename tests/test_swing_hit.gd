extends BaseTest

func test_strike_delay_is_inside_the_strike_frame() -> void:
	for pair in [["axe", PoseMath.HEAVY_STRIKE], ["pickaxe", PoseMath.HEAVY_STRIKE], ["hoe", PoseMath.HOE_CHOP], ["watering_can", PoseMath.CAN_POUR]]:
		var tool: String = pair[0]
		var k := PoseMath.strike_delay(tool) / PoseMath.swing_time(tool)
		check_eq(PoseMath.frame(tool, k + 0.001), pair[1], "%s bites on its strike frame" % tool)
		check(PoseMath.strike_delay(tool) < 0.2, "%s still feels responsive" % tool)
	for tool in ["hand", "scythe", "crab_pot", "turnip_seed"]:
		check(is_equal_approx(PoseMath.strike_delay(tool), 0.0), "%s acts at once" % tool)

func test_blow_waits_then_lands_once() -> void:
	var hits := [0]
	var s := SwingHit.new()
	check(s.queue(0.126, func(): hits[0] += 1), "queued")
	check_eq(hits[0], 0, "nothing on the press")
	check(not s.tick(0.1), "still winding up")
	check(s.tick(0.05), "lands")
	check_eq(hits[0], 1)
	check(not s.tick(1.0), "only once")
	check_eq(hits[0], 1)

func test_second_press_ignored_mid_swing() -> void:
	var hits := [0]
	var s := SwingHit.new()
	s.queue(0.1, func(): hits[0] += 1)
	check(not s.queue(0.1, func(): hits[0] += 10), "refused")
	s.tick(0.2)
	check_eq(hits[0], 1)
	check(s.queue(0.0, func(): hits[0] += 100), "no delay runs at once")
	check_eq(hits[0], 101)
	check(not s.busy())

func test_cancel() -> void:
	var hits := [0]
	var s := SwingHit.new()
	s.queue(0.1, func(): hits[0] += 1)
	s.cancel()
	s.tick(1.0)
	check_eq(hits[0], 0)

func test_pour_arc() -> void:
	var a := Vector2(0, -14)
	var b := Vector2(32, 4)
	check(PourMath.at(a, b, 0.0).is_equal_approx(a), "starts at the spout")
	check(PourMath.at(a, b, 1.0).distance_to(b) < 0.01, "ends on the soil")
	var first := PourMath.at(a, b, 0.25).y - PourMath.at(a, b, 0.0).y
	var last := PourMath.at(a, b, 1.0).y - PourMath.at(a, b, 0.75).y
	check(last > first, "water speeds up as it falls")
	check(PourMath.at(a, b, 0.5).y < a.lerp(b, 0.5).y, "arcs above the straight line")

func test_pour_covers_the_tile_only() -> void:
	for i in PourMath.DROPS_PER_CELL:
		var p := PourMath.spread(i)
		check(absf(p.x) <= 16.0 and absf(p.y) <= 16.0, "drop %d lands on its tile" % i)
	check(is_equal_approx(PourMath.birth(0), 0.0))
	check(is_equal_approx(PourMath.birth(PourMath.DROPS_PER_CELL - 1), PourMath.EMIT_TIME))
	check(PourMath.duration() < 0.7, "over quickly")
	check(PourMath.spout(PlayerMath.Facing.LEFT).x < 0.0 and PourMath.spout(PlayerMath.Facing.RIGHT).x > 0.0)
