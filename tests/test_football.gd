extends BaseTest

const DT := FootballMatch.TICK
const SEEDS := 10

# ---- helpers ----

func _ball(at: Vector2, vel: Vector2 = Vector2.ZERO, wet: float = 0.0) -> FootballBall:
	var b := FootballBall.new()
	b.reset(at)
	b.vel = vel
	b.wet = wet
	return b

## Steps until the first non-empty event (or the time runs out) and returns it.
func _first_event(b: FootballBall, seconds: float = 3.0) -> String:
	for i in int(seconds / DT):
		var ev := b.step(DT)
		if ev != "":
			return ev
	return ""

func _inside(p: Vector2, slack: float = 0.001) -> bool:
	return p.x >= -slack and p.y >= -slack and p.x <= FootballBall.FIELD.x + slack and p.y <= FootballBall.FIELD.y + slack

## Plays a whole AI match in 0.25 s slices and reports bounds / half-time bookkeeping.
func _play(home: int, away: int, seed_value: int) -> Dictionary:
	var m := FootballMatch.new(home, away, seed_value)
	m.auto = true
	var out := {"m": m, "halves": 0, "fulls": 0, "goals": [0, 0], "ball_ok": true, "players_ok": true, "steps": 0}
	while not m.finished and out["steps"] < 2000:
		m.update(0.25)
		out["steps"] += 1
		for e in m.events:
			if e == "half":
				out["halves"] += 1
			elif e == "full":
				out["fulls"] += 1
			elif e == "goal0":
				out["goals"][0] += 1
			elif e == "goal1":
				out["goals"][1] += 1
		m.events.clear()
		if not _inside(m.ball.pos):
			out["ball_ok"] = false
		for p in m.players:
			# players are clamped to the field, then _separate() may nudge them by under 5 px
			if not _inside(p["pos"], 1.0):
				out["players_ok"] = false
	return out

func _kicked_off(auto: bool = false) -> FootballMatch:
	var m := FootballMatch.new(2, 2, 5)
	m.auto = auto
	m.pause = 0.0
	return m

# ---- ball ----

func test_friction_stops_the_ball() -> void:
	var b := _ball(Vector2(60, 120))
	b.kick(Vector2.RIGHT, 150.0)
	var last := b.vel.length()
	var never_sped_up := true
	for i in 600:
		b.step(DT)
		if b.vel.length() > last + 0.001:
			never_sped_up = false
		last = b.vel.length()
	check(never_sped_up, "rolling ball only slows")
	check_eq(b.vel, Vector2.ZERO, "stopped")
	check(b.pos.x > 100.0 and b.pos.x < FootballBall.FIELD.x, "rolled a sensible way: %s" % b.pos)
	check(b.roll > 40.0, "roll distance tracked")

func test_wet_pitch_rolls_further() -> void:
	var dry := _ball(Vector2(40, 120), Vector2(180, 0), 0.0)
	var wet := _ball(Vector2(40, 120), Vector2(180, 0), 1.0)
	for i in 600:
		dry.step(DT)
		wet.step(DT)
	check(wet.pos.x > dry.pos.x + 20.0, "wet %s dry %s" % [wet.pos.x, dry.pos.x])
	check(FootballBall.roll_drag(1.0) < FootballBall.roll_drag(0.0))
	check(FootballBall.roll_decel(1.0) < FootballBall.roll_decel(0.0))
	check_eq(FootballBall.roll_drag(5.0), FootballBall.roll_drag(1.0), "wetness clamped")

func _rebound_height(wetness: float) -> float:
	var b := _ball(Vector2(200, 120), Vector2(20, 0), wetness)
	b.z = 60.0
	var landed := false
	var peak := 0.0
	for i in 180:
		b.step(DT)
		if b.z <= 0.0:
			landed = true
		elif landed:
			peak = maxf(peak, b.z)
	return peak

