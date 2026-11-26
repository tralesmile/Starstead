extends BaseTest

const T := BikeModel.TICK

func _solo(s: float = 0.0, lane: int = 1) -> Array:
	return [BikeModel.rider(s, lane)]

func _run(riders: Array, inp: Dictionary, secs: float, wet: float = 0.0) -> Array:
	var evs: Array = []
	for k in int(secs / T):
		var all: Array = []
		for i in riders.size():
			all.append(inp)
		for e in BikeModel.step(riders, all, wet, k * T, T):
			evs.append(e["ev"])
	return evs

func test_pedal_drains_and_easy_spin_recovers() -> void:
	var a := _solo()
	var b := _solo()
	_run(a, {"effort": 1.0}, 4.0)
	_run(b, {"effort": 0.0}, 4.0)
	check(float(a[0]["s"]) > float(b[0]["s"]), "pushing is faster")
	check(float(a[0]["stamina"]) < 0.7, "pushing costs stamina")
	check_eq(float(b[0]["stamina"]), 1.0)

func test_winded_then_recovers() -> void:
	var r := _solo()
	var evs := _run(r, {"effort": 1.0}, 15.0)
	check(evs.has("winded"))
	check(r[0]["winded"])
	var v_winded := float(r[0]["v"])
	_run(r, {"effort": 1.0}, 3.5)
	check(not r[0]["winded"], "gets its breath back even with Space held")
	check(v_winded < 12.0, "winded is slow: %f" % v_winded)

func test_drag_grows_with_speed_squared_and_draft_cuts_it() -> void:
	var low := BikeModel.resist(5.0, 0.0) - BikeModel.ROLL
	var high := BikeModel.resist(10.0, 0.0) - BikeModel.ROLL
	check(is_equal_approx(high, low * 4.0), "v^2")
	check(BikeModel.resist(0.0, 0.0) > 0.0, "rolling resistance")
	check(BikeModel.resist(13.0, 1.0) < BikeModel.resist(13.0, 0.0) * 0.8, "a wheel is a big help")

func test_slipstream_needs_a_wheel_in_front() -> void:
	var r := [BikeModel.rider(20.0, 1), BikeModel.rider(24.0, 1)]
	check(BikeModel.draft_strength(r, 0) > 0.9, "tucked in")
	check_eq(BikeModel.draft_strength(r, 1), 0.0, "the leader gets nothing")
	r[1]["s"] = 29.0
	var far := BikeModel.draft_strength(r, 0)
	check(far > 0.0 and far < 0.9, "fades with the gap")
	r[1]["s"] = 40.0
	check_eq(BikeModel.draft_strength(r, 0), 0.0)
	r[1]["s"] = 24.0
	r[1]["l"] = BikeModel.LANES[2]
	check_eq(BikeModel.draft_strength(r, 0), 0.0, "other line")

func test_inside_line_is_shorter_but_tighter() -> void:
	var s := BikeModel.lap_length() * 0.5
	check(BikeModel.path_factor(s, BikeModel.LANES[0]) > 1.0)
	check(BikeModel.path_factor(s, BikeModel.LANES[2]) < 1.0)
	check(BikeModel.corner_limit(s, BikeModel.LANES[0], 0.0) < BikeModel.corner_limit(s, BikeModel.LANES[2], 0.0))
	var a := _solo(0.0, 0)
	var b := _solo(0.0, 2)
	_run(a, {"effort": 0.3, "lane": 0}, 8.0)
	_run(b, {"effort": 0.3, "lane": 2}, 8.0)
	check(float(a[0]["s"]) > float(b[0]["s"]), "inside gets further round")

func test_cannot_ride_through_a_rider() -> void:
	# alongside: the line change waits
	var r := [BikeModel.rider(20.0, 0), BikeModel.rider(20.5, 1)]
	for k in 60:
		BikeModel.step_rider(r, 0, {"effort": 0.0, "lane": 2}, 0.0, T)
	check(float(r[0]["l"]) <= float(r[1]["l"]) - BikeModel.BIKE_WIDTH + 0.05, "held on its side: %f" % float(r[0]["l"]))
	# from behind on the same line: stuck on the back wheel
	var q := [BikeModel.rider(20.0, 1), BikeModel.rider(25.0, 1)]
	q[0]["v"] = 14.0
	q[1]["v"] = 5.0
	var blocked := false
	for k in 90:
		BikeModel.step(q, [{"effort": 1.0, "lane": 1}, {"effort": 0.0, "lane": 1}], 0.0, k * T, T)
		blocked = blocked or bool(q[0]["blocked"])
		check(float(q[0]["s"]) <= float(q[1]["s"]) - BikeModel.BIKE_LEN + 0.01, "never through")
	check(blocked)

