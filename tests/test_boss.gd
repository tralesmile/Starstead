extends BaseTest

const DT := 1.0 / 60.0

func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func _types(ev: Array) -> Array:
	return ev.map(func(e: Dictionary) -> String: return e["type"])

## Steps until an event of this type shows up; returns it ({} after `limit` seconds).
func _until(b: BossModel, player: Vector2, type: String, rng: RandomNumberGenerator, limit := 10.0) -> Dictionary:
	for i in int(limit / DT):
		for e in b.step(player, DT, rng):
			if e["type"] == type:
				return e
	return {}

func test_sleeps_until_near() -> void:
	var b := BossModel.new_boss(Vector2.ZERO)
	var rng := _rng(1)
	check_eq(b.hp, 260.0)
	check_eq(b.max_hp, 260.0)
	for i in 120:
		check_eq(b.step(Vector2(200, 0), DT, rng), [])
	check_eq(b.state, "sleep")
	check_eq(b.pos, Vector2.ZERO)
	check_eq(_types(b.step(Vector2(160, 0), DT, rng)), ["wake"])
	check_eq(b.state, "walk")

func test_walk_accelerates() -> void:
	var b := BossModel.new_boss(Vector2.ZERO)
	var rng := _rng(1)
	var p := Vector2(160, 0)
	b.step(p, DT, rng)
	b.step(p, DT, rng)
	check(b.vel.length() > 0.0 and b.vel.length() < 5.0, "starts slow %f" % b.vel.length())
	for i in 60:
		b.step(p, DT, rng)
	check(is_equal_approx(b.vel.length(), 40.0), "walk speed %f" % b.vel.length())
	b = BossModel.new_boss(Vector2.ZERO)
	b.take_hit(400.0 * 0.9)
	for i in 61:
		b.step(Vector2(900, 0), DT, rng)
	check(is_equal_approx(b.vel.length(), 58.0), "enraged speed %f" % b.vel.length())

func test_windup_locks_and_dodge() -> void:
	var rng := _rng(2)
	var b := BossModel.new_boss(Vector2.ZERO)
	var p := Vector2(80, 0)
	var w := _until(b, p, "windup", rng)
	check_eq(w.get("at"), p, "locked on the player")
	check_eq(b.telegraph(), 0.0)
	var at_pos := b.pos
	for i in 27:
		b.step(Vector2(80, 70), DT, rng)
	check(absf(b.telegraph() - 0.5) < 0.05, "half way %f" % b.telegraph())
	check_eq(b.slam_at, p, "does not follow")
	check_eq(b.pos, at_pos, "stands still")
	var s := _until(b, Vector2(80, 70), "slam", rng)
	check_eq(s.get("hit"), false)
	check_eq(s.get("damage"), 0.0)
	check_eq(b.telegraph(), 0.0)
	b = BossModel.new_boss(Vector2.ZERO)
	_until(b, p, "windup", rng)
	var t := 0.0
	var got := {}
	while got.is_empty() and t < 3.0:
		t += DT
		for e in b.step(p + Vector2(47, 0), DT, rng):
			got = e
	check(absf(t - 0.9) < 0.03, "windup 0.9 s, was %f" % t)
	check_eq(got.get("hit"), true)
	check_eq(got.get("damage"), 14.0)
	check(b.rocks.is_empty(), "no rocks while calm")

func test_state_timings_and_long_chase() -> void:
	var rng := _rng(3)
	var b := BossModel.new_boss(Vector2.ZERO)
	b.step(Vector2(160, 0), DT, rng)
	var far := Vector2(1000, 0)
	var t := 0.0
	while b.state == "walk" and t < 6.0:
		b.step(far, DT, rng)
		t += DT
	check(absf(t - 4.0) < 0.03, "winds up after 4 s, was %f" % t)
	check(is_equal_approx(b.slam_at.distance_to(b.pos), 96.0), "reach clamped")
	var spent := {}
	for i in 600:
		b.step(far, DT, rng)
		if b.state == "walk":
			break
		spent[b.state] = float(spent.get(b.state, 0.0)) + DT
	check(absf(float(spent.get("slam", 0.0)) - 0.2) < 0.04, "slam %s" % str(spent))
	check(absf(float(spent.get("recover", 0.0)) - 1.4) < 0.04, "recover %s" % str(spent))

