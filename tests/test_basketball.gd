extends BaseTest
## 3-on-3 street basketball: HoopBall physics, HoopMatch rules and AI balance, HoopLadder, court placement.

func _live(seed_value: int = 3) -> HoopMatch:
	var m := HoopMatch.new(2, 2, seed_value)
	m.auto = false
	m.pause = 0.0
	return m

func _park_others(m: HoopMatch, keep: Array) -> void:
	for i in m.players.size():
		if not keep.has(i):
			m.players[i]["pos"] = Vector2(12.0 + i * 14.0, 228.0)
			m.players[i]["stun"] = 99.0

func test_ball_falls_and_bounces_lower_each_time() -> void:
	var b := HoopBall.new()
	b.reset(Vector2(80, 180))
	b.z = 80.0
	var peaks: Array = []
	var rising := false
	for i in 400:
		var before := b.z
		b.step(1.0 / 60.0)
		check(b.z >= HoopBall.RADIUS - 0.001, "never under the floor")
		if rising and b.z < before:
			peaks.append(before)
		rising = b.z > before
	check(peaks.size() >= 2 and peaks[0] < 80.0 and peaks[1] < peaks[0], "bounces decay %s" % str(peaks))

func _fly(b: HoopBall, secs: float) -> Array:
	var seen: Array = []
	for i in int(secs * 60.0):
		var ev := b.step(1.0 / 60.0)
		if ev != "":
			seen.append(ev)
		if ev == "score":
			break
	return seen

func test_aimed_shots_drop_from_all_over_the_court() -> void:
	for from in [Vector2(220, 70), Vector2(220, 130), Vector2(220, 205), Vector2(90, 90), Vector2(350, 120), Vector2(50, 40), Vector2(400, 60), Vector2(200, 36), Vector2(230, 16)]:
		var b := HoopBall.new()
		b.pos = from
		b.z = 46.0
		b.launch(HoopBall.launch_velocity(from, 46.0, HoopBall.RIM, HoopBall.RIM_Z, HoopBall.flight_time(from.distance_to(HoopBall.RIM))), true)
		check(_fly(b, 2.5).has("score"), "swish from %s" % from)

func test_short_shot_rattles_the_iron_and_backboard_throws_it_back() -> void:
	var from := Vector2(220, 160)
	var b := HoopBall.new()
	b.pos = from
	b.z = 46.0
	var short := HoopBall.RIM + Vector2(0, HoopBall.RIM_R + 2.0)
	b.launch(HoopBall.launch_velocity(from, 46.0, short, HoopBall.RIM_Z, HoopBall.flight_time(130.0)), true)
	check(_fly(b, 1.4).has("rim"), "front rim")
	check(b.touched_iron and not b.shot, "now a loose ball")
	var c := HoopBall.new()
	c.pos = Vector2(236, 60)
	c.z = 70.0
	c.launch(Vector3(0, -200, 40))
	var hit := false
	for i in 40:
		if c.step(1.0 / 60.0) == "board":
			hit = true
			break
	check(hit and c.vel.y > 0.0 and c.pos.y >= HoopBall.BOARD_Y, "off the glass")

func test_three_point_line_and_fence() -> void:
	check(not HoopBall.is_three(HoopBall.RIM + Vector2(0, HoopBall.ARC - 2.0)))
	check(HoopBall.is_three(HoopBall.RIM + Vector2(0, HoopBall.ARC + 2.0)))
	var b := HoopBall.new()
	b.reset(Vector2(20, 200))
	b.vel = Vector2(-300, 0)
	for i in 60:
		b.step(1.0 / 60.0)
		check(b.pos.x >= HoopBall.RADIUS - 0.001, "fence holds")

func test_timing_distance_and_contest_shape_accuracy() -> void:
	check_eq(HoopMatch.timing_quality(HoopMatch.SWEET), 1.0)
	check(HoopMatch.timing_quality(HoopMatch.SWEET - 0.15) < 1.0 and HoopMatch.timing_quality(HoopMatch.SWEET - 0.15) > 0.2)
	check_eq(HoopMatch.timing_quality(0.1), 0.0)
	check(is_equal_approx(HoopMatch.timing_quality(1.0), HoopMatch.timing_quality(0.4)), "early and late cost the same")
	var last := 1.0
	for d in range(0, 320, 10):
		var p := HoopMatch.distance_chance(float(d))
		check(p <= last, "farther is never easier at %d" % d)
		last = p
	var open := HoopMatch.shot_chance(100.0, 1.0, 0.0, 2)
	check(open > HoopMatch.shot_chance(100.0, 0.3, 0.0, 2) + 0.2, "timing matters")
	check(open > HoopMatch.shot_chance(100.0, 1.0, 1.0, 2) + 0.2, "defence matters")

