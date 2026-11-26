extends BaseTest

func test_isle_is_dry_land_in_a_ring_of_sea() -> void:
	check(IsleModel.is_island(Vector2i(IsleModel.CENTER)))
	check(not HarbourModel.is_sea(Vector2i(IsleModel.CENTER)))
	for c in [Vector2i(284, 142), Vector2i(284, 180), Vector2i(308, 160), Vector2i(256, 160), Vector2i(250, 130)]:
		check(not IsleModel.is_land(c), str(c))
		check(HarbourModel.is_sea(c), str(c))

func test_every_island_cell_is_inside_the_world_and_rect() -> void:
	var n := 0
	for y in range(130, 195):
		for x in range(240, 320):
			if IsleModel.depth(Vector2i(x, y)) <= 1.0:
				n += 1
				check(IsleModel.RECT.has_point(Vector2i(x, y)), "outside rect %d,%d" % [x, y])
	check(n > 400)
	check_eq(ChunkGrid.chunk_of_cell(Vector2i(IsleModel.CENTER)), Vector2i(7, 6))

func test_jetty_joins_landing_to_the_island() -> void:
	for x in range(IsleModel.LANDING.x, int(IsleModel.CENTER.x)):
		check(IsleModel.is_land(Vector2i(x, IsleModel.LANDING.y)), "gap at x=%d" % x)
	check(IsleModel.is_jetty(IsleModel.LANDING))
	check(IsleModel.is_jetty(IsleModel.POST_CELL))
	check(HarbourModel.is_quay(FerryModel.HARBOUR_LANDING))
	check(HarbourModel.is_quay(FerryModel.HARBOUR_POST))
	for p in HarbourModel.props():
		check(p["cell"] != FerryModel.HARBOUR_POST and p["cell"] != FerryModel.HARBOUR_LANDING)

func test_generated_chunk_matches_the_layout() -> void:
	var g := WorldGen.new(1, Vector2i(7, 6))
	var o := ChunkGrid.origin_cell(Vector2i(7, 6))
	var grass := 0
	for y in range(IsleModel.RECT.position.y, IsleModel.RECT.end.y):
		for x in range(IsleModel.RECT.position.x, IsleModel.RECT.end.x):
			var c := Vector2i(x, y)
			var water := WorldGen.is_water(g.tiles[(y - o.y) * 64 + (x - o.x)])
			check_eq(water, not IsleModel.is_land(c), str(c))
			grass += 1 if g.tiles[(y - o.y) * 64 + (x - o.x)] <= 2 else 0
	check(grass > 200)
	check(g.trees.size() > 5, "the isle has trees")
	for t in g.trees:
		check(not IsleModel.is_clear(t + o))

func test_forage_is_deterministic_on_the_beach_and_storms_add_more() -> void:
	var a := IsleModel.forage(12, false)
	check_eq(str(a), str(IsleModel.forage(12, false)))
	check(str(a) != str(IsleModel.forage(13, false)))
	check_eq(a.size(), IsleModel.SPOTS)
	check_eq(IsleModel.forage(12, true).size(), IsleModel.SPOTS + IsleModel.STORM_EXTRA)
	var seen := {}
	var items: Dictionary = DataDB.load_json("items")
	for s in a:
		check(IsleModel.is_beach(s["cell"]))
		check(not seen.has(s["cell"]))
		seen[s["cell"]] = true
		check(items.has(s["item"]))
		check(DataDB.load_json("item_icons").has(s["item"]))

func test_daily_forage_pays_back_the_ticket_without_being_a_money_printer() -> void:
	var items: Dictionary = DataDB.load_json("items")
	var total := 0
	for day in 200:
		for s in IsleModel.forage(day, false):
			total += int(items[s["item"]]["price"])
	var per_day := total / 200.0
	check(per_day > FerryModel.FARE * 2, str(per_day))
	check(per_day < 320.0, str(per_day))

func test_picked_finds_stay_gone_until_morning_and_survive_a_save() -> void:
	var st := IsleState.new()
	var spots := IsleModel.forage(5, false)
	st.pick(5, spots[0]["cell"])
	st.pick(5, spots[0]["cell"])
	check_eq(st.remaining(5, spots).size(), spots.size() - 1)
	var back := IsleState.new()
	back.from_dict(JSON.parse_string(JSON.stringify(st.to_dict())))
	check_eq(back.remaining(5, spots).size(), spots.size() - 1)
	check_eq(back.remaining(6, IsleModel.forage(6, false)).size(), IsleModel.SPOTS)

func test_cairn_gives_its_keepsake_once() -> void:
	var st := IsleState.new()
	check(st.read_cairn())
	check(not st.read_cairn())
	var back := IsleState.new()
	back.from_dict(st.to_dict())
	check(not back.read_cairn())