func test_wet_pitch_bounces_lower() -> void:
	var dry := _rebound_height(0.0)
	var wet := _rebound_height(1.0)
	check(dry > 5.0, "dry ball bounces: %s" % dry)
	check(wet > 0.0 and wet < dry * 0.75, "wet %s dry %s" % [wet, dry])
	check(FootballBall.bounce_keep(1.0) < FootballBall.bounce_keep(0.0))

func test_curl_bends_the_path() -> void:
	var ys := []
	for spin: float in [-0.8, 0.0, 0.8]:
		var b := _ball(Vector2(100, 120))
		b.kick(Vector2.RIGHT, 250.0, 0.0, spin)
		for i in 60:
			b.step(DT)
		ys.append(b.pos.y)
		check(absf(b.curl) < absf(spin) * 0.5 + 0.001, "spin decays")
	check(absf(ys[1] - 120.0) < 0.01, "no spin goes straight")
	check(ys[2] > 135.0, "positive spin bends clockwise (down screen): %s" % ys[2])
	check(ys[0] < 105.0, "negative spin bends the other way: %s" % ys[0])

func test_goals_on_both_sides() -> void:
	var mid := FootballBall.FIELD.y * 0.5
	for off: float in [-25.0, 0.0, 25.0]:
		check_eq(_first_event(_ball(Vector2(60, mid + off), Vector2(-300, 0))), "goal_left")
		check_eq(_first_event(_ball(Vector2(FootballBall.FIELD.x - 60, mid + off), Vector2(300, 0))), "goal_right")

func test_over_the_bar_is_no_goal() -> void:
	for side in 2:
		var x := 8.0 if side == 0 else FootballBall.FIELD.x - 8.0
		var b := _ball(Vector2(x, 120), Vector2(-300 if side == 0 else 300, 0))
		b.z = FootballBall.BAR_Z + 20.0
		b.vz = 60.0
		var goal := false
		for i in 20:
			if b.step(DT).begins_with("goal"):
				goal = true
			check(_inside(b.pos), "high ball thrown back in: %s" % b.pos)
		check(not goal, "over the bar, side %d" % side)
		check((b.vel.x > 0.0) == (side == 0), "came back off the end boards")

func test_crossbar_rebounds() -> void:
	for side in 2:
		var x := 2.0 if side == 0 else FootballBall.FIELD.x - 2.0
		var b := _ball(Vector2(x, 120), Vector2(-300 if side == 0 else 300, 0))
		b.z = FootballBall.BAR_Z
		b.vz = 2.0
		check_eq(b.step(DT), "post", "bar, side %d" % side)
		check((b.vel.x > 0.0) == (side == 0))
		check(_inside(b.pos))

func test_wide_of_the_mouth_hits_boards() -> void:
	for y: float in [30.0, FootballBall.mouth_top() - 14.0, FootballBall.mouth_bottom() + 14.0, 210.0]:
		for side in 2:
			var x := 60.0 if side == 0 else FootballBall.FIELD.x - 60.0
			var b := _ball(Vector2(x, y), Vector2(-300 if side == 0 else 300, 0))
			check_eq(_first_event(b), "wall", "y %s side %d" % [y, side])
			check((b.vel.x > 0.0) == (side == 0))
			check(_inside(b.pos))

func test_side_boards_keep_the_ball_in() -> void:
	for dir: float in [-1.0, 1.0]:
		var b := _ball(Vector2(250, 120), Vector2(0, 300 * dir))
		check_eq(_first_event(b), "wall")
		check(b.vel.y * dir < 0.0, "reflected")
		check(absf(b.vel.y) < 300.0 * FootballBall.WALL_KEEP + 0.01, "loses pace")
		check(_inside(b.pos))