func test_contest_needs_a_defender_close_and_in_front() -> void:
	var m := _live()
	_park_others(m, [0, 3])
	m.players[0]["pos"] = Vector2(220, 160)
	m.players[3]["stun"] = 0.0
	m.players[3]["pos"] = Vector2(220, 146)
	var front := m.contest_on(0)
	m.players[3]["pos"] = Vector2(220, 174)
	var behind := m.contest_on(0)
	m.players[3]["pos"] = Vector2(220, 90)
	check(front > behind and behind > 0.0 and m.contest_on(0) == 0.0, "%f %f" % [front, behind])
	m.players[3]["pos"] = Vector2(220, 146)
	m.players[3]["z"] = 20.0
	check(m.contest_on(0) >= front, "a hand up counts")

func _shoot_with(m: HoopMatch, hold_secs: float) -> void:
	m.update(HoopMatch.TICK, {"shoot": true})
	for i in int(hold_secs / HoopMatch.TICK):
		m.update(HoopMatch.TICK)
	m.update(HoopMatch.TICK, {"release": true})

func test_release_timing_comes_from_how_long_space_is_held() -> void:
	var m := _live()
	_park_others(m, [0])
	_shoot_with(m, HoopMatch.SWEET * HoopMatch.METER_TIME - HoopMatch.TICK)
	check_eq(int(m.stats["fga"][0]), 1)
	check_eq(float(m.last_release["quality"]), 1.0, "released at %f" % m.last_release["meter"])
	var late := _live()
	_park_others(late, [0])
	late.update(HoopMatch.TICK, {"shoot": true})
	for i in 90:
		late.update(HoopMatch.TICK)
	check_eq(int(late.stats["fga"][0]), 1, "held too long lets go by itself")
	check(float(late.last_release["quality"]) < 0.15, "a late release is a bad one")

func test_made_basket_scores_two_or_three_then_other_ball() -> void:
	for spot in [[Vector2(220, 100), 2], [Vector2(220, 195), 3]]:
		var scored := false
		for s in 40:
			var m := _live(s + 1)
			_park_others(m, [0])
			m.players[0]["pos"] = spot[0]
			m.start_shot(0)
			m.release_shot(0, HoopMatch.SWEET)
			for i in 240:
				m.update(HoopMatch.TICK)
				if int(m.score[0]) > 0:
					break
			if int(m.score[0]) > 0:
				check_eq(int(m.score[0]), spot[1])
				for i in 180:
					m.update(HoopMatch.TICK)
				check_eq(m.offense, 1, "their ball after your bucket")
				check(m.owner >= 3)
				scored = true
				break
		check(scored, "an open perfect shot goes in within 40 tries")

func test_first_to_21_ends_it_and_a_tie_at_time_goes_to_next_basket() -> void:
	var m := _live()
	m.score = [20, 18]
	m.shot_info = {"team": 0, "shooter": 0, "points": 2}
	m._score()
	check(m.finished and m.result() == 1)
	var tie := _live()
	tie.clock = HoopMatch.TIME_LIMIT - 0.01
	tie.score = [8, 8]
	tie.update(0.05)
	check(tie.overtime and not tie.finished)
	tie.shot_info = {"team": 1, "shooter": 3, "points": 2}
	tie._score()
	check(tie.finished and tie.result() == -1)
	var up := _live()
	up.clock = HoopMatch.TIME_LIMIT - 0.01
	up.score = [9, 8]
	up.update(0.05)
	check(up.finished and not up.overtime)

func test_take_it_back_after_a_change_of_possession() -> void:
	var m := _live()
	m._gain(3)
	check(m.must_clear and m.offense == 1)
	m.players[3]["pos"] = Vector2(220, 90)
	check(not m.start_shot(3), "no shot before clearing")
	check(m.events.has("clear_first"))
	m.players[3]["pos"] = Vector2(220, 215)
	m.auto = true
	m.update(HoopMatch.TICK)
	check(not m.must_clear)

func test_pass_reaches_the_teammate_and_control_follows() -> void:
	var m := _live()
	_park_others(m, [0, 1])
	m.players[1]["stun"] = 0.0
	m.players[1]["pos"] = Vector2(110, 150)
	m.players[0]["pos"] = Vector2(220, 190)
	m.update(HoopMatch.TICK, {"pass": true, "move": Vector2(-1, -0.3)})
	for i in 90:
		m.update(HoopMatch.TICK)
		if m.owner >= 0:
			break
	check_eq(m.owner, 1)
	check_eq(m.selected, 1)
	check(not m.must_clear, "a pass is not a turnover")