func test_stone_hide_wake_and_death() -> void:
	var b := BossModel.new_boss(Vector2.ZERO)
	var r := b.take_hit(10.0)
	check(is_equal_approx(r["dealt"], 4.0), "hide")
	check_eq(b.state, "walk", "hit wakes it")
	check_eq(_types(b.step(Vector2(900, 0), DT, _rng(1))), ["wake"])
	b.state = "recover"
	check_eq(b.take_hit(10.0), {"dealt": 10.0, "dead": false})
	var kill := b.take_hit(1000.0)
	check_eq(kill["dead"], true)
	check(is_equal_approx(kill["dealt"], 246.0), "dealt capped at remaining hp")
	check_eq(b.state, "dead")
	check_eq(b.take_hit(10.0), {"dealt": 0.0, "dead": true})
	check_eq(b.step(Vector2.ZERO, DT, _rng(1)), [])
	check(b.rocks.is_empty())

func test_enrage_once_and_rocks() -> void:
	var rng := _rng(4)
	var b := BossModel.new_boss(Vector2.ZERO)
	b.state = "recover"
	b.take_hit(129.0)
	check(not b.enraged)
	b.take_hit(1.0)
	check(b.enraged, "at exactly half")
	var p := Vector2(60, 0)
	var seen := 0
	var fall := {}
	for i in 600:
		for e in b.step(p, DT, rng):
			if e["type"] == "enrage": seen += 1
			if e["type"] == "rockfall": fall = e
		if not fall.is_empty():
			break
	check_eq(seen, 1)
	check_eq((fall.get("at", []) as Array).size(), 4)
	check((fall.get("at", []) as Array).has(p), "one rock on the player")
	check_eq(b.rocks.size(), 4)
	for rock in b.rocks:
		check(rock["t"] >= 0.8 and rock["t"] <= 1.6 and not rock["done"])
	var lands: Array = []
	for i in 100:
		for e in b.step(p, DT, rng):
			check(e["type"] != "enrage", "only once")
			if e["type"] == "rock_land": lands.append(e)
	check_eq(lands.size(), 4)
	for e in lands:
		var hit: bool = (e["at"] as Vector2).distance_to(p) <= 22.0
		check_eq(e["hit"], hit)
		check_eq(e["damage"], 8.0 if hit else 0.0)
	check(b.rocks.is_empty(), "landed rocks are pruned")

func test_frames_loot_respawn() -> void:
	var b := BossModel.new_boss(Vector2.ZERO)
	check_eq(b.frame(3.0), 0)
	b.state = "walk"
	check_eq(b.frame(0.0), 1)
	check_eq(b.frame(0.26), 2)
	for pair in [["windup", 3], ["slam", 4], ["recover", 5], ["dead", 5]]:
		b.state = pair[0]
		check_eq(b.frame(1.0), pair[1], pair[0])
	var rng := _rng(5)
	var gold := {}
	var silver := {}
	for i in 200:
		var l := BossModel.loot(rng)
		check_eq(l[0], ["warden_core", 1])
		check_eq(l[1][0], "gold_ore")
		check_eq(l[2][0], "silver_ore")
		gold[l[1][1]] = true
		silver[l[2][1]] = true
	var g := gold.keys()
	var s := silver.keys()
	g.sort()
	s.sort()
	check_eq(g, [3, 4, 5])
	check_eq(s, [4, 5, 6])
	check(BossModel.can_respawn(-1, 1))
	check(not BossModel.can_respawn(3, 9))
	check(BossModel.can_respawn(3, 10))

