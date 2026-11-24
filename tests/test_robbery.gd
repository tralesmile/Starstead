extends BaseTest

func _m() -> RobberyModel:
	return RobberyModel.new(DataDB.load_json("loot"))

func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func test_seeded_house_deterministic() -> void:
	var a := _m().house("farm")
	var b := _m().house("farm")
	check_eq(a["loot"], b["loot"])
	check_eq(a["lock_level"], b["lock_level"])
	check(a["loot"].size() >= 2 and a["loot"].size() <= 4)
	check(not a["looted"])

func test_pick_chance_scales() -> void:
	var m := _m()
	check(m.pick_chance(1, 0) > m.pick_chance(4, 0))
	check(m.pick_chance(2, 5) > m.pick_chance(2, 0))
	check(m.pick_chance(5, 0) >= 0.05 and m.pick_chance(0, 99) <= 0.95)

func test_pick_and_loot() -> void:
	var m := _m()
	var h := m.house("h1")
	h["locked"] = true
	h["lock_level"] = 0
	var tries := 0
	while not m.attempt_pick("h1", 10, _rng(tries)):
		tries += 1
		check(tries < 50)
		if tries >= 50:
			return
	check(not h["locked"])
	check(m.noise > 0.0)
	var total := m.remaining_value("h1")
	var got := 0
	var it := m.loot_item("h1")
	while it != "":
		got += m.loot_value(it)
		it = m.loot_item("h1")
	check_eq(got, total)
	check(h["looted"])

func test_locked_blocks_loot() -> void:
	var m := _m()
	m.house("h2")["locked"] = true
	check_eq(m.loot_item("h2"), "")

func test_noise_rises_decays_wakes() -> void:
	var m := _m()
	m.house("h3")
	m.tick("h3", 1.0, true, true)
	check(m.noise > 0.0)
	var n := m.noise
	m.tick("h3", 1.0, false, false)
	check(m.noise < n)
	check(not m.residents_awake())
	for i in 10:
		m.tick("h3", 1.0, true, true)
	check(m.residents_awake())
	check(m.noise <= 100.0)

func test_witnessed_heat() -> void:
	var m := _m()
	var quiet := m.heat_after(0.0)
	m.add_noise(100.0)
	check(m.heat_after(0.0) > quiet)
	check_eq(m.heat_after(0.0), WantedMath.add(0.0, "robbery", true))

func test_memory_after_robbery() -> void:
	var m := _m()
	var h := m.house("h4")
	h["lock_level"] = 1
	m.finish_robbery("h4", _rng(1))
	check_eq(h["lock_level"], 2)
	check(h["grudge"] and h["locked"] and not h["dog"])
	m.cfg["memory"]["dog_chance"] = 1.0
	m.finish_robbery("h4", _rng(1))
	check(h["dog"])
	check_eq(h["lock_level"], 3)

func test_serialize_roundtrip() -> void:
	var m := _m()
	m.house("a")
	m.finish_robbery("b", _rng(3))
	m.add_noise(30.0)
	var d: Dictionary = JSON.parse_string(JSON.stringify(m.serialize()))
	var n := _m()
	n.deserialize(d)
	check_eq(n.noise, 30.0)
	check_eq(n.house("b")["lock_level"], m.house("b")["lock_level"])
	check_eq(n.house("a")["loot"], m.house("a")["loot"])
	check(n.house("b")["grudge"])

func _force(m: RobberyModel, id: String, safe: bool, alarm: bool) -> Dictionary:
	var h := m.house(id)
	h["locked"] = false
	h["safe"] = safe
	h["safe_cash"] = 200
	h["safe_open"] = false
	h["alarm"] = alarm
	h["alarm_armed"] = alarm
	return h