func test_steal_is_a_gamble_with_a_cooldown() -> void:
	check(HoopMatch.steal_chance(2, 2, true) < HoopMatch.steal_chance(2, 2, false))
	check(HoopMatch.steal_chance(4, 1, false) > HoopMatch.steal_chance(1, 4, false))
	var wins := 0
	for s in 200:
		var m := _live(s + 1)
		m.players[0]["face"] = Vector2.UP
		m.players[3]["pos"] = (m.players[0]["pos"] as Vector2) + Vector2(0, -13)
		if m.try_steal(3):
			wins += 1
			check(m.owner == 3 and m.must_clear)
		else:
			check(float(m.players[3]["stun"]) > 0.0, "a whiff costs you")
		check(not m.try_steal(3), "cooldown")
	check(wins > 15 and wins < 80, "steals %d/200" % wins)

func test_block_only_from_a_jumping_defender_on_the_shooter() -> void:
	var blocked := 0
	for s in 200:
		var m := _live(s + 1)
		_park_others(m, [0, 3])
		m.players[3]["stun"] = 0.0
		m.players[0]["pos"] = Vector2(220, 150)
		m.players[3]["pos"] = Vector2(220, 137)
		if s % 2 == 0:
			m.players[3]["z"] = 24.0
		m.start_shot(0)
		m.release_shot(0, HoopMatch.SWEET)
		if int(m.stats["blk"][1]) > 0:
			check(s % 2 == 0, "feet on the floor never blocks")
			blocked += 1
	check(blocked > 5 and blocked < 50, "blocks %d/100" % blocked)

func test_loose_ball_is_rebounded_and_a_stuck_one_is_rechecked() -> void:
	var m := _live()
	_park_others(m, [3])
	m.players[3]["stun"] = 0.0
	m.offense = 0
	m.owner = -1
	m.players[3]["pos"] = Vector2(180, 90)
	m.ball.reset(Vector2(180, 90))
	m.ball.z = 30.0
	m.ball.touched_iron = true
	m.update(HoopMatch.TICK)
	check_eq(m.owner, 3)
	check_eq(int(m.stats["reb"][1]), 1)
	check(m.must_clear)
	var stuck := _live()
	_park_others(stuck, [])
	stuck.owner = -1
	stuck.ball.reset(Vector2(420, 20))
	for i in 360:
		stuck.update(HoopMatch.TICK)
	check(stuck.owner >= 0, "nobody could reach it: check ball")

func test_shot_clock_turns_it_over() -> void:
	var m := _live()
	_park_others(m, [0])
	m.shot_clock = 0.02
	m.update(0.1)
	check_eq(m.offense, 1)
	check_eq(int(m.stats["to"][0]), 1)

func test_press_survives_frames_with_no_tick() -> void:
	var m := _live()
	_park_others(m, [0])
	m.update(1.0 / 144.0, {"shoot": true})   # too short to run a tick
	for i in 4:
		m.update(1.0 / 144.0)
	check(float(m.players[0]["meter"]) >= 0.0, "wind-up started")
	var tap := _live()
	_park_others(tap, [0])
	tap.update(1.0 / 144.0, {"shoot": true, "release": true})
	for i in 8:
		tap.update(1.0 / 144.0)
	check_eq(int(tap.stats["fga"][0]), 1, "a tap inside one frame still lets go")

static func _sim(home: int, away: int, seed_value: int) -> HoopMatch:
	var m := HoopMatch.new(home, away, seed_value, seed_value % 2)
	m.auto = true
	var guard := 0
	while not m.finished and guard < 1600:
		m.update(0.25)
		m.events.clear()
		guard += 1
	return m