## Player bot: walks into club range and swings; with `dodges` it leaves warning circles 0.25 s after they appear.
func _fight(dodges: bool, seed_no: int) -> Dictionary:
	var rng := _rng(seed_no)
	var b := BossModel.new_boss(Vector2.ZERO)
	var p := Vector2(150, 0)
	var taken := 0.0
	var t := 0.0
	var cd := 0.0
	var seen := {}                  # warning -> when the bot first saw it
	while b.state != "dead" and t < 180.0:
		for e in b.step(p, DT, rng):
			taken += float(e.get("damage", 0.0))
		t += DT
		var dangers: Array = []     # [key, centre, radius]
		if b.state == "windup":
			dangers.append(["slam %s" % str(b.slam_at), b.slam_at, BossModel.SLAM_RADIUS])
		for r in b.rocks:
			if not r["done"]:
				dangers.append(["rock %s" % str(r["pos"]), r["pos"], BossModel.ROCK_RADIUS])
		var away := Vector2.ZERO
		var fleeing := false
		var blocked: Array = []
		for d in dangers:
			if not seen.has(d[0]):
				seen[d[0]] = t
			if dodges and t - float(seen[d[0]]) >= 0.25:
				blocked.append(d)
				var off: Vector2 = p - (d[1] as Vector2)
				if off.length() < float(d[2]) + 3.0:
					fleeing = true
					var dir := off.normalized() if off.length() > 0.5 else (p - b.pos).normalized().orthogonal()
					away += dir * (float(d[2]) + 4.0 - off.length())
		var move := Vector2.ZERO
		if fleeing:
			move = away.normalized() * 110.0 * DT
		elif p.distance_to(b.pos) > 44.0:
			move = (b.pos - p).limit_length(110.0 * DT)
		if not fleeing:             # never walk back into a circle it has noticed
			for d in blocked:
				if (p + move).distance_to(d[1]) < float(d[2]) + 3.0:
					move = Vector2.ZERO
		p += move
		cd -= DT
		if cd <= 0.0 and b.state != "dead" and p.distance_to(b.pos) <= 56.0:
			b.take_hit(8.0)
			cd = 0.5
	return {"won": b.state == "dead", "taken": taken, "time": t}

func test_balance_dodger_wins_and_brawler_suffers() -> void:
	var good_total := 0.0
	var bad_total := 0.0
	for s in range(1, 21):
		var good := _fight(true, s)
		var bad := _fight(false, s)
		check(good["won"], "dodger wins seed %d" % s)
		check(good["taken"] < 100.0, "dodger under 100 damage, took %f" % good["taken"])
		check(good["time"] >= 15.0 and good["time"] <= 90.0, "fight length %f" % good["time"])
		good_total += good["taken"]
		bad_total += bad["taken"]
		if s <= 3:
			print("boss sim seed %d dodger %.0f dmg %.1f s | brawler %.0f dmg %.1f s" % [s, good["taken"], good["time"], bad["taken"], bad["time"]])
	print("boss sim mean dodger %.1f brawler %.1f" % [good_total / 20.0, bad_total / 20.0])
	check(good_total > 0.0, "the fight lands some hits on a dodger")
	check(bad_total > good_total * 3.0 and bad_total / 20.0 > 100.0, "not dodging hurts much more %f vs %f" % [bad_total, good_total])

# --- the boulder throw and the footsteps ---

## A walled room: floor cells 0..13 x 0..9 (448 x 320 px), plus an optional pillar.
func _room(pillar := Vector2i(-99, -99)) -> Callable:
	return func(c: Vector2i) -> bool: return c.x < 0 or c.y < 0 or c.x > 13 or c.y > 9 or c == pillar

func test_wall_contact_and_bounce_velocity() -> void:
	var room := _room()
	check_eq(BossModel.wall_contact(Vector2(100, 100), 10.0, room, Vector2.ZERO), {})
	check_eq(BossModel.wall_contact(Vector2(-500, 0), 10.0, Callable(), Vector2.ZERO), {}, "no query: open ground")
	var c := BossModel.wall_contact(Vector2(6, 100), 10.0, room, Vector2.ZERO)
	check_eq(c.get("normal"), Vector2.RIGHT)
	check(is_equal_approx(float(c.get("depth", 0.0)), 4.0), "depth %s" % str(c))
	c = BossModel.wall_contact(Vector2(1006, 1100), 10.0, room, Vector2(1000, 1000))
	check_eq(c.get("normal"), Vector2.RIGHT, "grid origin is honoured")
	c = BossModel.wall_contact(Vector2(-2, 100), 10.0, room, Vector2.ZERO)
	check_eq(c.get("normal"), Vector2.RIGHT, "a centre inside the wall leaves by the open face")
	check(is_equal_approx(float(c.get("depth", 0.0)), 12.0), "pushed fully clear %s" % str(c))
	check_eq(BossModel.bounce_velocity(Vector2(-100, 40), Vector2.RIGHT, 0.5), Vector2(50, 40))
	check_eq(BossModel.bounce_velocity(Vector2(100, 40), Vector2.RIGHT, 0.5), Vector2(100, 40), "leaving: untouched")

