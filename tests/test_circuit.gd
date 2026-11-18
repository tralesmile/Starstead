extends BaseTest

func test_track_is_a_closed_band_with_infield() -> void:
	var n := 0
	for x in range(-124, -68):
		for y in range(136, 184):
			var c := Vector2i(x, y)
			if CircuitModel.is_track(c):
				n += 1
				check(not CircuitModel.is_infield(c), "track is not infield")
	check(n > 250, "enough track cells: %d" % n)
	check(CircuitModel.is_track(CircuitModel.START_CELL), "start line on the track")
	check(CircuitModel.is_infield(Vector2i(-96, 160)), "road hub in the infield")
	check(not CircuitModel.is_track(Vector2i(-96, 160)), "hub is not track")

func test_checkpoints_lie_on_track_and_close_at_start() -> void:
	var cps := CircuitModel.checkpoints()
	check(cps.size() == CircuitModel.N_CP, "count")
	for p in cps:
		var c := Vector2i(floori(p.x / 32.0), floori(p.y / 32.0))
		check(CircuitModel.is_track(c), "checkpoint on track %s" % c)
	var last: Vector2 = cps[cps.size() - 1]
	check(last.distance_to(CircuitModel.start_px()) < 2.0, "last checkpoint is the start line")
	var first: Vector2 = cps[0]
	check(first.distance_to(last) < 600.0 and first.distance_to(last) > 100.0, "first checkpoint is next to the line")

func test_buildings_and_props_on_infield_or_outside_track() -> void:
	for b in CircuitModel.buildings():
		for c in CityModel.building_cells(b):
			check(CircuitModel.is_infield(c), "building cell in infield " + str(c))
		check(CircuitModel.is_infield(b["door"]), "door in infield " + str(b["door"]))
	for p in CircuitModel.props():
		var c: Vector2i = p["cell"]
		check(CircuitModel.in_rect(c) and not CircuitModel.is_track(c), "prop off the track: %s %s" % [p["kind"], c])

func test_grid_slots_behind_line() -> void:
	for k in 3:
		check(CircuitModel.grid_slots(k).x > CircuitModel.start_px().x, "slot %d behind the line" % k)
	check(CircuitModel.grid_slots(1).y != CircuitModel.grid_slots(0).y, "staggered lanes")

func test_licence_and_prize() -> void:
	check(CircuitModel.licence_ok(false, 200)["ok"], "can buy")
	check(CircuitModel.licence_ok(false, 200)["cash"] == 50, "pays 150")
	check(not CircuitModel.licence_ok(true, 999)["ok"], "already owned")
	check(CircuitModel.licence_ok(false, 10)["why"] == "broke", "broke")
	check(CircuitModel.prize(1, 2, [200, 100, 50]) == 1200, "circuit prize x3")
	check(CircuitModel.prize(4, 2, [200, 100, 50]) == 0, "no prize 4th")

func test_meter_triangle() -> void:
	check(is_equal_approx(SportsModel.meter(0.0), 1.0), "starts at 1")
	check(is_equal_approx(SportsModel.meter(1.0 / 1.4), 0.0), "bottom after half period")
	for i in 50:
		var m := SportsModel.meter(i * 0.137)
		check(m >= 0.0 and m <= 1.0, "in range")

func test_hoops() -> void:
	var w := SportsModel.hoop_width(0)
	check(SportsModel.hoop_made(0.5, 0.99, w), "centre always scores")
	check(not SportsModel.hoop_made(0.05, 0.0, w), "far off misses")
	check(SportsModel.hoop_made(0.5 + w * 1.5, 0.1, w), "edge can fall in")
	check(not SportsModel.hoop_made(0.5 + w * 1.5, 0.9, w), "edge can bounce out")
	check(SportsModel.hoop_width(10) > SportsModel.hoop_width(0), "wider with skill")
	check(SportsModel.hoop_payout([true, true, true, false, true]) == 12 * 4 + 6, "streak bonus once")
	check(SportsModel.hoop_payout([false, false]) == 0, "nothing")

func test_penalties() -> void:
	check(SportsModel.zone_of(0.1) == 0 and SportsModel.zone_of(0.5) == 1 and SportsModel.zone_of(0.9) == 2, "zones")
	check(SportsModel.penalty(0.1, 0.6, 2) == "goal", "keeper wrong way")
	check(SportsModel.penalty(0.1, 0.6, 0) == "saved", "keeper guessed, soft")
	check(SportsModel.penalty(0.1, 0.85, 0) == "goal", "power beats keeper")
	check(SportsModel.penalty(0.5, 0.98, 2) == "miss", "skied")
	check(SportsModel.penalty(0.5, 0.2, 2) == "saved", "too weak")
	check(SportsModel.keeper_zone(0.0) == 0 and SportsModel.keeper_zone(0.99) == 2, "keeper zones")

func test_boxing() -> void:
	var w := SportsModel.bout_window(0)
	var d := SportsModel.exchange(-1, -1, 0.3, w)
	check(d["you"] == 0 and d["opp"] == 8, "dodge counters")
	check(SportsModel.exchange(-1, 1, 0.3, w)["you"] == 6, "wrong dodge hurts")
	check(SportsModel.exchange(1, 2, 0.3, w)["opp"] == 4, "jab trades")
	check(SportsModel.exchange(1, 1, 5.0, w)["you"] == 6, "too slow")
	check(SportsModel.bout_window(3) < SportsModel.bout_window(0), "harder tiers are quicker")
	check(SportsModel.bout_over(10, 0, 3) == "win", "ko")
	check(SportsModel.bout_over(0, 5, 3) == "lose", "knocked out")
	check(SportsModel.bout_over(10, 5, 3) == "", "ongoing")
	check(SportsModel.bout_over(10, 5, SportsModel.ROUND_MAX) == "lose", "decision against")
	check(SportsModel.opp_hp(2) > SportsModel.opp_hp(0), "tiers scale")