func test_safe_crack() -> void:
	var m := _m()
	_force(m, "s1", true, false)
	check(m.safe_chance(10) > m.safe_chance(0))
	var got := -1
	var r := _rng(3)
	for i in 60:
		got = m.crack_safe("s1", 5, r)
		if got >= 0:
			break
	check_eq(got, 200)
	check_eq(m.crack_safe("s1", 5, r), -1)   # already open
	check(m.noise > 0.0)
	var none := _force(m, "s2", false, false)
	check_eq(m.crack_safe("s2", 5, r), -1)

func test_safe_refills_smaller() -> void:
	var m := _m()
	var h := _force(m, "s3", true, false)
	h["safe_open"] = true
	m.finish_robbery("s3", _rng(1))
	check(not h["safe_open"])
	check_eq(h["safe_cash"], 120)

func test_alarm_trigger_and_cut() -> void:
	var m := _m()
	var h := _force(m, "a1", false, true)
	check(not m.alarm_check("a1"))
	m.add_noise(40.0)
	check(m.alarm_check("a1"))
	check(not m.alarm_check("a1"))   # fires once
	check(h["alarm_fired"] and m.noise >= 100.0)
	var h2 := _force(m, "a2", false, true)
	var ok := false
	var r := _rng(9)
	for i in 80:
		h2["alarm_armed"] = true
		h2["alarm_fired"] = false
		if m.cut_alarm("a2", 8, r):
			ok = true
			break
	check(ok)
	check(not h2["alarm_armed"])
	check(m.cut_chance(8) > m.cut_chance(0))

func test_step_noise() -> void:
	var st: Dictionary = DataDB.load_json("loot")["step_noise"]
	check_eq(RobberyModel.step_noise_rate(st, false, true, false), 0.0)
	check_eq(RobberyModel.step_noise_rate(st, true, false, true), 0.0)
	check(RobberyModel.step_noise_rate(st, true, true, false) > RobberyModel.step_noise_rate(st, true, false, false))
	var m := _m()
	m.add_noise(10.0)
	m.tick_steps("x", 1.0, true, false, false)
	m.tick("x", 1.0, false, false)   # stepping pauses the decay
	check(m.noise > 10.0)
	m.tick("x", 1.0, false, false)
	check(m.noise < 10.9)

func test_save_keeps_safe_alarm() -> void:
	var m := _m()
	_force(m, "z", true, true)
	var m2 := _m()
	m2.deserialize(m.serialize())
	check(m2.house("z")["safe"] and m2.house("z")["alarm_armed"])
	m2.deserialize({"noise": 0, "houses": {"old": {"locked": false, "loot": []}}})
	check(not m2.house("old")["safe"])

func test_extras_layout() -> void:
	for id in ["city_house1", "city_house2", "city_house3", "city_apt_a", "farm_house_x"]:
		var l := InteriorModel.with_extras(InteriorModel.layout_for(id), true, false, true, true)
		var ids := []
		for f in l["furniture"]:
			ids.append(f["id"])
		check("safe" in ids and "alarm" in ids, id)
		var rects := InteriorModel.solid_rects(l)
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				check(not rects[i].intersects(rects[j]), "%s overlap %s %s" % [id, rects[i], rects[j]])
		var door := Rect2((int(l["door_x"]) - 0.5) * 32.0, (int(l["h"]) - 2) * 32.0, 64.0, 64.0)
		for r in rects:
			check(not r.intersects(door.grow(-4.0)), id + " blocks door")

func test_alarm_math() -> void:
	check_eq(AlarmMath.pulse(-1.0), 0.0)
	check_eq(AlarmMath.pulse(7.0), 0.0)
	var peak := 0.0
	for i in 100:
		peak = maxf(peak, AlarmMath.pulse(i * 0.02))
	check(peak > 0.2 and peak <= 0.28)
	check(AlarmMath.pulse(5.9) < 0.06)
	check(AlarmMath.ringing(1.0) and not AlarmMath.ringing(6.5))
	check(AlarmMath.shake(0.0) > AlarmMath.shake(0.4) and AlarmMath.shake(1.0) == 0.0)