func test_posts_rebound() -> void:
	for gx: float in [0.0, FootballBall.FIELD.x]:
		for gy: float in [FootballBall.mouth_top(), FootballBall.mouth_bottom()]:
			var inward := 1.0 if gx == 0.0 else -1.0
			var b := _ball(Vector2(gx + inward * 50.0, gy), Vector2(-inward * 280.0, 0))
			check_eq(_first_event(b), "post", "post at %s,%s" % [gx, gy])
			check(b.vel.x * inward > 0.0, "bounced back out")
			check(b.pos.distance_to(Vector2(gx, gy)) >= FootballBall.RADIUS + FootballBall.POST_R - 0.01)
			check(_inside(b.pos))

func test_wild_kicks_never_leave_the_pitch() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var bad := 0
	var goals := 0
	for k in 400:
		# half of them aimed close to a post, where the geometry is fiddliest
		var b := _ball(Vector2(rng.randf_range(6, 514), rng.randf_range(6, 234)), Vector2.ZERO, rng.randf())
		var aim := Vector2.from_angle(rng.randf() * TAU)
		if k % 2 == 0:
			var post := Vector2(0.0 if k % 4 == 0 else FootballBall.FIELD.x,
				FootballBall.mouth_top() if k % 8 < 4 else FootballBall.mouth_bottom())
			aim = (post + Vector2(0, rng.randf_range(-9, 9)) - b.pos).normalized()
		b.kick(aim, rng.randf_range(50, 420), rng.randf_range(0, 200), rng.randf_range(-0.8, 0.8))
		for i in 150:
			var ev := b.step(DT)
			if ev.begins_with("goal"):
				goals += 1
				break
			if not _inside(b.pos):
				bad += 1
				break
	check_eq(bad, 0, "kicks that escaped")
	check(goals > 0, "some went in")

func test_pass_speed_monotonic_and_clamped() -> void:
	var prev := 0.0
	for d in range(0, 700, 10):
		var s := FootballBall.pass_speed(float(d))
		check(s >= prev, "monotonic at %d" % d)
		check(s >= 130.0 and s <= 330.0, "clamped at %d" % d)
		prev = s
	check_eq(FootballBall.pass_speed(0.0), 130.0)
	check_eq(FootballBall.pass_speed(5000.0), 330.0)
	check(FootballBall.pass_speed(150.0) > FootballBall.pass_speed(80.0))

# ---- match ----

func test_two_halves_then_finished() -> void:
	var r := _play(2, 2, 11)
	var m: FootballMatch = r["m"]
	check(m.finished, "finished")
	check_eq(r["halves"], 1)
	check_eq(r["fulls"], 1)
	check_eq(m.half, 2)
	check_eq(m.minute(), 90)
	check_eq(m.time_left(), 0.0)
	check_eq(r["goals"], m.score, "goal events match the score")
	check_eq(m.result(), signi(m.score[0] - m.score[1]))
	var frozen := [m.score.duplicate(), m.ball.pos, m.clock]
	m.update(0.25)
	check_eq([m.score.duplicate(), m.ball.pos, m.clock], frozen, "nothing moves after full time")
	check(m.events.is_empty())

func test_same_seed_same_match() -> void:
	var a: FootballMatch = _play(2, 3, 1234)["m"]
	var b: FootballMatch = _play(2, 3, 1234)["m"]
	check_eq(a.score, b.score)
	check_eq(a.stats, b.stats)
	check_eq(a.ball.pos, b.ball.pos)
	for i in a.players.size():
		check_eq(a.players[i]["pos"], b.players[i]["pos"], "player %d" % i)

