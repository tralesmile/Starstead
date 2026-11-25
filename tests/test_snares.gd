extends BaseTest

func test_place_needs_dry_land_and_unique() -> void:
	var s := Snares.new()
	check(not s.place(Vector2i(1, 1), 0.5, "meadow"))
	check(not s.place(Vector2i(1, 1), 3.0, "meadow", true))
	check(s.place(Vector2i(1, 1), 3.0, "meadow"))
	check(not s.place(Vector2i(1, 1), 3.0, "meadow"))

func test_habitat_by_chunk() -> void:
	check_eq(Snares.habitat_for(Vector2i(1, 3)), "forest")
	check_eq(Snares.habitat_for(Vector2i(3, 4)), "meadow")
	check_eq(Snares.habitat_for(Vector2i(1, 6)), "meadow")

func test_catch_tables() -> void:
	check_eq(Snares.catch_for(0.05, "forest"), [])
	check_eq(Snares.catch_for(0.3, "forest"), ["raw_meat", "hide"])
	check_eq(Snares.catch_for(0.7, "forest"), ["raw_meat", "feather"])
	check_eq(Snares.catch_for(0.2, "meadow"), [])
	check_eq(Snares.catch_for(0.5, "meadow"), ["raw_meat"])

func test_rain_halves_catches() -> void:
	var dry := 0
	var wet := 0
	for seed in 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var s := Snares.new()
		for i in 25:
			s.place(Vector2i(i, 0), 4.0, "forest")
		dry += s.night_tick(rng, false)
		rng.seed = seed
		var w := Snares.new()
		for i in 25:
			w.place(Vector2i(i, 0), 4.0, "forest")
		wet += w.night_tick(rng, true)
	check(wet < dry)
	check(dry > 0)

func test_collect_resets_and_wears_out() -> void:
	var s := Snares.new()
	s.place(Vector2i(2, 2), 4.0, "meadow")
	var c := Vector2i(2, 2)
	s.snares[c]["ready"] = ["raw_meat"]
	s.snares[c]["uses"] = 1
	check(s.is_ready(c))
	check(not s.pick_up(c))
	check_eq(s.collect(c), ["raw_meat"])
	check(not s.is_ready(c))
	check(s.snares.has(c))
	s.snares[c]["ready"] = ["raw_meat"]
	s.snares[c]["uses"] = Snares.BREAK_AFTER
	s.collect(c)
	check(not s.snares.has(c))
	check_eq(s.collect(Vector2i(9, 9)), [])

func test_save_roundtrip() -> void:
	var s := Snares.new()
	s.place(Vector2i(3, 4), 4.0, "forest")
	s.snares[Vector2i(3, 4)]["ready"] = ["raw_meat", "hide"]
	var t := Snares.new()
	t.from_array(s.to_array())
	check_eq(t.snares[Vector2i(3, 4)]["ready"], ["raw_meat", "hide"])
	check_eq(t.snares[Vector2i(3, 4)]["habitat"], "forest")