func test_boulder_rolling_friction_and_slow_shatter() -> void:
	var b := BossModel.new_boulder(Vector2.ZERO, Vector2(230, 0))
	var res := {}
	for i in 60:
		res = BossModel.boulder_step(b, DT, Callable(), Vector2.ZERO)
	check(absf((b["vel"] as Vector2).x - (230.0 - BossModel.BOULDER_FRICTION)) < 0.1, "loses %s" % str(b["vel"]))
	check(not res["shatter"])
	check(absf(float(b["rolled"]) - (b["pos"] as Vector2).x) < 0.01, "rolled is the distance covered")
	check(absf(float(b["spin"]) - float(b["rolled"]) / BossModel.BOULDER_R) < 0.01, "spins with the distance")
	var t := 1.0
	while not res["shatter"] and t < 10.0:
		res = BossModel.boulder_step(b, DT, Callable(), Vector2.ZERO)
		t += DT
	var want := (230.0 * 230.0 - pow(BossModel.BOULDER_MIN_SPEED, 2.0)) / (2.0 * BossModel.BOULDER_FRICTION)
	check(absf(float(b["rolled"]) - want) < 4.0, "rolls %f, expected %f" % [b["rolled"], want])
	check_eq(b["bounces"], 0)
	b = BossModel.new_boulder(Vector2.ZERO, Vector2(-200, 0))
	BossModel.boulder_step(b, 0.1, Callable(), Vector2.ZERO)
	check(b["spin"] < 0.0, "turns the other way rolling left")

func test_boulder_bounces_off_walls_and_pillars() -> void:
	var b := BossModel.new_boulder(Vector2(400, 160), Vector2(230, 0))
	var res := {}
	for i in 30:
		res = BossModel.boulder_step(b, DT, _room(), Vector2.ZERO)
		check((b["pos"] as Vector2).x <= 448.0 - BossModel.BOULDER_R + 0.01, "stays out of the wall")
		if res["bounced"]:
			break
	check(res["bounced"], "reaches the wall")
	check((b["vel"] as Vector2).x < 0.0, "comes back")
	check(absf(-(b["vel"] as Vector2).x - float(res["impact"]) * BossModel.BOULDER_RESTITUTION) < 0.5, "restitution %s %s" % [str(b["vel"]), str(res)])
	check_eq(b["bounces"], 1)
	b = BossModel.new_boulder(Vector2(100, 176), Vector2(200, 0))
	var pillar := _room(Vector2i(6, 5))
	for i in 60:
		BossModel.boulder_step(b, DT, pillar, Vector2.ZERO)
		if b["bounces"] > 0:
			break
	check((b["vel"] as Vector2).x < 0.0 and (b["pos"] as Vector2).x <= 192.0 - BossModel.BOULDER_R + 0.01, "pillar turns it %s" % str(b))
	# between close walls it breaks on the last allowed bounce, while still fast
	var slot := func(c: Vector2i) -> bool: return c.x < 0 or c.x > 2
	b = BossModel.new_boulder(Vector2(48, 0), Vector2(265, 0))
	var shattered := false
	for i in 180:
		if BossModel.boulder_step(b, DT, slot, Vector2.ZERO)["shatter"]:
			shattered = true
			break
	check(shattered)
	check_eq(b["bounces"], BossModel.BOULDER_MAX_BOUNCES)
	check((b["vel"] as Vector2).length() > BossModel.BOULDER_MIN_SPEED)

func test_boulder_stays_inside_the_real_hall() -> void:
	var m := CaveModel.generate(1, CaveModel.BOSS_FLOOR)
	var start := Vector2(m.boss_spawn()) * 32.0 + Vector2(16, 24)
	var total := 0
	var escaped := 0
	var endless := 0
	for i in 72:
		var b := BossModel.new_boulder(start, Vector2.from_angle(TAU * i / 72.0) * BossModel.RAGE_BOULDER_SPEED)
		var done := false
		for k in 200:   # long frames, to be sure it cannot tunnel
			done = BossModel.boulder_step(b, 0.05, m.is_solid, Vector2.ZERO)["shatter"]
			if m.is_solid(Vector2i(((b["pos"] as Vector2) / 32.0).floor())):
				escaped += 1
			if done:
				break
		if not done:
			endless += 1
		check(b["bounces"] <= BossModel.BOULDER_MAX_BOUNCES)
		total += int(b["bounces"])
	check_eq(escaped, 0, "never inside rock")
	check_eq(endless, 0, "every throw ends")
	check(total > 36, "the hall gives real ricochets: %d" % total)