func test_balance_and_bounds_over_seeds() -> void:
	var strong := 0
	var weak := 0
	var ball_bad := 0
	var players_bad := 0
	var unfinished := 0
	for pairing in [[1, 1], [4, 4], [4, 1], [1, 4]]:
		var total := 0
		var wins := [0, 0]
		for s in SEEDS:
			var r := _play(pairing[0], pairing[1], 100 + s)
			var m: FootballMatch = r["m"]
			total += m.score[0] + m.score[1]
			if m.result() != 0:
				wins[0 if m.result() > 0 else 1] += 1
			if not m.finished or r["halves"] != 1:
				unfinished += 1
			if not r["ball_ok"]:
				ball_bad += 1
			if not r["players_ok"]:
				players_bad += 1
		var avg := float(total) / SEEDS
		print("football %s: %.1f goals/match, wins home %d away %d" % [str(pairing), avg, wins[0], wins[1]])
		if pairing[0] == pairing[1]:
			check(avg >= 1.5 and avg <= 10.0, "goals per match %s: %s" % [str(pairing), avg])
		else:
			var s_side := 0 if pairing[0] > pairing[1] else 1
			strong += wins[s_side]
			weak += wins[1 - s_side]
	print("football tier 4 vs 1 over %d: strong %d, weak %d" % [SEEDS * 2, strong, weak])
	check(strong >= weak * 2 + 4, "tier 4 wins %d, tier 1 wins %d" % [strong, weak])
	check_eq(unfinished, 0, "unfinished matches")
	check_eq(ball_bad, 0, "matches where the ball left the pitch")
	check_eq(players_bad, 0, "matches where a player left the pitch")

func test_shoot_releases_with_kick_lock() -> void:
	var m := _kicked_off()
	var i := m.owner
	m.shoot(i, 0.4, Vector2.ZERO)
	check_eq(m.owner, -1)
	check_eq(m.last_touch, i)
	check_eq(m.players[i]["lock"], FootballMatch.KICK_LOCK)
	check(m.ball.vel.x > 0.0, "team 0 shoots right")
	check_eq(m.stats["shots"], [1, 0])
	check(m.events.has("kick"))
	for k in 10:
		m.update(DT)
		check(m.owner != i, "kicker cannot trap it again while locked")

func test_pass_releases_with_kick_lock() -> void:
	var m := _kicked_off()
	var i := m.owner
	var j := m.pass_target(i, Vector2(0, 1))
	check(j >= 1 and j <= 3 and j != i, "an outfield team-mate: %d" % j)
	m.pass_ball(i, Vector2(0, 1))
	check_eq(m.owner, -1)
	check_eq(m.players[i]["lock"], FootballMatch.KICK_LOCK)
	check_eq(m.selected, j, "control follows the pass")
	check((m.players[j]["pos"] - m.ball.pos).dot(m.ball.vel) > 0.0, "heads for the target")
	for k in 10:
		m.update(DT)
		check(m.owner != i)

func test_shot_power_and_lift() -> void:
	for c: float in [-1.0, 0.0, 0.2, 0.3, 0.43]:
		check_eq(FootballMatch.shot_lift(c), 0.0, "gentle shot stays down %s" % c)
	check(FootballMatch.shot_lift(FootballMatch.CHARGE_TIME) > 100.0)
	check(FootballMatch.shot_lift(0.6) < FootballMatch.shot_lift(0.75))
	check_eq(FootballMatch.shot_speed(0.0), FootballMatch.SHOT_MIN)
	check_eq(FootballMatch.shot_speed(99.0), FootballMatch.SHOT_MAX)
	check(FootballMatch.shot_speed(0.5) > FootballMatch.shot_speed(0.2))

func test_human_move_and_sprint() -> void:
	var m := _kicked_off()
	check_eq(m.selected, 2)
	var start: Vector2 = m.players[2]["pos"]
	for k in 4:
		m.update(0.1, {"move": Vector2(0, -1), "sprint": true})
	check(m.players[2]["pos"].y < start.y - 15.0, "moved up: %s from %s" % [m.players[2]["pos"], start])
	check(m.players[2]["stamina"] < 1.0, "sprinting costs stamina")
	check_eq(m.owner, 2, "kept the ball")
	check(m.ball.pos.distance_to(m.players[2]["pos"]) < 16.0, "dribbled along")
	check_eq(m.stats["shots"], [0, 0])

