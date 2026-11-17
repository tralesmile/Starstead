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