func test_boulder_knock_lane_and_roll_frames() -> void:
	check(is_equal_approx(BossModel.knock_force(200.0), 2.0 * BossModel.knock_force(100.0)), "force follows speed")
	check_eq(BossModel.knock_force(0.0), 0.0)
	check(BossModel.boulder_damage(100.0) < BossModel.boulder_damage(230.0))
	check(is_equal_approx(BossModel.boulder_damage(230.0), BossModel.BOULDER_DAMAGE))
	check_eq(BossModel.roll_frame(0.0, 16), 0)
	check_eq(BossModel.roll_frame(TAU / 16.0, 16), 1)
	check_eq(BossModel.roll_frame(-TAU / 16.0, 16), 15)
	check_eq(BossModel.roll_frame(TAU * 3.0, 16), 0)
	var lane := BossModel.trace_lane(Vector2(100, 160), Vector2.RIGHT, _room(), Vector2.ZERO)
	check_eq(lane.size(), 3)
	check(absf(lane[1].x - (448.0 - BossModel.BOULDER_R)) <= BossModel.BOULDER_SUBSTEP, "lane ends at the wall %s" % str(lane))
	check(lane[2].x < lane[1].x, "rebound tail points back")
	lane = BossModel.trace_lane(Vector2.ZERO, Vector2.DOWN, Callable(), Vector2.ZERO, 200.0)
	check_eq(lane.size(), 2)
	check(absf(lane[1].y - 200.0) <= BossModel.BOULDER_SUBSTEP)

func test_footstep_amplitude() -> void:
	for rage in [false, true]:
		var peak: float = BossModel.RAGE_STEP_AMP if rage else BossModel.STEP_AMP
		check(is_equal_approx(BossModel.step_amp(0.0, rage), peak))
		check(is_equal_approx(BossModel.step_amp(BossModel.STEP_NEAR, rage), peak))
		check_eq(BossModel.step_amp(500.0, rage), 0.0)
		var last := peak
		for d in range(0, 320, 4):
			var a := BossModel.step_amp(d, rage)
			check(a <= last + 0.0001, "never grows with distance")
			check(a == 0.0 or a >= BossModel.STEP_MIN_AMP)
			last = a
	for d in [0.0, 80.0, 130.0]:
		check(BossModel.step_amp(d, true) > BossModel.step_amp(d, false), "heavier when enraged at %f" % d)
	check(BossModel.RAGE_STEP_AMP < 2.0, "stays gentle")
	for i in 50:   # whole pixels, never more than 2
		var off := HitMath.shake_offset(BossModel.STEP_SHAKE_TIME * (1.0 - i / 50.0), BossModel.STEP_SHAKE_TIME, BossModel.RAGE_STEP_AMP, i * 0.37)
		check(off == off.round() and absf(off.x) <= 2.0 and absf(off.y) <= 2.0)

func test_throws_only_at_a_distance() -> void:
	var rng := _rng(7)
	for dist in [200.0, 300.0]:
		var b := BossModel.new_boss(Vector2.ZERO)
		b.state = "walk"
		var t := 0.0
		while b.state == "walk" and t < 3.0:
			b.step(b.pos + Vector2(dist, 0), DT, rng)
			t += DT
		check_eq(b.state, "aim", "at %f" % dist)
		check(absf(t - BossModel.FAR_TIME) < 0.04, "after keeping away, was %f" % t)
	for dist in [120.0, 800.0]:   # close by, or out of range: the old slam chase
		var b := BossModel.new_boss(Vector2.ZERO)
		b.state = "walk"
		var aimed := false
		for i in int(5.0 / DT):
			b.step(b.pos + Vector2(dist, 0), DT, rng)
			aimed = aimed or b.state == "aim"
		check(not aimed, "no throw at %f" % dist)

