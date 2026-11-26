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