func test_corner_grip_lower_in_rain_wobble_then_slide() -> void:
	check(BikeModel.grip(1.0) < BikeModel.grip(0.0))
	check_eq(BikeModel.wet_for(0.0), 0.0)
	check(BikeModel.wet_for(0.3) > 0.5)
	var s := 0.0
	for k in 220:   # find the tightest bend
		if BikeModel.radius(float(k)) < BikeModel.radius(s):
			s = float(k)
	var lim := BikeModel.corner_limit(s, 0.0, 0.0)
	check(BikeModel.corner_limit(s, 0.0, 1.0) < lim)
	var a := _solo(s)
	a[0]["v"] = lim * 1.07
	var ev := BikeModel.step_rider(a, 0, {"effort": 0.0}, 0.0, T)
	check(ev.has("wobble") and not ev.has("slide"), "slightly over: wobble")
	check(float(a[0]["v"]) < lim * 1.07)
	var b := _solo(s)
	b[0]["v"] = lim * 1.25
	var ev2 := BikeModel.step_rider(b, 0, {"effort": 0.0}, 0.0, T)
	check(ev2.has("slide"), "well over: slide")
	check(float(b[0]["v"]) < lim * 0.6 and float(b[0]["slide"]) > 1.0, "costs speed and time")
	var c := _solo(s)
	c[0]["v"] = lim * 0.97
	check(BikeModel.step_rider(c, 0, {"effort": 0.0}, 0.0, T).is_empty(), "under the limit is clean")
	check(BikeModel.step_rider(_dry_speed(s, lim * 0.97), 0, {"effort": 0.0}, 1.0, T).has("slide"), "the same speed slides in the wet")

func _dry_speed(s: float, v: float) -> Array:
	var r := _solo(s)
	r[0]["v"] = v
	return r

func test_brake() -> void:
	var a := _dry_speed(0.0, 12.0)
	var b := _dry_speed(0.0, 12.0)
	_run(a, {"effort": 0.0}, 1.0)
	_run(b, {"effort": 1.0, "brake": true}, 1.0)
	check(float(b[0]["v"]) < float(a[0]["v"]) - 3.0)

func test_place_laps_prize() -> void:
	var r := BikeModel.grid()
	check_eq(r.size(), BikeModel.RIDERS)
	r[0]["done"] = 61.0
	r[1]["done"] = 60.0
	r[2]["s"] = 500.0
	check_eq(BikeModel.place(r, 1), 0)
	check_eq(BikeModel.place(r, 0), 1)
	check_eq(BikeModel.place(r, 2), 2)
	check_eq(BikeModel.lap_of(-3.0), 1)
	check_eq(BikeModel.lap_of(BikeModel.lap_length() + 1.0), 2)
	check_eq(BikeModel.lap_of(9999.0), BikeModel.LAPS)
	check(BikeModel.prize(0) > BikeModel.prize(1) and BikeModel.prize(4) == 0)
	check(BikeModel.prize(0) - BikeModel.FEE <= 110, "within a job shift")

func test_grid_has_no_overlap() -> void:
	var rng := RandomNumberGenerator.new()
	for sd in 8:
		rng.seed = sd
		var g := BikeModel.grid([], rng)
		check_eq(float(g[0]["s"]), float(BikeModel.GRID[0][0]), "your spot is fixed")
		for i in g.size():
			for j in range(i + 1, g.size()):
				check(g[i]["lane"] != g[j]["lane"] or absf(float(g[i]["s"]) - float(g[j]["s"])) >= BikeModel.BIKE_LEN, "grid %d %d" % [i, j])

func test_one_paid_race_a_day_survives_save() -> void:
	var best := {}
	check(BikeModel.entry(best, 4, 100)["paid"])
	check_eq(BikeModel.entry(best, 4, 5)["why"], "broke")
	best[BikeModel.DAY_KEY] = 4
	check_eq(BikeModel.entry(best, 4, 100)["why"], "done")
	# JSON turns ints into floats; GameState loads sport_best back with int()
	var loaded: Dictionary = JSON.parse_string(JSON.stringify(best))
	check(BikeModel.paid_today(loaded, 4))
	check(BikeModel.entry(loaded, 5, 100)["paid"], "next day pays again")