func test_human_shoot_applies_once() -> void:
	var m := _kicked_off()
	m.update(0.25, {"move": Vector2.ZERO, "shoot": 0.3, "curl": 0.5})
	check_eq(m.stats["shots"][0], 1)
	check_eq(m.events.count("kick"), 1)
	check(m.owner != 2)
	check(m.ball.pos.x > FootballBall.FIELD.x * 0.5 + 10.0, "ball flew toward goal")

func test_human_pass_tackle_and_switch() -> void:
	var m := _kicked_off()
	m.update(DT, {"move": Vector2(0, 1), "pass": true})
	check_eq(m.owner, -1)
	check(m.events.has("kick"))
	check(m.selected != 2, "now controlling the receiver")
	# without the ball, "tackle" starts a slide
	m = _kicked_off()
	m.owner = -1
	m.ball.pos = Vector2(60, 30)
	m.update(DT, {"move": Vector2.ZERO, "tackle": true})
	check(m.players[m.selected]["slide"] > 0.0, "sliding")
	# manual switch picks another outfield player
	m = _kicked_off()
	m.owner = -1
	var before := m.selected
	m.update(DT, {"switch": true})
	check(m.selected != before and m.selected >= 1 and m.selected <= 3, "switched to %d" % m.selected)

func test_pause_ignores_input() -> void:
	var m := FootballMatch.new(1, 1, 3)
	var start: Vector2 = m.players[2]["pos"]
	m.update(0.25, {"move": Vector2(0, 1), "shoot": 0.3})
	check_eq(m.players[2]["pos"], start)
	check_eq(m.clock, 0.0)
	check_eq(m.stats["shots"], [0, 0])

# ---- league ----

func test_can_play_reasons() -> void:
	var l := FootballLeague.new()
	check_eq(l.can_play(1, 100, 100.0, 12.0), "")
	check_eq(l.can_play(1, FootballLeague.MATCH_FEE, 21.0, 8.0), "", "limits inclusive where they should be")
	check(l.can_play(1, 100, 100.0, 7.9).contains("Kick-offs"))
	check(l.can_play(1, 100, 100.0, 20.0).contains("Kick-offs"))
	check(l.can_play(1, 100, float(FootballLeague.ENERGY_COST), 12.0).contains("tired"))
	check(l.can_play(1, FootballLeague.MATCH_FEE - 1, 100.0, 12.0).contains("fee"))
	l.record(1, 1, 5)
	check(l.can_play(5, 100, 100.0, 12.0).contains("tomorrow"))
	check_eq(l.can_play(6, 100, 100.0, 12.0), "")

func test_record_updates_the_table() -> void:
	var l := FootballLeague.new()
	var rival := l.opponent()
	var res := l.record(3, 1, 4)
	check_eq(l.table[0], [1, 1, 0, 0, 3, 1])
	check_eq(l.table[rival], [1, 0, 0, 1, 1, 3])
	for row in l.table:
		check_eq(row[0], 1, "everyone played")
		check_eq(row[0], row[1] + row[2] + row[3])
	check_eq(res["pay"], FootballLeague.WIN_PAY)
	check(not res["season_over"] and not res["champion"])
	check_eq(l.round_i, 1)
	check_eq(l.last_day, 4)
	check_eq(l.record(2, 2, 5)["pay"], FootballLeague.DRAW_PAY)
	check_eq(l.record(0, 1, 6)["pay"], 0)
	check_eq(l.table[0], [3, 1, 1, 1, 5, 4])
	check_eq(FootballLeague.points(l.table[0]), 4)