func test_ai_vs_ai_balance() -> void:
	const N := 16
	var wins := [0, 0]
	var sum := {"pts": 0, "fga": 0, "fgm": 0, "tpa": 0, "tpm": 0, "reb": 0, "stl": 0, "blk": 0}
	var secs := 0.0
	for s in N:
		var m := _sim(2, 2, s + 1)
		check(m.finished, "match %d ends" % s)
		check(m.result() != 0, "no draws")
		wins[0 if m.result() > 0 else 1] += 1
		sum["pts"] += int(m.score[0]) + int(m.score[1])
		secs += m.clock
		for k in sum:
			if k != "pts":
				sum[k] += int(m.stats[k][0]) + int(m.stats[k][1])
	var fg := float(sum["fgm"]) / float(sum["fga"])
	var threes := float(sum["tpa"]) / float(sum["fga"])
	print("bball 2v2 x%d: wins %s, %.1f points, %.0f s, FG %.0f%%, 3s %.0f%% of shots at %.0f%%, reb %.1f stl %.1f blk %.1f" % [N, str(wins), float(sum["pts"]) / N, secs / N,
		fg * 100.0, threes * 100.0, 100.0 * sum["tpm"] / maxi(1, sum["tpa"]), float(sum["reb"]) / N, float(sum["stl"]) / N, float(sum["blk"]) / N])
	check(wins[0] >= 3 and wins[1] >= 3, "equal crews both win %s" % str(wins))
	check(float(sum["pts"]) / N > 16.0 and float(sum["pts"]) / N < 40.0, "scoring pace")
	check(fg > 0.28 and fg < 0.62, "field goal rate %f" % fg)
	check(threes > 0.07 and threes < 0.6, "twos and threes both taken %f" % threes)
	check(float(sum["blk"]) / float(sum["fga"]) < 0.2, "blocks stay rare")

func test_better_crew_usually_wins_and_seeds_repeat() -> void:
	var strong := 0
	for s in 10:
		if _sim(4, 1, s + 100).result() > 0:
			strong += 1
	check(strong >= 8, "tier 4 beat tier 1 %d/10" % strong)
	var a := _sim(2, 3, 9)
	var b := _sim(2, 3, 9)
	check_eq(a.score, b.score)
	check_eq(a.stats, b.stats)

func test_ladder_pays_climbs_and_limits_to_one_game_a_day() -> void:
	var l := HoopLadder.new()
	check_eq(l.can_play(1, 100, 90.0, 12.0), "")
	check(l.can_play(1, 5, 90.0, 12.0) != "" and l.can_play(1, 100, 10.0, 12.0) != "" and l.can_play(1, 100, 90.0, 23.0) != "")
	var r := l.record(21, 15, 1)
	check_eq(r["pay"], HoopLadder.WIN_PAY[0])
	check_eq(l.rung, 1)
	check(l.can_play(1, 100, 90.0, 12.0) != "", "once a day")
	check_eq(l.can_play(2, 100, 90.0, 12.0), "")
	check_eq(l.record(10, 21, 2)["pay"], 0)
	check_eq(l.rung, 1, "a loss keeps the rung")
	l.record(21, 3, 3)
	var tier_before := l.tier_of(1)
	var top := l.record(21, 19, 4)
	check(top["crown"] and l.crowns == 1 and l.rung == 0)
	check_eq(top["pay"], HoopLadder.WIN_PAY[2] + HoopLadder.CROWN_PAY)
	check_eq(l.tier_of(1), tier_before + 1, "rivals sharpen")

func test_ladder_save_roundtrip_through_json() -> void:
	var a := HoopLadder.new()
	a.record(21, 10, 4)
	a.record(5, 21, 5)
	var b := HoopLadder.new()
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	check_eq(b.to_dict(), a.to_dict())
	for k in b.to_dict():
		check_eq(typeof(b.to_dict()[k]), TYPE_INT, k)
	var fresh := HoopLadder.new()
	fresh.from_dict({})
	check_eq(fresh.last_day, -1)
	check_eq(fresh.rung, 0)

func test_street_hoop_has_its_own_spot_by_the_sports_hall() -> void:
	var c := CircuitModel.HOOP_CELL
	check(CircuitModel.is_infield(c) and CircuitModel.is_infield(c + Vector2i(0, 1)), "on the infield")
	check_eq(CircuitModel.props().filter(func(p): return p["kind"] == "streethoop").size(), 1)
	for p in CircuitModel.props():
		if p["kind"] != "streethoop":
			var d: Vector2i = (p["cell"] as Vector2i) - c
			check(maxi(absi(d.x), absi(d.y)) >= 4, "clear of %s" % p["kind"])
	check(Vector2(c - CircuitModel.BIKE_CELL).length() > 6.0 and Vector2(c - CircuitModel.LEAGUE_CELL).length() > 6.0)
	check(not Rect2i(CircuitModel.PITCH_CELL, Vector2i(6, 4)).grow(2).has_point(c))
	var hall: Dictionary = CircuitModel.buildings()[1]
	check(Vector2(c - (hall["door"] as Vector2i)).length() < 9.0, "next to the Sports Hall")
	for b in CircuitModel.buildings():
		for bc in CityModel.building_cells(b):
			var d: Vector2i = bc - c
			check(maxi(absi(d.x), absi(d.y)) >= 2, "clear of %s" % b["id"])