func test_best_time_in_centiseconds() -> void:
	var best := {}
	check(BikeModel.record_time(best, 61.234))
	check_eq(int(best[BikeModel.BEST_KEY]), 6123)
	check(not BikeModel.record_time(best, 63.0))
	check(BikeModel.record_time(best, 59.5))
	check_eq(int(best[BikeModel.BEST_KEY]), 5950)

func test_rack_stands_on_the_infield_clear_of_pitch_and_props() -> void:
	var c := CircuitModel.BIKE_CELL
	check(CircuitModel.is_infield(c))
	check(not Rect2i(CircuitModel.PITCH_CELL, Vector2i(6, 4)).has_point(c))
	var here := CircuitModel.props().filter(func(p): return p["cell"] == c)
	check_eq(here.size(), 1)

# ---------------------------------------------------------------- whole races

func _bot(riders: Array, kind: String, wet: float, mem: Dictionary) -> Dictionary:
	var r: Dictionary = riders[0]
	if kind == "hold":   # only ever holds Space
		return {"effort": 1.0, "brake": false, "lane": r["lane"]}
	# a sensible drafter with a player's controls: Space is on or off
	var who := {"style": "sprinter", "bonus": 0.0, "kick": 100.0, "cruise": 0.4, "nerve": 1.0, "attack": 0.0}
	var a := BikeModel.ai_input(riders, 0, who, wet)
	mem["acc"] = float(mem.get("acc", 0.0)) + float(a["effort"])
	var on := float(mem["acc"]) >= 0.5
	if on:
		mem["acc"] = float(mem["acc"]) - 1.0
	a["effort"] = 1.0 if on else 0.0
	return a

func _race(kind: String, seed_value: int, wet: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var who: Array = [{}]
	var bonus: Array = [0.0]
	for i in range(1, BikeModel.RIDERS):
		who.append(BikeModel.personality(i, rng))
		bonus.append(who[i]["bonus"])
	var riders := BikeModel.grid(bonus, rng)
	var mem := {}
	var t := 0.0
	var drafted := 0.0
	while t < 120.0:
		var inputs: Array = [_bot(riders, kind, wet, mem)]
		for i in range(1, BikeModel.RIDERS):
			inputs.append(BikeModel.ai_input(riders, i, who[i], wet))
		BikeModel.step(riders, inputs, wet, t, T)
		t += T
		drafted += T if float(riders[0]["draft"]) > 0.3 else 0.0
		if riders.all(func(q): return float(q["done"]) >= 0.0):
			break
	var winner := 0
	var crashes := 0
	for i in BikeModel.RIDERS:
		if BikeModel.place(riders, i) == 0:
			winner = i
		if i > 0:
			crashes += int(riders[i]["crashes"])
	return {"place": BikeModel.place(riders, 0), "winner": winner, "time": float(riders[winner]["done"]),
		"all_done": riders.all(func(q): return float(q["done"]) >= 0.0), "drafted": drafted, "ai_crashes": crashes}

func test_balance_dry_and_wet() -> void:
	var seeds := 6
	for wet in [0.0, 1.0]:
		var hold: Array = []
		var smart: Array = []
		var winners := {}
		var times: Array = []
		for sd in seeds:
			var h := _race("hold", sd + 1, wet)
			var d := _race("draft", sd + 1, wet)
			for res in [h, d]:
				check(res["all_done"], "everyone finishes")
				check(float(res["time"]) >= 45.0 and float(res["time"]) <= 75.0, "race length %f" % float(res["time"]))
				check(int(res["ai_crashes"]) <= 1, "rivals can corner")
			hold.append(h["place"])
			smart.append(d["place"])
			winners[h["winner"]] = true
			times.append(snappedf(float(d["time"]), 0.1))
		var wins := smart.count(0)
		var podium := smart.filter(func(p): return p <= 2).size()
		print("BIKE wet=%d hold places %s | drafting places %s | winning times %s | rival winners %s" % [int(wet), hold, smart, times, winners.keys()])
		check_eq(hold.count(0), 0, "holding Space never wins")
		check(hold.filter(func(p): return p >= 3).size() >= seeds - 1, "holding Space ends up at the back")
		check(podium >= seeds / 2, "drafting is usually on the podium: %d" % podium)
		check(winners.size() >= 2, "more than one rider can win")
		if wet == 0.0:
			check(wins >= 1, "sensible drafting can win")
