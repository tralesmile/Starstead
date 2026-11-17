extends BaseTest

func test_place_needs_water_and_unique() -> void:
	var p := CrabPots.new()
	check(not p.place(Vector2i(1, 1), 0.5))
	check(not p.place(Vector2i(1, 1), -0.2))
	check(p.place(Vector2i(1, 1), -1.0))
	check(not p.place(Vector2i(1, 1), -1.0))

func test_fills_overnight_to_cap_and_collects() -> void:
	var p := CrabPots.new()
	p.place(Vector2i(2, 2), -4.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 30:
		p.day_tick(rng)
	check_eq((p.pots[Vector2i(2, 2)]["ready"] as Array).size(), CrabPots.MAX_HELD)
	check(p.is_ready(Vector2i(2, 2)))
	var got := p.collect(Vector2i(2, 2))
	check_eq(got.size(), CrabPots.MAX_HELD)
	check(not p.is_ready(Vector2i(2, 2)))
	check_eq(p.collect(Vector2i(9, 9)), [])

func test_catch_table_by_depth() -> void:
	check_eq(CrabPots.catch_for(0.1, false), "minnow")
	check_eq(CrabPots.catch_for(0.1, true), "carp")
	check_eq(CrabPots.catch_for(0.5, true), "crab")

func test_save_roundtrip() -> void:
	var p := CrabPots.new()
	p.place(Vector2i(3, 4), -1.0)
	p.pots[Vector2i(3, 4)]["ready"] = ["crab"]
	var q := CrabPots.new()
	q.from_array(p.to_array())
	check_eq(q.pots[Vector2i(3, 4)]["ready"], ["crab"])
