extends BaseTest

func test_wanted_lookup() -> void:
	var t := {"pine_forest": {"deer": 4}}
	check_eq(RegionWildlife.wanted(t, "pine_forest")["deer"], 4)
	check(RegionWildlife.wanted(t, "nowhere").is_empty())

func test_data_valid() -> void:
	var t: Dictionary = DataDB.load_json("wildlife")
	check(t.has("farmland") and t.has("pine_forest"))
	var animals: Dictionary = DataDB.load_json("animals")["animals"]
	for r in t:
		for id in t[r]:
			check(animals.has(id), "unknown animal %s" % id)

func test_fish_counts() -> void:
	check_eq(RegionWildlife.fish_count(10), 0)
	check(RegionWildlife.fish_count(200) >= 1)
	check_eq(RegionWildlife.fish_count(9999), RegionWildlife.FISH_PER_CHUNK)

func test_keep_and_cap() -> void:
	check(RegionWildlife.should_keep(1000.0, 2048.0))
	check(not RegionWildlife.should_keep(9000.0, 2048.0))
	check_eq(RegionWildlife.room(22, 5), 2)
	check_eq(RegionWildlife.room(30, 5), 0)

func test_seed_daily() -> void:
	check(RegionWildlife.chunk_seed(1, Vector2i(2, 3), 1) != RegionWildlife.chunk_seed(1, Vector2i(2, 3), 2))
	check_eq(RegionWildlife.chunk_seed(1, Vector2i(2, 3), 4), RegionWildlife.chunk_seed(1, Vector2i(2, 3), 4))