func test_season_is_three_rounds_meeting_everyone() -> void:
	var l := FootballLeague.new()
	var met := []
	for r in 3:
		check(not l.season_done())
		met.append(l.opponent())
		var res := l.record(1, 1, r)
		check_eq(res["season_over"], r == 2)
	met.sort()
	check_eq(met, [1, 2, 3])
	check(l.season_done())
	for row in l.table:
		check_eq(row[0], 3, "final table stays readable")
	var order := l.standings()
	check_eq(order.size(), 4)
	for i in 3:
		check(FootballLeague.points(l.table[order[i]]) >= FootballLeague.points(l.table[order[i + 1]]), "standings sorted")
	l.start_next_season()
	check_eq(l.season, 2)
	check_eq(l.round_i, 0)
	check_eq(l.table[0], [0, 0, 0, 0, 0, 0])

func test_record_after_a_finished_season_rolls_over() -> void:
	var l := FootballLeague.new()
	for r in 3:
		l.record(0, 0, r)
	l.record(2, 0, 9)
	check_eq(l.season, 2)
	check_eq(l.round_i, 1)
	check_eq(l.table[0], [1, 1, 0, 0, 2, 0])

func test_champion_bonus_titles_and_rival_tiers() -> void:
	var l := FootballLeague.new()
	var base := [l.tier_of(0), l.tier_of(1), l.tier_of(2), l.tier_of(3)]
	check_eq(base, FootballLeague.BASE_TIER)
	var day := 0
	for title in range(1, 5):
		var res := {}
		for r in 3:
			day += 1
			res = l.record(9, 0, day)
		check(res["champion"] and res["season_over"])
		check_eq(res["place"], 1)
		check_eq(res["pay"], FootballLeague.WIN_PAY + FootballLeague.CHAMPION_PAY)
		check(res["text"].contains("CHAMPIONS"))
		check_eq(l.titles, title)
		check_eq(l.tier_of(0), base[0], "your tier is fixed")
		for c in range(1, 4):
			check_eq(l.tier_of(c), mini(4, base[c] + mini(title, 2)), "club %d after %d titles" % [c, title])

func test_losing_season_pays_no_bonus() -> void:
	var l := FootballLeague.new()
	var res := {}
	for r in 3:
		res = l.record(0, 9, r)
	check(res["season_over"] and not res["champion"])
	check_eq(res["place"], 4)
	check_eq(res["pay"], 0)
	check_eq(l.titles, 0)

func test_simulated_goals_follow_tiers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var high := 0
	var low := 0
	for i in 500:
		var a := FootballLeague.sim_goals(4, 1, rng)
		var b := FootballLeague.sim_goals(1, 4, rng)
		check(a >= 0 and a <= 8 and b >= 0 and b <= 8)
		high += a
		low += b
	check(high > low * 3)

func test_save_roundtrip_through_json() -> void:
	var a := FootballLeague.new()
	for r in 3:
		a.record(5, 0, r + 1)
	a.record(2, 1, 8)
	var parsed = JSON.parse_string(JSON.stringify(a.to_dict()))
	var b := FootballLeague.new()
	b.from_dict(parsed)
	check_eq(b.season, a.season)
	check_eq(b.round_i, a.round_i)
	check_eq(b.titles, a.titles)
	check_eq(b.last_day, a.last_day)
	check_eq(b.table, a.table)
	for row in b.table:
		for v in row:
			check_eq(typeof(v), TYPE_INT, "floats from JSON become ints")
	check_eq(b.standings(), a.standings())
	check_eq(b.record(1, 0, 9), a.record(1, 0, 9), "same future after loading")
	check_eq(b.table, a.table)
	var fresh := FootballLeague.new()
	fresh.from_dict({})
	check_eq(fresh.season, 1)
	check_eq(fresh.round_i, 0)
	check_eq(fresh.last_day, -1)
	check_eq(fresh.table[3], [0, 0, 0, 0, 0, 0])

func test_press_survives_frames_with_no_tick() -> void:
	var m := FootballMatch.new(1, 1, 3)
	m.pause = 0.0
	m.update(1.0 / 144.0, {"shoot": 0.3})   # too short to run a tick
	for i in 4:
		m.update(1.0 / 144.0)
	check_eq(int(m.stats["shots"][0]), 1)