func test_aim_tracks_then_locks_and_punish_window() -> void:
	var rng := _rng(8)
	var b := BossModel.new_boss(Vector2.ZERO)
	b.start_aim(Vector2(200, 0))
	check_eq(b.state, "aim")
	check_eq(b.telegraph(), 0.0, "no slam ring while aiming")
	check_eq(b.frame(0.0), 3)
	b.step(Vector2(0, 200), DT, rng)
	check_eq(b.aim_dir, Vector2.DOWN, "follows")
	check(not b.aim_locked())
	for i in 120:
		if b.aim_locked():
			break
		b.step(Vector2(0, 200), DT, rng)
	check(b.aim_progress() > 0.5 and b.aim_progress() < 0.62, "locks part way %f" % b.aim_progress())
	for i in 10:
		b.step(Vector2(200, 0), DT, rng)
	check_eq(b.aim_dir, Vector2.DOWN, "locked lane does not follow")
	check(not _until(b, Vector2(200, 0), "throw", rng, 1.0).is_empty())
	check_eq(b.frame(0.0), 4)
	check(is_equal_approx(b.take_hit(10.0)["dealt"], 4.0), "still stone while the boulder rolls")
	check(not _until(b, Vector2(200, 0), "shatter", rng, 8.0).is_empty())
	check(b.boulder.is_empty())
	check_eq(b.state, "recover")
	check(is_equal_approx(b.take_hit(10.0)["dealt"], 10.0), "punish window takes full damage")
	var t := 0.0
	while b.state == "recover" and t < 5.0:
		b.step(Vector2(1000, 0), DT, rng)
		t += DT
	check(absf(t - BossModel.PUNISH_TIME) < 0.04, "window %f" % t)
	var early := false
	for i in int((BossModel.THROW_COOLDOWN - BossModel.PUNISH_TIME - 0.2) / DT):
		b.step(b.pos + Vector2(220, 0), DT, rng)
		early = early or b.state == "aim"
	check(not early, "cooldown")
	check(not _until(b, b.pos + Vector2(220, 0), "aim", rng, 3.0).is_empty(), "throws again later")

func test_killing_it_removes_the_boulder() -> void:
	var b := BossModel.new_boss(Vector2.ZERO)
	b.start_aim(Vector2(200, 0))
	_until(b, Vector2(200, 0), "throw", _rng(9), 2.0)
	check(not b.boulder.is_empty())
	b.take_hit(10000.0)
	check(b.boulder.is_empty())

## Throws at a player `dist` away; with `dodges` they run across the lane 0.25 s after it locks.
func _throw_at(dodges: bool, angle: float, dist: float, rage: bool) -> Array:
	var rng := _rng(10)
	var b := BossModel.new_boss(Vector2.ZERO)
	b.enraged = rage
	var p := Vector2.from_angle(angle) * dist
	b.start_aim(p)
	var locked_for := 0.0
	var hits: Array = []
	for i in 600:
		for e in b.step(p, DT, rng):
			if e["type"] == "boulder_hit":
				hits.append(e)
			if e["type"] == "shatter":
				return hits
		if b.aim_locked() or b.state == "throw":
			locked_for += DT
		if dodges and locked_for >= 0.25 and absf((p - b.pos).cross(b.aim_dir)) < BossModel.BOULDER_HIT_R + 4.0:
			p += b.aim_dir.orthogonal() * 110.0 * DT
	return hits

func test_boulder_is_fair_to_dodge_and_hurts_by_speed() -> void:
	for rage in [false, true]:
		for dist in [BossModel.THROW_MIN_DIST, 220.0, 330.0]:
			for k in 8:
				var a := TAU * k / 8.0
				check_eq(_throw_at(true, a, dist, rage).size(), 0, "dodged at %f rage %s" % [dist, rage])
				check_eq(_throw_at(false, a, dist, rage).size(), 1, "standing still is hit once at %f" % dist)
	var near: Dictionary = _throw_at(false, 0.0, 150.0, false)[0]
	var far: Dictionary = _throw_at(false, 0.0, 330.0, false)[0]
	check(near["force"] > far["force"] and near["damage"] > far["damage"], "a slower boulder hits softer")
	check(is_equal_approx(near["force"], BossModel.knock_force((near["vel"] as Vector2).length())))
